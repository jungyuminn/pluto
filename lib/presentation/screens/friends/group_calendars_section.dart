import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/group_calendar_service.dart';
import 'package:pluto/domain/entities/group_calendar.dart';
import 'package:pluto/presentation/screens/friends/friend_photo_peek.dart';
import 'package:pluto/presentation/screens/friends/group_calendar_screen.dart';
import 'package:pluto/presentation/widgets/app_arrow.dart';

class GroupCalendarsBlock extends StatelessWidget {
  const GroupCalendarsBlock({super.key, required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IncomingInvites(onToast: onToast),
        const _Calendars(),
      ],
    );
  }
}

class _IncomingInvites extends StatelessWidget {
  const _IncomingInvites({required this.onToast});

  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    final service = GroupCalendarService.instance;
    return StreamBuilder(
      stream: service.incomingInvites(),
      initialData: service.lastInvites,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <GroupCalendarInvite>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final colors = AppColors.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, AppStrings.groupCalendarIncoming),
              _card(
                colors,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 68),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.border,
                          ),
                        ),
                      _InviteRow(
                        invite: items[i],
                        onToast: onToast,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.onToast});

  final GroupCalendarInvite invite;
  final ValueChanged<String> onToast;

  Future<void> _respond(BuildContext context, bool accept) async {
    final service = GroupCalendarService.instance;
    try {
      if (accept) {
        await service.accept(invite.id);
        onToast(AppStrings.groupCalendarAccepted);
      } else {
        await service.decline(invite.id);
      }
    } catch (error) {
      onToast(service.messageOf(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          FriendPhotoPeekTarget(size: 40, profile: invite.fromProfile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.calendarName.isEmpty
                      ? AppStrings.groupCalendar
                      : invite.calendarName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    color: colors.text,
                  ),
                ),
                Text(
                  invite.fromLabel,
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
          _IconAction(
            icon: Icons.close_rounded,
            color: colors.muted,
            onPressed: () => _respond(context, false),
          ),
          _IconAction(
            icon: Icons.check_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF60A5FA)
                : const Color(0xFF40A6FF),
            onPressed: () => _respond(context, true),
          ),
        ],
      ),
    );
  }
}

class _Calendars extends StatelessWidget {
  const _Calendars();

  void _open(BuildContext context, GroupCalendar calendar) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupCalendarScreen(calendar: calendar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = GroupCalendarService.instance;
    return StreamBuilder(
      stream: service.calendars(),
      initialData: service.lastCalendars,
      builder: (context, snapshot) {
        final calendars = snapshot.data ?? const <GroupCalendar>[];
        if (calendars.isEmpty) return const SizedBox.shrink();
        final colors = AppColors.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, AppStrings.groupCalendar),
              _card(
                colors,
                child: Column(
                  children: [
                    for (var i = 0; i < calendars.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.border,
                          ),
                        ),
                      _CalendarTile(
                        calendar: calendars[i],
                        onPressed: () => _open(context, calendars[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.calendar, required this.onPressed});

  final GroupCalendar calendar;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.card,
      pressedColor: colors.pressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calendar.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 16,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    AppStrings.groupCalendarMemberCount(
                      calendar.memberUids.length,
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            AppArrow.right(size: 22, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

Widget _label(BuildContext context, String text) {
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

Widget _card(AppColors colors, {required Widget child}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(24),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: child,
    ),
  );
}
