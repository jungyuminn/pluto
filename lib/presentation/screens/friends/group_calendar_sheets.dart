import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/group_calendar_service.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/group_calendar.dart';
import 'package:pluto/presentation/screens/friends/friend_photo_peek.dart';
import 'package:pluto/presentation/screens/friends/friends_toast.dart';

Future<GroupCalendar?> showCreateGroupCalendarSheet(BuildContext context) {
  return showComposeSheet<GroupCalendar>(
    context,
    builder: (context) => const _NameSheet(),
  );
}

Future<bool> showRenameGroupCalendarSheet(
  BuildContext context, {
  required GroupCalendar calendar,
}) async {
  final ok = await showComposeSheet<bool>(
    context,
    builder: (context) => _NameSheet(calendar: calendar),
  );
  return ok == true;
}

Future<void> showInviteGroupCalendarSheet(
  BuildContext context, {
  required GroupCalendar calendar,
}) {
  return showComposeSheet<void>(
    context,
    builder: (context) => _InviteSheet(calendar: calendar),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({this.calendar});

  final GroupCalendar? calendar;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.calendar?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final service = GroupCalendarService.instance;
    try {
      if (widget.calendar == null) {
        final created = await service.create(_name.text);
        if (!mounted) return;
        Navigator.pop(context, created);
      } else {
        await service.rename(widget.calendar!.id, _name.text);
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      showFriendsToast(context, service.messageOf(error), top: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final renaming = widget.calendar != null;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: BoxDecoration(
          color: colors.groupedBackground,
          borderRadius: PcLayout.sheetRadius(),
        ),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!PcLayout.isPc) ...[
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
            ] else
              const SizedBox(height: 14),
            Text(
              renaming
                  ? AppStrings.groupCalendarRename
                  : AppStrings.groupCalendarCreate,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(16),
                        ],
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: AppStrings.groupCalendarNameHint,
                          hintStyle: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 16,
                            color: colors.muted,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 16,
                          color: colors.text,
                        ),
                      ),
                    ),
                    PressBounce(
                      onPressed: _submit,
                      pressedColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          renaming
                              ? AppStrings.friendsCodeSave
                              : AppStrings.groupCalendarCreate,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.calendar});

  final GroupCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final friends = [
      for (final friend in FriendService.instance.lastFriends)
        if (!calendar.hasMember(friend.uid)) friend,
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors.groupedBackground,
        borderRadius: PcLayout.sheetRadius(),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!PcLayout.isPc) ...[
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
          ] else
            const SizedBox(height: 14),
          Text(
            AppStrings.groupCalendarInvite,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Text(
                AppStrings.groupCalendarNoFriends,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  color: colors.muted,
                ),
              ),
            )
          else
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: friends.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 72),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colors.border,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    return _InviteTile(
                      calendar: calendar,
                      friend: friends[index],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatefulWidget {
  const _InviteTile({required this.calendar, required this.friend});

  final GroupCalendar calendar;
  final FriendProfile friend;

  @override
  State<_InviteTile> createState() => _InviteTileState();
}

class _InviteTileState extends State<_InviteTile> {
  var _busy = false;

  Future<void> _invite() async {
    if (_busy) return;
    setState(() => _busy = true);
    final service = GroupCalendarService.instance;
    try {
      await service.invite(calendar: widget.calendar, friend: widget.friend);
      if (!mounted) return;
      showFriendsToast(context, AppStrings.groupCalendarInvited, top: true);
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showFriendsToast(context, service.messageOf(error), top: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final friend = widget.friend;
    return PressBounce(
      onPressed: _busy ? null : _invite,
      color: colors.card,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            FriendPhotoPeekTarget(size: 40, profile: friend),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 16,
                      color: colors.text,
                    ),
                  ),
                  if (friend.friendCode.isNotEmpty)
                    Text(
                      friend.friendCode,
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
          ],
        ),
      ),
    );
  }
}
