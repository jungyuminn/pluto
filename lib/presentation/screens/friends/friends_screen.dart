import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/diary_photo_storage.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_order_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/todo_request.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:pluto/presentation/screens/friends/category_share_sheet.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_calendar_screen.dart';
import 'package:pluto/presentation/screens/friends/friend_photo_peek.dart';
import 'package:pluto/presentation/screens/friends/friend_star_button.dart';
import 'package:pluto/presentation/screens/friends/friends_toast.dart';
import 'package:pluto/presentation/widgets/overflow_menu.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

final _codeFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(32),
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
  TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.toLowerCase();
    if (text == newValue.text) return newValue;
    return newValue.copyWith(text: text, composing: TextRange.empty);
  }),
];

Future<void> showAddFriendSheet(BuildContext context) async {
  try {
    await FriendService.instance.ensureProfile();
  } catch (_) {}
  if (!context.mounted) return;
  final me = FriendService.instance.profile.value;
  if (me == null || !me.hasIdentity) {
    showFriendsToast(context, AppStrings.friendsProfileNeed);
    return;
  }
  return showComposeSheet<void>(
    context,
    builder: (context) => const AddFriendSheet(),
  );
}

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _code = TextEditingController();
  final _service = FriendService.instance;
  final _toastOverlay = OverlayPortalController();
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;
  var _draftOutgoing = <FriendRequestItem>[];
  final _seenOutgoing = <String>{};
  final _cancelWhenReady = <String>{};
  final _inFlightCodes = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
    if (PcLayout.isPc) _toastOverlay.show();
  }

  Future<void> _bootstrap() async {
    try {
      await _service.ensureProfile();
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final sheet = Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: colors.groupedBackground,
            borderRadius: PcLayout.sheetRadius(),
          ),
          clipBehavior: PcLayout.isPc ? Clip.antiAlias : Clip.none,
          child: Stack(
            fit: StackFit.loose,
            children: [
              ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
                children: [
                  if (PcLayout.isPc)
                    const SizedBox(height: 14)
                  else ...[
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const SizedBox(width: 36, height: 4),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Center(
                    child: Text(
                      AppStrings.friendsAdd,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _addFriendCard(colors),
                  _incomingSection(),
                  _outgoingSection(),
                ],
              ),
              if (!PcLayout.isPc)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 12 + bottom,
                  child: AnimatedFriendsToast(
                    text: _hint,
                    visible: _hintVisible,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!PcLayout.isPc) return sheet;
    return OverlayPortal(
      controller: _toastOverlay,
      overlayChildBuilder: (context) {
        final safe = MediaQuery.paddingOf(context).bottom;
        return PcLayout.pinBottomToast(
          bottom: 20 + safe,
          child: AnimatedFriendsToast(
            text: _hint,
            visible: _hintVisible,
          ),
        );
      },
      child: sheet,
    );
  }

  Widget _addFriendCard(AppColors colors) {
    return _Card(
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
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
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
    );
  }

  Widget _incomingSection() {
    return StreamBuilder(
      stream: _service.incomingRequests(),
      initialData: _service.lastIncoming,
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
    );
  }

  Widget _outgoingSection() {
    return StreamBuilder(
      stream: _service.outgoingRequests(),
      initialData: _service.lastOutgoing,
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
    );
  }

  List<FriendRequestItem> _mergedOutgoing(List<FriendRequestItem> remote) {
    for (final item in remote) {
      _seenOutgoing.add(item.toCode);
      if (item.toUid.isNotEmpty) _seenOutgoing.add(item.toUid);
    }
    return [
      ..._draftOutgoing.where((item) {
        return !_seenOutgoing.contains(item.toCode) &&
            !_seenOutgoing.contains(item.toUid);
      }),
      ...remote.where((item) => !_cancelWhenReady.contains(item.toCode)),
    ];
  }

  Future<void> _send() async {
    final me = _service.profile.value;
    if (me == null || !me.hasIdentity) {
      _toast(AppStrings.friendsProfileNeed);
      return;
    }
    final code = _code.text.trim();
    if (code.isEmpty || _inFlightCodes.contains(code)) return;
    if (_draftOutgoing.any((item) => item.toCode == code)) {
      _toast(AppStrings.friendsAlreadySent);
      return;
    }
    if (me.friendCode == code) {
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
      if (other.uid == me.uid) {
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
        fromUid: me.uid,
        toUid: other.uid,
        fromName: me.displayName,
        fromCode: me.friendCode,
        fromPhotoURL: me.photoURL,
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
      _toast(AppStrings.friendsSent(other.label));
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
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}


class _FriendsScreenState extends State<FriendsScreen> {
  final _myCode = TextEditingController();
  final _myName = TextEditingController();
  final _nameFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _service = FriendService.instance;
  var _savingCode = false;
  var _savingName = false;
  var _savingPhoto = false;
  var _photoMenuOpen = false;
  Uint8List? _preview;
  var _hint = '';
  var _hintVisible = false;
  String? _flyingUid;
  OverlayEntry? _flightEntry;
  final _flightKey = GlobalKey<_FlyingFriendTileState>();
  final _tileKeys = <String, GlobalKey>{};
  var _shownFavorites = const <FriendProfile>[];
  var _shownRegulars = const <FriendProfile>[];
  Timer? _hintTimer;

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
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocus);
    _nameFocus.dispose();
    _codeFocus.removeListener(_onCodeFocus);
    _codeFocus.dispose();
    _myCode.dispose();
    _myName.dispose();
    _hintTimer?.cancel();
    _flightEntry?.remove();
    super.dispose();
  }

  GlobalKey _tileKey(String uid) {
    return _tileKeys.putIfAbsent(uid, GlobalKey.new);
  }

  Rect? _tileRect(String uid) {
    final box = _tileKey(uid).currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  bool _willFavoriteMove(FriendProfile friend, bool nextFavorite) {
    final favs = _shownFavorites;
    final regs = _shownRegulars;
    if (nextFavorite) {
      if (favs.isEmpty && regs.length <= 1) return false;
      final fromSlot =
          favs.length + regs.indexWhere((item) => item.uid == friend.uid);
      return fromSlot != favs.length;
    }
    if (regs.isEmpty && favs.length <= 1) return false;
    final fromSlot = favs.indexWhere((item) => item.uid == friend.uid);
    final nextRegs = FriendOrderPreference.instance.apply([
      ...regs,
      friend,
    ]);
    final toSlot = (favs.length - 1) +
        nextRegs.indexWhere((item) => item.uid == friend.uid);
    return fromSlot != toSlot;
  }

  void _toggleFavorite(FriendProfile friend, bool value) {
    final from = _tileRect(friend.uid);
    final moves = _willFavoriteMove(friend, value);
    if (moves) {
      _flyingUid = friend.uid;
      if (from != null) _parkFlight(friend, favorited: value, from: from);
    }
    FriendFavoritePreference.instance.setFavorite(friend.uid, value);
    _toast(
      value
          ? AppStrings.friendsFavoriteAdded
          : AppStrings.friendsFavoriteRemoved,
    );
    if (!moves) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final to = _tileRect(friend.uid);
      if (to == null || (from != null && (from.center - to.center).distance < 2)) {
        _clearFlight();
        return;
      }
      _flightKey.currentState?.flyTo(to);
    });
  }

  void _parkFlight(
    FriendProfile friend, {
    required bool favorited,
    required Rect from,
  }) {
    _flightEntry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingFriendTile(
        key: _flightKey,
        friend: friend,
        favorited: favorited,
        homePinned: FriendHomePreference.instance.contains(friend.uid),
        from: from,
        onDone: _clearFlight,
      ),
    );
    _flightEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _clearFlight() {
    _flightEntry?.remove();
    _flightEntry = null;
    if (!mounted) return;
    if (_flyingUid == null) return;
    setState(() => _flyingUid = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: _FriendsAppBar(
        title: AppStrings.friendsProfileSettings,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          PcLayout.constrainWidth(
            ListView(
              padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32 + bottom),
              children: [
                ValueListenableBuilder(
                  valueListenable: _service.profile,
                  builder: (context, profile, _) {
                    _syncCode(profile);
                    return _profileCard(colors, profile);
                  },
                ),
                _incomingTodos(),
                _outgoingTodos(),
                _friendsSection(colors),
              ],
            ),
          ),
          PcLayout.pinBottomToast(
            bottom: 20 + bottom,
            child: AnimatedFriendsToast(
              text: _hint,
              visible: _hintVisible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendsSection(AppColors colors) {
    return StreamBuilder(
      stream: _service.friends(),
      builder: (context, snapshot) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            FriendFavoritePreference.instance.listenable,
            FriendHomePreference.instance.listenable,
            FriendOrderPreference.instance.listenable,
          ]),
          builder: (context, _) {
        final friends = FriendFavoritePreference.instance.apply(
          snapshot.data ?? const <FriendProfile>[],
        );
        final favorites = [
          for (final friend in friends)
            if (FriendFavoritePreference.instance.contains(friend.uid)) friend,
        ];
        final regulars = [
          for (final friend in friends)
            if (!FriendFavoritePreference.instance.contains(friend.uid)) friend,
        ];
        _shownFavorites = favorites;
        _shownRegulars = regulars;
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(AppStrings.friendsList),
              if (friends.isEmpty)
                const _EmptyCard(
                  title: AppStrings.friendsEmpty,
                  hint: AppStrings.friendsEmptyHint,
                )
              else
                _Card(
                  child: Column(
                    children: [
                      if (favorites.isNotEmpty)
                        _friendGroup(
                          colors,
                          friends: favorites,
                          leadingDivider: false,
                          onReorder: (oldIndex, newIndex) {
                            unawaited(
                              _service.reorderFavorites(
                                favorites,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              ),
                            );
                          },
                        ),
                      if (regulars.isNotEmpty)
                        _friendGroup(
                          colors,
                          friends: regulars,
                          leadingDivider: favorites.isNotEmpty,
                          onReorder: (oldIndex, newIndex) {
                            unawaited(
                              _service.reorderRegulars(
                                regulars,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _friendGroup(
    AppColors colors, {
    required List<FriendProfile> friends,
    required bool leadingDivider,
    required void Function(int oldIndex, int newIndex) onReorder,
  }) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      itemCount: friends.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(animation.value);
            return Transform.translate(
              offset: Offset(0, -4 * t),
              child: Transform.scale(
                scale: 1 + 0.02 * t,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final showLine = index > 0 || leadingDivider;
        final flying = _flyingUid == friend.uid;
        return ReorderableDelayedDragStartListener(
          key: ValueKey(friend.uid),
          index: index,
          child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: showLine
                        ? colors.border
                        : colors.border.withValues(alpha: 0),
                  ),
                ),
                KeyedSubtree(
                  key: _tileKey(friend.uid),
                  child: IgnorePointer(
                    ignoring: flying,
                    child: Opacity(
                      opacity: flying ? 0 : 1,
                      child: _FriendTile(
                        friend: friend,
                        homePinned: FriendHomePreference.instance
                            .contains(friend.uid),
                        favorited: FriendFavoritePreference.instance
                            .contains(friend.uid),
                        onPressed: () => _openCalendar(friend),
                        onHomeChanged: (value) {
                          FriendHomePreference.instance.setPinned(
                            friend.uid,
                            value,
                          );
                          _toast(
                            value
                                ? AppStrings.friendsHomePinned(friend.label)
                                : AppStrings.friendsHomeUnpinned(friend.label),
                          );
                        },
                        onFavoriteChanged: (value) =>
                            _toggleFavorite(friend, value),
                        onSharedTodo: () => _addSharedTodo(friend),
                        onRemove: () => _removeFriend(friend),
                      ),
                    ),
                  ),
                ),
              ],
          ),
        );
      },
    );
  }

  void _onCodeFocus() {
    if (_codeFocus.hasFocus) return;
    unawaited(_saveMyCode());
  }

  void _toastCodeCooldownIfLocked() {
    final profile = _service.profile.value;
    if (profile == null || profile.canChangeCode) return;
    final days = profile.cooldownDays < 1 ? 1 : profile.cooldownDays;
    _toast(AppStrings.friendsCodeCooldown(days));
  }

  void _syncCode(FriendProfile? profile) {
    if (profile != null && !profile.canChangeCode && _codeFocus.hasFocus) {
      _codeFocus.unfocus();
    }
    if (_codeFocus.hasFocus) return;
    final code = profile?.friendCode.trim() ?? '';
    if (_myCode.text == code) return;
    _myCode.text = code;
  }

  Widget _photoButton(AppColors colors, FriendProfile? profile) {
    final hasPhoto = _hasPhoto(profile);
    final open = hasPhoto && _photoMenuOpen;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PressBounce(
            onPressed: _savingPhoto || open
                ? null
                : () {
                    if (!hasPhoto) {
                      unawaited(_pickPhoto());
                      return;
                    }
                    setState(() => _photoMenuOpen = true);
                  },
            pressedScale: 0.96,
            pressedColor: Colors.transparent,
            child: FriendAvatar(
              size: 84,
              profile: profile,
              preview: _preview,
              showFavorite: false,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !open,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: ClipOval(
                  child: ColoredBox(
                    color: const Color(0xB8000000),
                    child: Row(
                      children: [
                        Expanded(
                          child: _photoSplit(
                            icon: AppIcons.edit,
                            label: AppStrings.friendsPhotoPick,
                            onPressed: () {
                              setState(() => _photoMenuOpen = false);
                              unawaited(_pickPhoto());
                            },
                          ),
                        ),
                        ColoredBox(
                          color: Colors.white.withValues(alpha: 0.28),
                          child: const SizedBox(width: 1, height: 84),
                        ),
                        Expanded(
                          child: _photoSplit(
                            icon: AppIcons.trashCan,
                            label: AppStrings.friendsPhotoClear,
                            danger: true,
                            onPressed: () => unawaited(_confirmClearPhoto()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: PressBounce(
              onPressed: _savingPhoto
                  ? null
                  : () {
                      if (!hasPhoto) {
                        unawaited(_pickPhoto());
                        return;
                      }
                      setState(() => _photoMenuOpen = !_photoMenuOpen);
                    },
              pressedScale: 0.92,
              pressedColor: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: open
                      ? colors.text
                      : FriendAvatar.accentOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 2),
                ),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: open
                        ? Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: colors.card,
                          )
                        : const AppAssetImage(
                            asset: AppIcons.edit,
                            width: 11,
                            height: 11,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSplit({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.94,
      pressedColor: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.zero,
      child: ColoredBox(
        color: danger
            ? const Color(0x33FF3B30)
            : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAssetImage(
              asset: icon,
              width: 16,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPhoto(FriendProfile? profile) {
    if (_preview != null) return true;
    return FriendService.instance.avatarBytes(profile?.uid) != null;
  }

  Future<void> _confirmClearPhoto() async {
    if (_savingPhoto) return;
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
            AppStrings.friendsPhotoClearTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.friendsPhotoClearBody,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PressBounce(
                      onPressed: () => Navigator.pop(context, false),
                      color: colors.border,
                      pressedColor:
                          Color.lerp(colors.border, Colors.black, 0.12)!,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PressBounce(
                      onPressed: () => Navigator.pop(context, true),
                      color: colors.danger,
                      pressedColor:
                          Color.lerp(colors.danger, Colors.black, 0.16)!,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            AppStrings.delete,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || ok != true) return;
    await _clearPhoto();
  }

  Future<void> _clearPhoto() async {
    if (_savingPhoto) return;
    setState(() {
      _preview = null;
      _photoMenuOpen = false;
      _savingPhoto = true;
    });
    try {
      await _service.clearPhoto();
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      _toast(AppStrings.friendsPhotoCleared);
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      _toast(_service.messageOf(error));
    }
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

  Widget _categoryShareRow(AppColors colors) {
    return PressBounce(
      onPressed: () => showCategoryShareSheet(context),
      pressedScale: 0.99,
      color: colors.card,
      pressedColor: colors.pressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.friendsCategoryShare,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 16,
                  color: colors.text,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colors.muted,
            ),
          ],
        ),
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
        _SectionLabel(AppStrings.friendsProfileSettings),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _photoButton(colors, profile),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(AppStrings.friendsMyName),
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
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.border,
                          ),
                          const SizedBox(height: 8),
                          _FieldLabel(AppStrings.friendsMyCode),
                          Row(
                            children: [
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final locked = profile != null &&
                                        !profile.canChangeCode;
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: locked
                                          ? _toastCodeCooldownIfLocked
                                          : null,
                                      child: AbsorbPointer(
                                        absorbing: locked,
                                        child: TextField(
                                          controller: _myCode,
                                          focusNode: _codeFocus,
                                          readOnly: locked,
                                          canRequestFocus: !locked,
                                          enableInteractiveSelection: !locked,
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
                                            hintText:
                                                AppStrings.friendsCodeEditHint,
                                            hintStyle: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              color: colors.hint,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            counterText: '',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                              0,
                                              4,
                                              0,
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              PressBounce(
                                onPressed: _copyMyCode,
                                pressedScale: 0.94,
                                pressedColor: colors.pressed,
                                borderRadius: BorderRadius.circular(18),
                                child: Tooltip(
                                  message: AppStrings.friendsCopy,
                                  child: Semantics(
                                    button: true,
                                    label: AppStrings.friendsCopy,
                                    child: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Center(
                                        child: AppAssetImage(
                                          asset: AppIcons.copy,
                                          width: 20,
                                          height: 20,
                                          color: colors.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colors.border,
                ),
              ),
              _categoryShareRow(colors),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyMyCode() async {
    final code = _myCode.text.trim();
    if (code.isEmpty) {
      _toast(AppStrings.friendsCodeNeed);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _toast(AppStrings.friendsCopied);
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
    final profile = _service.profile.value;
    final current = profile?.friendCode.trim() ?? '';
    if (_savingCode || code == current) return;
    if (code.isEmpty) {
      _myCode.text = current;
      return;
    }
    if (profile != null && !profile.canChangeCode) {
      _myCode.text = current;
      _toastCodeCooldownIfLocked();
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
    final ok = await confirmRemoveFriend(context, friend);
    if (!ok || !mounted) return;
    try {
      await _service.remove(friend.uid);
      if (!mounted) return;
      _toast(AppStrings.friendsUnfriended(friend.label));
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Widget _incomingTodos() {
    return StreamBuilder(
      stream: _service.incomingTodos(),
      initialData: _service.lastIncomingTodos,
      builder: (context, snapshot) {
        return _TodoRequestSection(
          key: const ValueKey('todo-incoming'),
          title: AppStrings.friendsSharedTodoIncoming,
          items: snapshot.data ?? const <TodoRequestItem>[],
          incoming: true,
          onAccept: _acceptTodo,
          onDecline: _declineTodo,
        );
      },
    );
  }

  Widget _outgoingTodos() {
    return StreamBuilder(
      stream: _service.outgoingTodos(),
      initialData: _service.lastOutgoingTodos,
      builder: (context, snapshot) {
        return _TodoRequestSection(
          key: const ValueKey('todo-outgoing'),
          title: AppStrings.friendsSharedTodoOutgoing,
          items: snapshot.data ?? const <TodoRequestItem>[],
          incoming: false,
          onCancel: _cancelTodo,
        );
      },
    );
  }

  Future<void> _addSharedTodo(FriendProfile friend) async {
    final sent = await showAddEventSheet(
      context,
      date: DateTime.now(),
      shareWith: friend,
    );
    if (!mounted || !sent) return;
    _toast(AppStrings.friendsSharedTodoSent(friend.label));
  }

  Future<void> _acceptTodo(TodoRequestItem item) async {
    try {
      await _service.acceptTodo(item.id);
      if (!mounted) return;
      _toast(AppStrings.friendsSharedTodoAccepted);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Future<void> _declineTodo(TodoRequestItem item) async {
    try {
      await _service.declineTodo(item.id);
    } catch (error) {
      if (!mounted) return;
      _toast(_service.messageOf(error));
    }
  }

  Future<void> _cancelTodo(TodoRequestItem item) async {
    try {
      await _service.cancelTodo(item.id);
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

class _TodoRequestSection extends StatefulWidget {
  const _TodoRequestSection({
    super.key,
    required this.title,
    required this.items,
    required this.incoming,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final String title;
  final List<TodoRequestItem> items;
  final bool incoming;
  final ValueChanged<TodoRequestItem>? onAccept;
  final ValueChanged<TodoRequestItem>? onDecline;
  final ValueChanged<TodoRequestItem>? onCancel;

  @override
  State<_TodoRequestSection> createState() => _TodoRequestSectionState();
}

class _TodoRequestSectionState extends State<_TodoRequestSection> {
  static const _anim = Duration(milliseconds: 280);

  var _items = <TodoRequestItem>[];
  final _entering = <String>{};
  final _leaving = <String>{};

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(_TodoRequestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.items);
  }

  void _sync(List<TodoRequestItem> next) {
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
      _hide(item.id);
      changed = true;
    }
    if (changed) setState(() {});
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
    final sectionOpen =
        _items.any((item) => !_leaving.contains(item.id));
    return AnimatedSize(
      duration: _anim,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _items.isEmpty
          ? const SizedBox(width: double.infinity)
          : _RequestReveal(
              visible: sectionOpen,
              child: Padding(
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
                              key: ValueKey(_items[i].id),
                              visible: sectionOpen
                                  ? !_entering.contains(_items[i].id) &&
                                      !_leaving.contains(_items[i].id)
                                  : true,
                              child: Column(
                                children: [
                                  _row(colors, _items[i]),
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
            ),
    );
  }

  Widget _row(AppColors colors, TodoRequestItem item) {
    final other = widget.incoming ? item.fromProfile : item.toProfile;
    final time = item.startMinutes == null
        ? item.dateLabel
        : '${item.dateLabel}  ${CalendarEvent.formatMinutes(item.startMinutes!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          FriendPhotoPeekTarget(size: 40, profile: other),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
                Text(
                  '${other.label} · $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            _IconAction(
              icon: Icons.close_rounded,
              color: colors.muted,
              semanticLabel: AppStrings.friendsDecline,
              onPressed: () {
                _hide(item.id);
                widget.onDecline?.call(item);
              },
            ),
            _IconAction(
              icon: Icons.check_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF40A6FF),
              semanticLabel: AppStrings.friendsAccept,
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
    final sectionOpen =
        _items.any((item) => !_leaving.contains(item.id));
    return AnimatedSize(
      duration: _anim,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _items.isEmpty
          ? const SizedBox(width: double.infinity)
          : _RequestReveal(
              visible: sectionOpen,
              child: Padding(
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
                              visible: sectionOpen
                                  ? !_entering.contains(_items[i].id) &&
                                      !_leaving.contains(_items[i].id)
                                  : true,
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
            ),
    );
  }

  Widget _requestRow(AppColors colors, FriendRequestItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          FriendPhotoPeekTarget(
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
            _IconAction(
              icon: Icons.close_rounded,
              color: colors.muted,
              semanticLabel: AppStrings.friendsDecline,
              onPressed: () {
                _hide(item.id);
                widget.onDecline?.call(item);
              },
            ),
            _IconAction(
              icon: Icons.check_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF40A6FF),
              semanticLabel: AppStrings.friendsAccept,
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

class _FlyingFriendTile extends StatefulWidget {
  const _FlyingFriendTile({
    super.key,
    required this.friend,
    required this.favorited,
    required this.homePinned,
    required this.from,
    required this.onDone,
  });

  final FriendProfile friend;
  final bool favorited;
  final bool homePinned;
  final Rect from;
  final VoidCallback onDone;

  @override
  State<_FlyingFriendTile> createState() => _FlyingFriendTileState();
}

class _FlyingFriendTileState extends State<_FlyingFriendTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _move;
  late Rect _from = widget.from;
  late Rect _to = widget.from;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _move = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  void flyTo(Rect to) {
    if ((to.center - _from.center).distance < 2) {
      widget.onDone();
      return;
    }
    _from = Rect.lerp(_from, _to, _move.value) ?? _from;
    _to = to;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _move,
        builder: (context, child) {
          final rect = Rect.lerp(_from, _to, _move.value)!;
          return Stack(
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: child!,
              ),
            ],
          );
        },
        child: Material(
          color: colors.card,
          child: _FriendTile(
            friend: widget.friend,
            homePinned: widget.homePinned,
            favorited: widget.favorited,
            onPressed: () {},
            onHomeChanged: (_) {},
            onFavoriteChanged: (_) {},
            onSharedTodo: () {},
            onRemove: () {},
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.homePinned,
    required this.favorited,
    required this.onPressed,
    required this.onHomeChanged,
    required this.onFavoriteChanged,
    required this.onSharedTodo,
    required this.onRemove,
  });

  final FriendProfile friend;
  final bool homePinned;
  final bool favorited;
  final VoidCallback onPressed;
  final ValueChanged<bool> onHomeChanged;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onSharedTodo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
            child: FriendPhotoPeekTarget(size: 40, profile: friend),
          ),
          Expanded(
            child: PressBounce(
              onPressed: onPressed,
              pressedScale: 0.98,
              color: colors.card,
              pressedColor: colors.pressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
            ),
          ),
          FriendStarButton(
            favorited: favorited,
            onPressed: () => onFavoriteChanged(!favorited),
          ),
          OverflowMenuButton(
            actions: [
              OverflowMenuAction(
                label: homePinned
                    ? AppStrings.friendsHomeUnpin
                    : AppStrings.friendsHomePin,
                leadingAsset:
                    homePinned ? AppIcons.removeHome : AppIcons.addHome,
                leadingFlipX: true,
                onPressed: () => onHomeChanged(!homePinned),
              ),
              OverflowMenuAction(
                label: AppStrings.friendsSharedTodoAdd,
                leadingAsset: AppIcons.linkOutlined,
                onPressed: onSharedTodo,
              ),
              OverflowMenuAction(
                label: AppStrings.friendsRemove,
                leadingAsset: AppIcons.trashCan,
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

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Icon(icon, size: 22, color: color),
        ),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                hint,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  color: colors.muted,
                ),
              ),
            ],
          ],
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.of(context).muted,
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
