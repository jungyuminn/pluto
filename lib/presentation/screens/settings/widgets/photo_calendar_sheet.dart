import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/photo_calendar_client.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/presentation/screens/settings/widgets/dots_loading_dialog.dart';

Future<List<CalendarEvent>?> showPhotoCalendarSheet(
  BuildContext context, {
  required List<CalendarEvent> existing,
}) async {
  final photos = await PhotoCalendarClient.pickPhotos();
  if (photos.isEmpty || !context.mounted) return null;
  return showComposeSheet<List<CalendarEvent>>(
    context,
    builder: (context) => PhotoCalendarSheet(
      photos: photos,
      existing: existing,
    ),
  );
}

class PhotoCalendarSheet extends StatefulWidget {
  const PhotoCalendarSheet({
    super.key,
    required this.photos,
    required this.existing,
  });

  final List<Uint8List> photos;
  final List<CalendarEvent> existing;

  @override
  State<PhotoCalendarSheet> createState() => _PhotoCalendarSheetState();
}

class _PhotoCalendarSheetState extends State<PhotoCalendarSheet> {
  final _skipped = <String>{};
  var _events = <CalendarEvent>[];
  var _done = 0;
  var _reading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    var done = 0;
    await for (final drafts in PhotoCalendarClient.readAll(widget.photos)) {
      if (!mounted) return;
      done += 1;
      setState(() {
        _done = done;
        _events = PhotoCalendarClient.toEvents(
          drafts,
          existing: widget.existing,
        );
      });
    }
    if (!mounted) return;
    setState(() {
      _done = widget.photos.length;
      _reading = false;
    });
  }

  List<List<CalendarEvent>> get _rows {
    final seen = <String>{};
    final rows = <List<CalendarEvent>>[];
    for (final event in _events) {
      final groupId = event.groupId;
      if (groupId != null) {
        if (!seen.add(groupId)) continue;
        rows.add([
          for (final item in _events)
            if (item.groupId == groupId) item,
        ]);
      } else {
        rows.add([event]);
      }
    }
    return rows;
  }

  List<CalendarEvent> get _kept => [
        for (final event in _events)
          if (!_skipped.contains(event.id)) event,
      ];

  int get _keptCount => _rows
      .where((row) => row.any((event) => !_skipped.contains(event.id)))
      .length;

  void _toggle(List<CalendarEvent> row) {
    setState(() {
      final ids = [for (final event in row) event.id];
      if (ids.every(_skipped.contains)) {
        _skipped.removeAll(ids);
        return;
      }
      _skipped.addAll(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final bottom = composeSheetBottomOf(context);
    return Material(
      color: colors.card,
      elevation: 0,
      borderRadius: PcLayout.sheetRadius(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * (PcLayout.isPc ? 0.78 : 0.72),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.photoImportTitle,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 6),
              _reading
                  ? _PhotoImportWaitText(
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.secondary,
                      ),
                    )
                  : Text(
                      AppStrings.importConfirmBody(_keptCount),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.secondary,
                      ),
                    ),
              if (_events.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.importConfirmSkipHint,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _events.isEmpty
                    ? Center(
                        child: _reading
                            ? const DotsLoader()
                            : Text(
                                AppStrings.photoImportEmpty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.muted,
                                ),
                              ),
                      )
                    : ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return _PhotoEventTile(
                            event: row.first,
                            last: row.last.day,
                            selected: row.any(
                              (event) => !_skipped.contains(event.id),
                            ),
                            onPressed: () => _toggle(row),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PressBounce(
                      onPressed: () => Navigator.of(context).pop(),
                      color: colors.border,
                      pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontFamily: font,
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
                    child: Opacity(
                      opacity: !_reading && _kept.isNotEmpty ? 1 : 0.45,
                      child: PressBounce(
                      onPressed: !_reading && _kept.isNotEmpty
                          ? () => Navigator.of(context).pop(_kept)
                          : null,
                      color: colors.accentBright,
                      pressedColor: Color.lerp(
                        colors.accentBright,
                        Colors.black,
                        0.16,
                      )!,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            AppStrings.importAction,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}

class _PhotoImportWaitText extends StatefulWidget {
  const _PhotoImportWaitText({required this.style});

  final TextStyle style;

  @override
  State<_PhotoImportWaitText> createState() => _PhotoImportWaitTextState();
}

class _PhotoImportWaitTextState extends State<_PhotoImportWaitText> {
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % AppStrings.photoImportWaits.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Text(
        AppStrings.photoImportWaits[_index],
        key: ValueKey(_index),
        style: widget.style,
      ),
    );
  }
}

class _PhotoEventTile extends StatelessWidget {
  const _PhotoEventTile({
    required this.event,
    required this.last,
    required this.selected,
    required this.onPressed,
  });

  final CalendarEvent event;
  final DateTime last;
  final bool selected;
  final VoidCallback onPressed;

  String _dayText(DateTime date) {
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.year}. ${date.month}. ${date.day}. ($weekday)';
  }

  String get _dateLabel {
    final start = event.day;
    final dateText = last.isAfter(start)
        ? '${_dayText(start)} ~ ${_dayText(last)}'
        : _dayText(start);
    final time = event.timeLabel;
    if (time == null) return dateText;
    return '$dateText · $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final idle = selected
        ? Color.lerp(colors.groupedBackground, colors.accentBright, 0.18)!
        : colors.groupedBackground;
    return PressBounce(
      onPressed: onPressed,
      color: idle,
      pressedColor: Color.lerp(
        idle,
        colors.isDark ? Colors.white : Colors.black,
        colors.isDark ? 0.14 : 0.1,
      )!,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? colors.accentBright : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: selected
                    ? null
                    : Border.all(color: colors.muted, width: 1.8),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
