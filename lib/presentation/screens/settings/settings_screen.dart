import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _compact = false;
  var _sortByTime = false;
  var _showTime = false;
  var _todoReminderLead = TodoReminderLead.off;
  var _summaryEnabled = true;
  var _summaryHour = NotificationPreference.defaultSummaryMinutes;
  var _showLeftover = true;
  var _showToday = true;
  var _showTomorrow = true;
  var _showWeek = false;
  var _showMonth = false;
  var _dark = false;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final scope = AppScope.of(context);
    _compact = scope.homeViewPreference.isCompact;
    _sortByTime = scope.dayEventsViewPreference.sortByTime;
    _showTime = scope.dayEventsViewPreference.showTime;
    _todoReminderLead = scope.notificationPreference.todoReminderLead;
    _summaryEnabled = scope.notificationPreference.summaryEnabled;
    _summaryHour = scope.notificationPreference.summaryMinutes;
    _showLeftover = scope.homeViewPreference.showLeftover;
    _showToday = scope.homeViewPreference.showToday;
    _showTomorrow = scope.homeViewPreference.showTomorrow;
    _showWeek = scope.homeViewPreference.showWeek;
    _showMonth = scope.homeViewPreference.showMonth;
    _dark = scope.themePreference.isDark;
  }

  Future<void> _setCompact(bool value) async {
    if (_compact == value) return;
    setState(() => _compact = value);
    await AppScope.of(context).homeViewPreference.setCompact(value);
  }

  Future<void> _toggleSortByTime() async {
    final next = !_sortByTime;
    setState(() => _sortByTime = next);
    await AppScope.of(context).dayEventsViewPreference.setSortByTime(next);
  }

  Future<void> _toggleShowTime() async {
    final next = !_showTime;
    setState(() => _showTime = next);
    await AppScope.of(context).dayEventsViewPreference.setShowTime(next);
  }

  Future<void> _setShowLeftover(bool value) async {
    setState(() => _showLeftover = value);
    await AppScope.of(context).homeViewPreference.setShowLeftover(value);
  }

  Future<void> _setShowToday(bool value) async {
    setState(() => _showToday = value);
    await AppScope.of(context).homeViewPreference.setShowToday(value);
  }

  Future<void> _setShowTomorrow(bool value) async {
    setState(() => _showTomorrow = value);
    await AppScope.of(context).homeViewPreference.setShowTomorrow(value);
  }

  Future<void> _setShowWeek(bool value) async {
    setState(() => _showWeek = value);
    await AppScope.of(context).homeViewPreference.setShowWeek(value);
  }

  Future<void> _setShowMonth(bool value) async {
    setState(() => _showMonth = value);
    await AppScope.of(context).homeViewPreference.setShowMonth(value);
  }

  Future<void> _setDark(bool value) async {
    if (_dark == value) return;
    setState(() => _dark = value);
    await AppScope.of(context).themePreference.setDark(value);
  }

  Future<void> _openTodoNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _TodoNotificationSettingsPage(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _todoReminderLead =
          AppScope.of(context).notificationPreference.todoReminderLead;
    });
  }

  Future<void> _openSummaryNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _SummaryNotificationSettingsPage(),
      ),
    );
    if (!mounted) return;
    final preference = AppScope.of(context).notificationPreference;
    setState(() {
      _summaryEnabled = preference.summaryEnabled;
      _summaryHour = preference.summaryMinutes;
    });
  }

  static String _leadLabel(TodoReminderLead lead) {
    switch (lead) {
      case TodoReminderLead.off:
        return AppStrings.notifyOff;
      case TodoReminderLead.minutes5:
        return AppStrings.notifyMinutes5;
      case TodoReminderLead.minutes10:
        return AppStrings.notifyMinutes10;
      case TodoReminderLead.minutes30:
        return AppStrings.notifyMinutes30;
      case TodoReminderLead.hours1:
        return AppStrings.notifyHours1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.settingsTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
        children: [
          _SectionLabel(AppStrings.settingsHomeSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.defaultView,
                checked: !_compact,
                onPressed: () => _setCompact(false),
              ),
              _SettingsTile(
                label: AppStrings.categoryView,
                checked: _compact,
                onPressed: () => _setCompact(true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(AppStrings.settingsHomeLayoutSection),
          _SettingsCard(
            children: [
              _SettingsSwitchTile(
                label: AppStrings.homeShowLeftover,
                value: _showLeftover,
                onChanged: _setShowLeftover,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowToday,
                value: _showToday,
                onChanged: _setShowToday,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowTomorrow,
                value: _showTomorrow,
                onChanged: _setShowTomorrow,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowWeek,
                value: _showWeek,
                onChanged: _setShowWeek,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowMonth,
                value: _showMonth,
                onChanged: _setShowMonth,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(AppStrings.settingsTodoSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.timeSortView,
                checked: _sortByTime,
                onPressed: _toggleSortByTime,
              ),
              _SettingsTile(
                label: AppStrings.timeDisplay,
                checked: _showTime,
                onPressed: _toggleShowTime,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(AppStrings.settingsNotificationSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.todoNotificationSetting,
                value: _leadLabel(_todoReminderLead),
                chevron: true,
                onPressed: _openTodoNotificationSettings,
              ),
              _SettingsTile(
                label: AppStrings.summaryNotificationSetting,
                value: _summaryEnabled
                    ? AppStrings.summaryTimeLabel(_summaryHour)
                    : AppStrings.notifyOff,
                chevron: true,
                onPressed: _openSummaryNotificationSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(AppStrings.settingsAppearanceSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.lightMode,
                checked: !_dark,
                onPressed: () => _setDark(false),
              ),
              _SettingsTile(
                label: AppStrings.darkMode,
                checked: _dark,
                onPressed: () => _setDark(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodoNotificationSettingsPage extends StatefulWidget {
  const _TodoNotificationSettingsPage();

  @override
  State<_TodoNotificationSettingsPage> createState() =>
      _TodoNotificationSettingsPageState();
}

class _TodoNotificationSettingsPageState
    extends State<_TodoNotificationSettingsPage> {
  late TodoReminderLead _lead;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _lead = AppScope.of(context).notificationPreference.todoReminderLead;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(TodoReminderLead lead) {
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.todoReminderHint(_SettingsScreenState._leadLabel(lead));
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _select(TodoReminderLead lead) async {
    if (lead.isEnabled) _showHint(lead);
    if (_lead == lead) return;
    if (lead.isEnabled) {
      await TodoReminderService.instance.requestPermission();
    }
    if (!mounted) return;
    setState(() => _lead = lead);
    await AppScope.of(context).notificationPreference.setTodoReminderLead(lead);
    await TodoReminderService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.todoNotificationSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  for (final lead in TodoReminderLead.values)
                    _SettingsTile(
                      label: _SettingsScreenState._leadLabel(lead),
                      checked: _lead == lead,
                      onPressed: () => _select(lead),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryNotificationSettingsPage extends StatefulWidget {
  const _SummaryNotificationSettingsPage();

  @override
  State<_SummaryNotificationSettingsPage> createState() =>
      _SummaryNotificationSettingsPageState();
}

class _SummaryNotificationSettingsPageState
    extends State<_SummaryNotificationSettingsPage> {
  var _enabled = true;
  var _minutes = NotificationPreference.defaultSummaryMinutes;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final preference = AppScope.of(context).notificationPreference;
    _enabled = preference.summaryEnabled;
    _minutes = preference.summaryMinutes;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(int minutes) {
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.summaryReminderHint(minutes);
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _selectOff() async {
    if (!_enabled) return;
    setState(() => _enabled = false);
    await AppScope.of(context).notificationPreference.setSummaryEnabled(false);
    await TodoReminderService.instance.sync();
  }

  Future<void> _selectTime(int minutes) async {
    _showHint(minutes);
    if (_enabled && _minutes == minutes) return;
    await TodoReminderService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _enabled = true;
      _minutes = minutes;
    });
    await AppScope.of(context).notificationPreference.setSummaryMinutes(minutes);
    await TodoReminderService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.summaryNotificationSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  _SettingsTile(
                    label: AppStrings.notifyOff,
                    checked: !_enabled,
                    onPressed: _selectOff,
                  ),
                  for (final minutes in NotificationPreference.summaryTimeOptions)
                    _SettingsTile(
                      label: AppStrings.summaryTimeLabel(minutes),
                      checked: _enabled && _minutes == minutes,
                      onPressed: () => _selectTime(minutes),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
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
            fontFamily: AppFonts.pretendard,
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

class _FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FrostedAppBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
                fontFamily: AppFonts.pretendard,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).text,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(24),
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
                    color: AppColors.of(context).border,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(!value),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: CupertinoSwitch(
                  value: value,
                  activeTrackColor: colors.accentBright,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.onPressed,
    this.checked = false,
    this.value,
    this.chevron = false,
  });

  final String label;
  final bool checked;
  final String? value;
  final bool chevron;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      color: colors.card,
      pressedColor: colors.pressed,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              if (checked)
                Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: colors.text,
                ),
              if (chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
