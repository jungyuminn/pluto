import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/monthly_stats.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_kind_stats.dart';
import 'package:job_planner/presentation/theme/apply_status_colors.dart';

class MonthlyStatsScreen extends StatefulWidget {
  const MonthlyStatsScreen({super.key, this.weekly = false});

  final bool weekly;

  @override
  State<MonthlyStatsScreen> createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  MonthlyStats? _stats;
  var _loading = true;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final applications = await scope.getJobApplications();
    final diaries = await scope.getDiaries();
    final ledgers = await scope.getLedgers();
    if (!mounted) return;
    setState(() {
      if (widget.weekly) {
        final week = MonthlyStats.previousWeek(
          _today,
          startMonday: scope.calendarPreference.startMonday,
        );
        _stats = MonthlyStats.ofRange(
          start: week.start,
          end: week.end,
          events: events,
          applications: applications,
          diaries: diaries,
          ledgers: ledgers,
        );
      } else {
        _stats = MonthlyStats.of(
          month: MonthlyStats.previousMonth(_today),
          events: events,
          applications: applications,
          diaries: diaries,
          ledgers: ledgers,
        );
      }
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    final preference = AppScope.of(context).homeViewPreference;
    if (widget.weekly) {
      await preference.dismissWeeklyStats(_today);
    } else {
      await preference.dismissMonthlyStats(_today);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final stats = _stats;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
            child: Row(
              children: [
                _CircleButton(
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PressBounce(
                    onPressed: _confirm,
                    color: colors.card,
                    pressedColor: colors.pressed,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        AppStrings.confirm,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading || stats == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: _items(stats, colors),
              ),
            ),
        ],
      ),
    );
  }

  Widget _appear(int order, Widget child) {
    return FadeIn(
      delay: Duration(milliseconds: 70 * order),
      offset: const Offset(0, 16),
      child: child,
    );
  }

  Widget _section(int order, List<Widget> children) {
    return _appear(
      order,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<Widget> _items(MonthlyStats stats, AppColors colors) {
    var order = 0;
    final items = <Widget>[
      _appear(
        order++,
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: colors.text,
            ),
            children: [
              TextSpan(
                text: widget.weekly
                    ? '${AppStrings.weeklyStatsHeadline}\n'
                    : '${AppStrings.monthlyStatsHeadlineMonth(stats.month)}\n',
              ),
              ..._headline(stats, colors),
            ],
          ),
        ),
      ),
    ];
    final highlights = _highlights(stats);
    if (highlights.isNotEmpty) {
      items.add(const SizedBox(height: 24));
      items.add(
        _HighlightGrid(
          items: highlights,
          startOrder: order,
        ),
      );
      order += highlights.length;
    }
    if (stats.totalTodos > 0) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsTodoSection),
          const SizedBox(height: 8),
          _ProgressCard(
            done: stats.completedTodos,
            total: stats.totalTodos,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            children: [
              _StatRow(
                label: AppStrings.monthlyStatsCompletedLabel,
                value: '${stats.completedTodos}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsIncompleteLabel,
                value: '${stats.incompleteTodos}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsTotalLabel,
                value: '${stats.totalTodos}',
              ),
            ],
          ),
        ]),
      );
    }
    if (stats.categories.isNotEmpty) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsCategorySection),
          const SizedBox(height: 8),
          _StatsCard(
            children: [
              for (final category in stats.categories)
                _BarRow(
                  label: category.name,
                  done: category.completed,
                  total: category.total,
                  color: Color(category.color),
                ),
            ],
          ),
        ]),
      );
    }
    if (stats.busyDay != null) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsBusyDaySection),
          const SizedBox(height: 8),
          _BusyDayCard(day: stats.busyDay!),
        ]),
      );
    }
    if (stats.companies > 0) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsJobSection),
          const SizedBox(height: 8),
          _StatsCard(
            children: [
              _StatRow(
                label: AppStrings.monthlyStatsRoundsLabel,
                value: '${stats.jobRounds}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsCompaniesLabel,
                value: '${stats.companies}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsCoverLettersLabel,
                value: '${stats.coverLetters}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsFinalPassedLabel,
                value: '${stats.finalPassed}',
                dotColor: ApplyStatusColors.of(ApplyStatus.finalPassed),
              ),
              _StatRow(
                label: AppStrings.monthlyStatsPassedLabel,
                value: '${stats.passed}',
                dotColor: ApplyStatusColors.of(ApplyStatus.interviewPassed),
              ),
              _StatRow(
                label: AppStrings.monthlyStatsRejectedLabel,
                value: '${stats.rejected}',
                dotColor: ApplyStatusColors.rejected,
              ),
              _StatRow(
                label: AppStrings.monthlyStatsInProgressLabel,
                value: '${stats.inProgress}',
                dotColor: ApplyStatusColors.of(ApplyStatus.documentSubmitted),
              ),
            ],
          ),
        ]),
      );
    }
    if (stats.roundTypes.isNotEmpty) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsRoundTypeSection),
          const SizedBox(height: 8),
          _StatsCard(
            children: [
              for (final type in stats.roundTypes)
                _StatRow(
                  label: type.name,
                  value: '${type.count}',
                ),
            ],
          ),
        ]),
      );
    }
    if (stats.diaries > 0) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsDiarySection),
          const SizedBox(height: 8),
          _StatsCard(
            children: [
              _StatRow(
                label: AppStrings.monthlyStatsDiaryCountLabel,
                value: '${stats.diaries}',
              ),
              _StatRow(
                label: AppStrings.monthlyStatsDiaryDaysLabel,
                value: AppStrings.monthlyStatsDiaryDaysValue(stats.diaryDays),
              ),
              if (stats.diaryPhotos > 0)
                _StatRow(
                  label: AppStrings.monthlyStatsDiaryPhotosLabel,
                  value: '${stats.diaryPhotos}',
                ),
              if (stats.diaryCategories.length > 1)
                for (final category in stats.diaryCategories)
                  _StatRow(
                    label: category.name,
                    value: '${category.total}',
                    dotColor: Color(category.color),
                  ),
            ],
          ),
        ]),
      );
    }
    if (!stats.ledger.isEmpty) {
      items.add(
        _section(order++, [
          const SizedBox(height: 28),
          _SectionTitle(AppStrings.monthlyStatsLedgerSection),
          const SizedBox(height: 8),
          _PaddedCard(
            child: LedgerKindStats(
              consumption: stats.ledger.consumption,
              expense: stats.ledger.expense,
              salary: stats.ledger.salary,
              net: stats.ledger.net,
              showSalary: stats.ledger.hasSalary,
            ),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            children: [
              _StatRow(
                label: AppStrings.monthlyStatsLedgerCountLabel,
                value: '${stats.ledger.count}',
              ),
              for (final category in stats.ledgerCategories)
                _StatRow(
                  label: category.name,
                  value: '${category.total}',
                  dotColor: Color(category.color),
                ),
            ],
          ),
        ]),
      );
    }
    return items;
  }

  List<_HighlightItem> _highlights(MonthlyStats stats) {
    final items = <_HighlightItem>[];
    if (stats.totalTodos > 0) {
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsCompletedLabel,
          value: '${stats.completedTodos}',
        ),
      );
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsRateLabel,
          value: AppStrings.monthlyStatsRateValue(stats.completionRate),
        ),
      );
    }
    if (stats.companies > 0) {
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsRoundsLabel,
          value: '${stats.jobRounds}',
        ),
      );
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsCompaniesLabel,
          value: '${stats.companies}',
        ),
      );
    }
    if (stats.diaries > 0 && items.length < 4) {
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsDiaryCountLabel,
          value: '${stats.diaries}',
        ),
      );
    }
    if (!stats.ledger.isEmpty && items.length < 4) {
      items.add(
        _HighlightItem(
          label: AppStrings.monthlyStatsLedgerCountLabel,
          value: '${stats.ledger.count}',
        ),
      );
    }
    if (items.length > 4) return items.sublist(0, 4);
    return items;
  }

  List<InlineSpan> _headline(MonthlyStats stats, AppColors colors) {
    TextSpan accent(String text) => TextSpan(
          text: text,
          style: TextStyle(color: colors.accent),
        );

    if (stats.completedTodos > 0 && stats.jobRounds > 0) {
      return [
        accent(AppStrings.monthlyStatsTodoCount(stats.completedTodos)),
        const TextSpan(text: '${AppStrings.monthlyStatsCompleteAnd}\n'),
        accent(AppStrings.monthlyStatsRoundCount(stats.jobRounds)),
        const TextSpan(text: AppStrings.monthlyStatsRoundsTail),
      ];
    }
    if (stats.completedTodos > 0) {
      return [
        accent(AppStrings.monthlyStatsTodoCount(stats.completedTodos)),
        const TextSpan(text: '\n${AppStrings.monthlyStatsCompletedTail}'),
      ];
    }
    if (stats.totalTodos > 0 && stats.jobRounds > 0) {
      return [
        accent(AppStrings.monthlyStatsTodoCount(stats.totalTodos)),
        const TextSpan(text: '${AppStrings.monthlyStatsAnd}\n'),
        accent(AppStrings.monthlyStatsRoundCount(stats.jobRounds)),
        const TextSpan(text: AppStrings.monthlyStatsTotalTail),
      ];
    }
    if (stats.jobRounds > 0) {
      return [
        accent(AppStrings.monthlyStatsRoundCount(stats.jobRounds)),
        const TextSpan(text: '\n${AppStrings.monthlyStatsRoundsTail}'),
      ];
    }
    if (stats.totalTodos > 0) {
      return [
        accent(AppStrings.monthlyStatsTodoCount(stats.totalTodos)),
        const TextSpan(text: '\n${AppStrings.monthlyStatsTotalTail}'),
      ];
    }
    if (stats.diaries > 0 && !stats.ledger.isEmpty) {
      return [
        accent(AppStrings.monthlyStatsDiaryCount(stats.diaries)),
        const TextSpan(text: '${AppStrings.monthlyStatsAnd}\n'),
        accent(AppStrings.monthlyStatsLedgerCount(stats.ledger.count)),
        const TextSpan(text: AppStrings.monthlyStatsTotalTail),
      ];
    }
    if (stats.diaries > 0) {
      return [
        accent(AppStrings.monthlyStatsDiaryCount(stats.diaries)),
        const TextSpan(text: '\n${AppStrings.monthlyStatsDiaryWroteTail}'),
      ];
    }
    if (!stats.ledger.isEmpty) {
      return [
        accent(AppStrings.monthlyStatsLedgerCount(stats.ledger.count)),
        const TextSpan(text: '\n${AppStrings.monthlyStatsTotalTail}'),
      ];
    }
    return const [TextSpan(text: AppStrings.monthlyStatsEmptyTail)];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.of(context).text,
      ),
    );
  }
}

class _HighlightItem {
  const _HighlightItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _HighlightGrid extends StatelessWidget {
  const _HighlightGrid({
    required this.items,
    required this.startOrder,
  });

  final List<_HighlightItem> items;
  final int startOrder;

  @override
  Widget build(BuildContext context) {
    Widget tile(int index) {
      return FadeIn(
        delay: Duration(milliseconds: 70 * (startOrder + index)),
        offset: const Offset(0, 16),
        child: _HighlightTile(item: items[index]),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            Expanded(child: tile(i)),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < items.length ? tile(i + 1) : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.item});

  final _HighlightItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
                color: colors.accentBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = total == 0 ? 0.0 : done / total;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.monthlyStatsRateLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colors.text,
                    ),
                  ),
                ),
                Text(
                  AppStrings.monthlyStatsRateValue(
                    ((progress * 100).round()),
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    color: colors.accentBright,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.monthlyStatsFraction(done, total),
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusyDayCard extends StatelessWidget {
  const _BusyDayCard({required this.day});

  final MonthlyBusyDay day;

  String _titleOf(MonthlyBusyDayItem item) {
    final title = item.title.trim();
    if (title.isNotEmpty) return title;
    return switch (item.kind) {
      MonthlyBusyDayKind.diary => AppStrings.monthlyStatsDiarySection,
      MonthlyBusyDayKind.ledger => AppStrings.monthlyStatsLedgerCountLabel,
      MonthlyBusyDayKind.job => AppStrings.monthlyStatsJobSection,
      MonthlyBusyDayKind.todo => AppStrings.monthlyStatsTodoSection,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final weekday = AppStrings.weekdays[day.date.weekday % 7];
    final dateLabel = '${day.date.month}. ${day.date.day}. ($weekday)';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                Text(
                  AppStrings.monthlyStatsBusyDayCount(day.items.length),
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.accentBright,
                  ),
                ),
              ],
            ),
            if (day.items.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var i = 0; i < day.items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _BusyDayItemRow(
                  title: _titleOf(day.items[i]),
                  item: day.items[i],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BusyDayItemRow extends StatelessWidget {
  const _BusyDayItemRow({
    required this.title,
    required this.item,
  });

  final String title;
  final MonthlyBusyDayItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = Color(item.color);
    final muted = item.completed;
    final trailing = item.trailing ?? item.timeLabel;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: muted ? colors.muted : color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: muted ? colors.muted : colors.text,
            ),
          ),
        ),
        if (trailing != null && trailing.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            trailing,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: muted ? colors.muted : color,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaddedCard extends StatelessWidget {
  const _PaddedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: child,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
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
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.dotColor,
  });

  final String label;
  final String value;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colors.text,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });

  final String label;
  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              Text(
                AppStrings.monthlyStatsFraction(done, total),
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}
