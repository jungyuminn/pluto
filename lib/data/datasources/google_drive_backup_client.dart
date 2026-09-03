import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:pluto/data/datasources/app_auth_service.dart';

class GoogleDriveBackupFile {
  const GoogleDriveBackupFile({required this.fileName, required this.date});

  final String fileName;
  final DateTime date;
}

class GoogleDriveBackupClient {
  GoogleDriveBackupClient._();

  static const folderName = '플루토 백업';
  static const legacyFolderName = '잡플래너 백업';
  static const filePrefix = '플루토_백업_';
  static const legacyFilePrefix = '잡플래너_백업_';
  static const _keepCount = 3;
  static const _scopes = [drive.DriveApi.driveFileScope];

  static Future<void> upload(
    Uint8List bytes,
    String fileName, {
    required bool interactive,
  }) {
    return _withApi(interactive: interactive, (api) async {
      final folderId = await _ensureFolder(api);
      final existingId = await _fileId(api, folderId, fileName);
      final media = drive.Media(
        Stream<List<int>>.fromIterable([bytes]),
        bytes.length,
        contentType: 'application/zip',
      );
      if (existingId != null) {
        await api.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        await api.files.create(
          drive.File()
            ..name = fileName
            ..parents = [folderId],
          uploadMedia: media,
        );
      }
      await _prune(api, folderId);
    });
  }

  static Future<List<GoogleDriveBackupFile>> list() {
    return _withApi(interactive: true, (api) async {
      final folderId = await _ensureFolder(api);
      final result = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id, name, modifiedTime)',
        orderBy: 'modifiedTime desc',
      );
      final items = <GoogleDriveBackupFile>[
        for (final file in result.files ?? const <drive.File>[])
          if (_isBackupName(file.name ?? ''))
            GoogleDriveBackupFile(
              fileName: file.name!,
              date: _dateOf(file),
            ),
      ];
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    });
  }

  static Future<Uint8List> read(String fileName) {
    return _withApi(interactive: true, (api) async {
      final folderId = await _ensureFolder(api);
      final id = await _fileId(api, folderId, fileName);
      if (id == null) {
        throw const FormatException('missing Drive backup');
      }
      final response = await api.files.get(
        id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (response is! drive.Media) {
        throw const FormatException('missing Drive backup');
      }
      final chunks = <int>[];
      await for (final chunk in response.stream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    });
  }

  static Future<T> _withApi<T>(
    Future<T> Function(drive.DriveApi api) action, {
    required bool interactive,
  }) async {
    final client = await _authorizedClient(interactive: interactive);
    try {
      return await action(drive.DriveApi(client));
    } finally {
      client.close();
    }
  }

  static Future<http.Client> _authorizedClient({required bool interactive}) async {
    await AppAuthService.instance.ensureGoogleInitialized();
    final authorization = await _authorization(interactive: interactive);
    final token = authorization.accessToken;
    if (token.isEmpty) {
      throw PlatformException(
        code: interactive ? 'signed_out' : 'unavailable',
        message: 'Drive authorization missing',
      );
    }
    return _GoogleAuthClient(token);
  }

  static Future<GoogleSignInClientAuthorization> _authorization({
    required bool interactive,
  }) async {
    final instanceClient = GoogleSignIn.instance.authorizationClient;
    try {
      final silent = await instanceClient.authorizationForScopes(_scopes);
      if (silent != null) return silent;
    } catch (_) {}

    final account = await _account(interactive: interactive);
    if (account != null) {
      try {
        final silent =
            await account.authorizationClient.authorizationForScopes(_scopes);
        if (silent != null) return silent;
      } catch (_) {}
      if (interactive) {
        try {
          return await account.authorizationClient.authorizeScopes(_scopes);
        } on GoogleSignInException catch (error) {
          throw _authException(error);
        }
      }
    }

    if (interactive) {
      try {
        return await instanceClient.authorizeScopes(_scopes);
      } on GoogleSignInException catch (error) {
        throw _authException(error);
      }
    }
    throw PlatformException(code: 'signed_out', message: 'Google signed out');
  }

  static Future<GoogleSignInAccount?> _account({required bool interactive}) async {
    try {
      final lightweight =
          GoogleSignIn.instance.attemptLightweightAuthentication();
      if (lightweight != null) {
        final account = await lightweight;
        if (account != null) return account;
      }
    } catch (_) {}
    if (!interactive) return null;
    try {
      return await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (error) {
      throw _authException(error);
    }
  }

  static PlatformException _authException(GoogleSignInException error) {
    return PlatformException(
      code: AppAuthService.isUserCanceled(error) ? 'signed_out' : 'unavailable',
      message: error.toString(),
    );
  }

  static bool _isBackupName(String name) {
    return (name.startsWith(filePrefix) || name.startsWith(legacyFilePrefix)) &&
        name.toLowerCase().endsWith('.zip');
  }

  static Future<String?> _folderId(drive.DriveApi api, String name) async {
    final escaped = name.replaceAll("'", r"\'");
    final existing = await api.files.list(
      q: "name = '$escaped' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      $fields: 'files(id)',
      pageSize: 1,
    );
    final id = existing.files?.firstOrNull?.id;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static Future<String> _ensureFolder(drive.DriveApi api) async {
    final current = await _folderId(api, folderName);
    if (current != null) return current;
    final legacy = await _folderId(api, legacyFolderName);
    if (legacy != null) {
      try {
        await api.files.update(drive.File()..name = folderName, legacy);
      } catch (_) {}
      return legacy;
    }
    final created = await api.files.create(
      drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    final createdId = created.id;
    if (createdId == null || createdId.isEmpty) {
      throw PlatformException(code: 'unavailable', message: 'Drive folder missing');
    }
    return createdId;
  }

  static Future<String?> _fileId(
    drive.DriveApi api,
    String folderId,
    String fileName,
  ) async {
    final escaped = fileName.replaceAll("'", r"\'");
    final result = await api.files.list(
      q: "'$folderId' in parents and name = '$escaped' and trashed = false",
      $fields: 'files(id)',
      pageSize: 1,
    );
    return result.files?.firstOrNull?.id;
  }

  static Future<void> _prune(drive.DriveApi api, String folderId) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
      orderBy: 'modifiedTime desc',
    );
    final files = [
      for (final file in result.files ?? const <drive.File>[])
        if (_isBackupName(file.name ?? '')) file,
    ];
    for (final file in files.skip(_keepCount)) {
      final id = file.id;
      if (id == null) continue;
      try {
        await api.files.delete(id);
      } catch (_) {}
    }
  }

  static DateTime _dateOf(drive.File file) {
    final name = file.name ?? '';
    final match = RegExp(r'(\d{8})').firstMatch(name);
    if (match != null) {
      final stamp = match.group(1)!;
      return DateTime(
        int.parse(stamp.substring(0, 4)),
        int.parse(stamp.substring(4, 6)),
        int.parse(stamp.substring(6, 8)),
      );
    }
    return file.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._token) : _inner = http.Client();

  final String _token;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
