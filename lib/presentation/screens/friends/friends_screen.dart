import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/diary_photo_storage.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_calendar_screen.dart';
import 'package:pluto/presentation/widgets/overflow_menu.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

enum FriendsScreenKind { profile, add }

final _codeFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(32),
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
  TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.toLowerCase();
    if (text == newValue.text) return newValue;
    return newValue.copyWith(text: text, composing: TextRange.empty);
  }),
];

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key}) : kind = FriendsScreenKind.profile;

  const FriendsScreen.add({super.key}) : kind = FriendsScreenKind.add;

  final FriendsScreenKind kind;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _code = TextEditingController();
  final _myCode = TextEditingController();
  final _myName = TextEditingController();
  final _nameFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _service = FriendService.instance;
  var _savingCode = false;
  var _savingName = false;
  var _savingPhoto = false;
  Uint8List? _preview;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;
  var _draftOutgoing = <FriendRequestItem>[];
  final _cancelWhenReady = <String>{};
  final _inFlightCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onNameFocus);
    _codeFocus.addListener(_onCodeFocus);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await _service.ensureProfile();
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocus);
    _nameFocus.dispose();
    _codeFocus.removeListener(_onCodeFocus);
    _codeFocus.dispose();
    _code.dispose();
    _myCode.dispose();
    _myName.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FriendsAppBar(
        title: widget.kind == FriendsScreenKind.add
            ? AppStrings.friendsAdd
            : AppStrings.friendsProfile,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          PcLayout.constrainWidth(
        ListView(
          padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32 + bottom),
          children: [
                if (widget.kind == FriendsScreenKind.profile) ...[
                  ValueListenableBuilder(
                    valueListenable: _service.profile,
                    builder: (context, profile, _) {
                      _syncCode(profile);
                      return _profileCard(colors, profile);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(AppStrings.friendsList),
                  StreamBuilder(
                    stream: _service.friends(),
                    builder: (context, snapshot) {
                      final friends = snapshot.data ?? const <FriendProfile>[];
                      if (friends.isEmpty) {
                        return _Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                            child: Column(
                              children: [
                                Text(
                                  AppStrings.friendsEmpty,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.friendsEmptyHint,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 13,
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return _Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < friends.length; i++) ...[
                              _FriendTile(
                                friend: friends[i],
                                onPressed: () => _openCalendar(friends[i]),
                                onRemove: () => _removeFriend(friends[i]),
                              ),
                              if (i != friends.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: colors.border,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  _Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _code,
                            maxLength: 32,
                            inputFormatters: _codeFormatters,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 16,
                              color: colors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.friendsCodeHint,
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.of(context),
                                color: colors.hint,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 4),
                          PressBounce(
                            onPressed: _send,
                            color: colors.tint(colors.accent, 0.16),
                            pressedColor: colors.tint(colors.accent, 0.26),
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 44,
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  AppStrings.friendsSend,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder(
                    stream: _service.incomingRequests(),
                    builder: (context, snapshot) {
                      return _RequestSection(
                        key: const ValueKey('incoming'),
                        title: AppStrings.friendsIncoming,
                        items: snapshot.data ?? const <FriendRequestItem>[],
                        incoming: true,
                        onAccept: _accept,
                        onDecline: _decline,
                      );
                    },
                  ),
                  StreamBuilder(
                    stream: _service.outgoingRequests(),
                    builder: (context, snapshot) {
                      return _RequestSection(
                        key: const ValueKey('outgoing'),
                        title: AppStrings.friendsOutgoing,
                        items: _mergedOutgoing(
                          snapshot.data ?? const <FriendRequestItem>[],
                        ),
                        incoming: false,
                        onCancel: _cancel,
                      );
                    },
                  ),
                ],
          ],
        ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: _hintVisible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: _hintVisible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: _hintVisible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: _hintVisible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCodeFocus() {
    if (_codeFocus.hasFocus) return;
    unawaited(_saveMyCode());
  }

  void _syncCode(FriendProfile? profile) {
    if (_codeFocus.hasFocus) return;
    final code = profile?.friendCode.trim() ?? '';
    if (_myCode.text == code) return;
    _myCode.text = code;
  }

  Widget _photoButton(AppColors colors, FriendProfile? profile) {
    return PressBounce(
      onPressed: _savingPhoto ? null : _pickPhoto,
      pressedScale: 0.96,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FriendAvatar(
              size: 72,
              profile: profile,
              preview: _preview,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FriendAvatar.accentOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 2),
                ),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: AppAssetImage(
                      asset: AppIcons.edit,
                      width: 11,
                      height: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_savingPhoto) return;
    try {
      final picked = await const DiaryPhotoStorage().pick();
      if (picked == null || !mounted) return;
      final bytes = await SyncedFileStore.instance.read(picked.path);
      if (bytes == null || bytes.isEmpty) return;
      if (bytes.length > 5 * 1024 * 1024) {
        _toast(AppStrings.friendsPhotoTooBig);
        return;
      }
      setState(() {
        _preview = bytes;
        _savingPhoto = true;
      });
      await _service.setPhoto(bytes, _photoType(picked.name));
      if (!mounted) return;
      setState(() => _savingPhoto = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _savingPhoto = false;
      });
      _toast(_service.messageOf(error));
    }
  }

  String _photoType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Widget _accountRow(AppColors colors) {
    final user = AppAuthService.instance.user;
    if (user == null) return const SizedBox.shrink();
    final provider = AppAuthService.providerOf(user);
    final id = AppAuthService.accountId(user);
    final (asset, background, tint) = switch (provider) {
      'kakao' => (AppIcons.kakaoLogo, const Color(0xFFFEE500), null),
      'google' => (AppIcons.googleLogo, Colors.white, null),
      'apple' => (AppIcons.appleLogo, const Color(0xFF111111), Colors.white),
      _ => (AppIcons.planet, colors.tint(colors.accent, 0.16), colors.accent),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: provider == 'google'
                  ? Border.all(color: colors.border)
                  : null,
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: AppAssetImage(
                  asset: asset,
                  width: 13,
                  height: 13,
                  color: tint,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNameFocus() {
    if (_nameFocus.hasFocus) return;
    unawaited(_saveMyName());
  }

  void _syncName(FriendProfile? profile) {
    if (_nameFocus.hasFocus) return;
    final name = profile?.displayName.trim() ?? '';
    if (_myName.text == name) return;
    _myName.text = name;
  }

  Widget _profileCard(AppColors colors, FriendProfile? profile) {
    _syncName(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(AppStrings.friendsProfile),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    _photoButton(colors, profile),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _myName,
                            focusNode: _nameFocus,
                            maxLength: 16,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveMyName(),
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 16,
                              color: colors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.friendsNameEditHint,
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.of(context),
                                color: colors.hint,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.border,
                          ),
                          TextField(
                            controller: _myCode,
                            focusNode: _codeFocus,
                            maxLength: 32,
                            inputFormatters: _codeFormatters,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveMyCode(),
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 16,
                              color: colors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: profile?.suggestedCode.isNotEmpty == true
                                  ? profile!.suggestedCode
                                  : AppStrings.friendsMyCode,
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.of(context),
                                color: colors.hint,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colors.border,
                ),
              ),
              _accountRow(colors),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveMyName() async {
    final name = _myName.text.trim();
    final current = _service.profile.value?.displayName.trim() ?? '';
    if (_savingName || name == current) return;
    if (name.isEmpty) {
      _myName.text = current;
      return;
    }
    _savingName = true;
    try {
      await _service.setDisplayName(name);
    } catch (error) {
      if (!mounted) return;
      _myName.text = current;
      _toast(_service.messageOf(error));
    } finally {
      _savingName = false;
    }
  }

  Future<void> _saveMyCode() async {
    final code = _myCode.text.trim();
    final current = _service.profile.value?.friendCode.trim() ?? '';
    if (_savingCode || code == current) return;
    if (code.isEmpty) {
      _myCode.text = current;
      return;
    }
    _savingCode = true;
    try {
      await _service.setFriendCode(code);
    } catch (error) {
      if (!mounted) return;
      _myCode.text = current;
      _toast(_service.messageOf(error));
    } finally {
      _savingCode = false;
    }
  }

  List<FriendRequestItem> _mergedOutgoing(List<FriendRequestItem> remote) {
    final codes = {for (final item in remote) item.toCode};
    return [
      ..._draftOutgoing.where((item) => !codes.contains(item.toCode)),
      ...remote.where((item) => !_cancelWhenReady.contains(item.toCode)),
    ];
  }

  Future<void> _send() async {
    final code = _code.text.trim();
    if (code.isEmpty || _inFlightCodes.contains(code)) return;
    if (_draftOutgoing.any((item) => item.toCode == code)) {
      _toast(AppStrings.friendsAlreadySent);
      return;
    }
    final me = _service.profile.value;
    if (me != null && me.friendCode == code) {
      _toast(AppStrings.friendsSelf);
      return;
    }
    _inFlightCodes.add(code);
    FriendRequestItem? draft;
    try {
      final other = await _service.lookupByCode(code);
      if (!mounted) return;
      if (other == null) {
        _toast(AppStrings.friendsNotFound);
        return;
      }
      if (other.uid == me?.uid) {
        _toast(AppStrings.friendsSelf);
        return;
      }
      if (await _service.isFriend(other.uid)) {
        if (!mounted) return;
        _toast(AppStrings.friendsAlready);
        return;
      }
      if (!mounted) return;
      draft = FriendRequestItem(
        id: 'local:$code:${DateTime.now().microsecondsSinceEpoch}',
        fromUid: me?.uid ?? '',
        toUid: other.uid,
        fromName: me?.displayName ?? '',
        fromCode: me?.friendCode ?? '',
        fromPhotoURL: me?.photoURL ?? '',
        toName: other.label,
        toCode: other.friendCode,
        toPhotoURL: other.photoURL,
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      _code.clear();
      setState(() {
        _draftOutgoing = [..._draftOutgoing, draft!];
      });
      _toast(AppStrings.friendsSent);
      final result = await _service.sendRequest(code);
      if (_cancelWhenReady.contains(code)) {
        if (result.requestId.isNotEmpty) {
          await _service.cancel(result.requestId);
        }
        _cancelWhenReady.remove(code);
        return;
      }
      if (!mounted) return;
      if (result.status == 'accepted') {
        final id = draft.id;
        setState(() {
          _draftOutgoing = [
            for (final item in _draftOutgoing)
              if (item.id != id) item,
          ];
        });
        _toast(AppStrings.friendsAccepted);
      }
    } catch (error) {
      if (!mounted) return;
      final id = draft?.id;
      if (id != null) {
        setState(() {
          _draftOutgoing = [
            for (final item in _draftOutgoing)
              if (item.id != id) item,
          ];
        });
      }
      _toast(_service.messageOf(error));
    } finally {
      _inFlightCodes.remove(code);
    }
  }

  Future<void> _accept(FriendRequestItem item) async {
    try {
      await _service.accept(item.id);
      if (!mounted) return;
      _toast(AppStrings.friendsAccepted);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Future<void> _decline(FriendRequestItem item) async {
    try {
      await _service.decline(item.id);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Future<void> _cancel(FriendRequestItem item) async {
    if (item.id.startsWith('local:')) {
      _cancelWhenReady.add(item.toCode);
      if (!mounted) return;
      setState(() {
        _draftOutgoing = [
          for (final entry in _draftOutgoing)
            if (entry.id != item.id) entry,
        ];
      });
      return;
    }
    try {
      await _service.cancel(item.id);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  void _toast(String text) {
    _hintTimer?.cancel();
    setState(() {
      _hint = text;
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _removeFriend(FriendProfile friend) async {
    final colors = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            AppStrings.friendsRemoveTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          content: Text(
            AppStrings.friendsRemoveBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.friendsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppStrings.friendsRemove,
                style: TextStyle(color: colors.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await _service.remove(friend.uid);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Future<void> _openCalendar(FriendProfile friend) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FriendCalendarScreen(friend: friend),
      ),
    );
  }
}

class _RequestSection extends StatefulWidget {
  const _RequestSection({
    super.key,
    required this.title,
    required this.items,
    required this.incoming,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final String title;
  final List<FriendRequestItem> items;
  final bool incoming;
  final ValueChanged<FriendRequestItem>? onAccept;
  final ValueChanged<FriendRequestItem>? onDecline;
  final ValueChanged<FriendRequestItem>? onCancel;

  @override
  State<_RequestSection> createState() => _RequestSectionState();
}

class _RequestSectionState extends State<_RequestSection> {
  static const _anim = Duration(milliseconds: 280);

  String _rowKey(FriendRequestItem item) {
    return widget.incoming
        ? 'in:${item.fromUid}:${item.fromCode}'
        : 'out:${item.toCode}';
  }

  var _items = <FriendRequestItem>[];
  final _entering = <String>{};
  final _leaving = <String>{};

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(_RequestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.items);
  }

  void _sync(List<FriendRequestItem> next) {
    final nextIds = {for (final item in next) item.id};
    var changed = false;

    for (final item in next) {
      if (_leaving.contains(item.id)) continue;
      final index = _items.indexWhere((entry) => entry.id == item.id);
      if (index >= 0) {
        if (!identical(_items[index], item)) {
          _items[index] = item;
          changed = true;
        }
        continue;
      }
      final alias = _items.indexWhere((entry) {
        return !_leaving.contains(entry.id) && _samePerson(item)(entry);
      });
      if (alias >= 0) {
        _entering.remove(_items[alias].id);
        _items[alias] = item;
        changed = true;
        continue;
      }
      _items.add(item);
      _entering.add(item.id);
      changed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _entering.remove(item.id));
      });
    }

    for (final item in List.of(_items)) {
      if (nextIds.contains(item.id) || _leaving.contains(item.id)) continue;
      if (next.any(_samePerson(item))) continue;
      _hide(item.id);
      changed = true;
    }

    if (changed) setState(() {});
  }

  bool Function(FriendRequestItem) _samePerson(FriendRequestItem item) {
    return (entry) {
      if (widget.incoming) {
        return entry.fromCode == item.fromCode && entry.fromUid == item.fromUid;
      }
      return entry.toCode == item.toCode;
    };
  }

  void _hide(String id) {
    if (_leaving.contains(id)) return;
    setState(() {
      _leaving.add(id);
      _entering.remove(id);
    });
    Future<void>.delayed(_anim, () {
      if (!mounted) return;
      setState(() {
        _items.removeWhere((item) => item.id == id);
        _leaving.remove(id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedSize(
      duration: _anim,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _items.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(widget.title),
                  _Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          _RequestReveal(
                            key: ValueKey(_rowKey(_items[i])),
                            visible: !_entering.contains(_items[i].id) &&
                                !_leaving.contains(_items[i].id),
                            child: Column(
                              children: [
                                _requestRow(colors, _items[i]),
                                if (i != _items.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 68),
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: colors.border,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _requestRow(AppColors colors, FriendRequestItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          FriendAvatar(
            size: 40,
            profile: widget.incoming ? item.fromProfile : item.toProfile,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.incoming ? item.fromLabel : item.toLabel,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: widget.incoming
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: colors.text,
                  ),
                ),
                Text(
                  widget.incoming ? item.fromCode : item.toCode,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 13,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (widget.incoming) ...[
            _TextAction(
              label: AppStrings.friendsDecline,
              color: colors.muted,
              onPressed: () {
                _hide(item.id);
                widget.onDecline?.call(item);
              },
            ),
            const SizedBox(width: 4),
            _TextAction(
              label: AppStrings.friendsAccept,
              color: colors.accent,
              onPressed: () {
                _hide(item.id);
                widget.onAccept?.call(item);
              },
            ),
          ] else
            _TextAction(
              label: AppStrings.friendsCancel,
              color: colors.muted,
              weight: FontWeight.w400,
              onPressed: () {
                _hide(item.id);
                widget.onCancel?.call(item);
              },
            ),
        ],
      ),
    );
  }
}

class _RequestReveal extends StatefulWidget {
  const _RequestReveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_RequestReveal> createState() => _RequestRevealState();
}

class _RequestRevealState extends State<_RequestReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.visible ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(_RequestReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: _fade,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.onPressed,
    required this.onRemove,
  });

  final FriendProfile friend;
  final VoidCallback onPressed;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: PressBounce(
              onPressed: onPressed,
              pressedScale: 0.98,
              color: colors.card,
              pressedColor: colors.pressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    FriendAvatar(size: 40, profile: friend),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.label,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 16,
                              color: colors.text,
                            ),
                          ),
                          if (friend.friendCode.isNotEmpty)
                            Text(
                              friend.friendCode,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: 13,
                                color: colors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          OverflowMenuButton(
            actions: [
              OverflowMenuAction(
                label: AppStrings.friendsRemove,
                color: colors.danger,
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.color,
    required this.onPressed,
    this.weight = FontWeight.w800,
  });

  final String label;
  final Color color;
  final FontWeight weight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: weight,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _HintToast extends StatelessWidget {
  const _HintToast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 2, 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).text,
        ),
      ),
    );
  }
}

class _FriendsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FriendsAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const _toolbarHeight = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: colors.groupedBackground.withValues(alpha: 0.08),
          child: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            toolbarHeight: _toolbarHeight,
            centerTitle: true,
            leading: PressBounce(
              onPressed: onBack,
              pressedColor: Colors.transparent,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: colors.text,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
