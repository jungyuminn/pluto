import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _compact = false;
  var _sortByTime = false;
  var _showTime = false;
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        leading: PressBounce(
          onPressed: () => Navigator.pop(context),
          pressedColor: Colors.transparent,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
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
          _SectionLabel(AppStrings.settingsAppearanceSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.lightMode,
                checked: true,
                onPressed: () {},
              ),
              _SettingsTile(
                label: AppStrings.darkMode,
                checked: false,
                onPressed: () {},
              ),
            ],
          ),
        ],
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
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.checked,
    required this.onPressed,
  });

  final String label;
  final bool checked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      color: Colors.white,
      pressedColor: const Color(0xFFF8FAFC),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (checked)
                const Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
