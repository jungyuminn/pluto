import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/job/widgets/company_list.dart';
import 'package:job_planner/presentation/screens/job/widgets/delete_company_dialog.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen>
    with SingleTickerProviderStateMixin {
  final _search = PlainTextEditingController();
  final _searchFocus = FocusNode();
  late final AnimationController _searchAnimation;
  late final CurvedAnimation _searchFade;
  var _items = <JobApplication>[];
  var _companyCategories = <EventCategory>[];
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _searchOpen = false;
  var _sortByDate = false;

  @override
  void initState() {
    super.initState();
    _searchAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _searchFade = CurvedAnimation(
      parent: _searchAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _compact = AppScope.of(context).jobViewPreference.isCompact;
    _sortByDate = AppScope.of(context).jobViewPreference.sortByDate;
    _reload();
  }

  @override
  void dispose() {
    _searchFade.dispose();
    _searchAnimation.dispose();
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  List<JobApplication> get _orderedItems {
    if (!_sortByDate) return _items;
    return List.of(_items)..sort(JobApplication.compareHomeOrder);
  }

  String _categoryNameOf(JobApplication item) {
    final id = item.categoryId;
    if (id != null && id.isNotEmpty) {
      for (final category in _companyCategories) {
        if (category.id == id) return category.name;
      }
    }
    return item.categoryName;
  }

  List<JobApplication> get _visibleItems {
    final query = _search.text;
    final items = _orderedItems;
    if (KoreanSearch.compact(query).isEmpty) return items;
    return items.where((item) {
      return KoreanSearch.matchesAny(
        [item.companyName, item.position, _categoryNameOf(item)],
        query,
      );
    }).toList();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final items = await scope.getJobApplications();
    final companyCategories = await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return;
    setState(() {
      _items = items;
      _companyCategories = companyCategories;
      _loading = false;
    });
  }

  Future<void> _openAddSheet() async {
    final saved = await showAddCompanySheet(context);
    if (saved && mounted) await _reload();
  }

  Future<void> _openEditSheet(JobApplication application) async {
    final saved = await showAddCompanySheet(
      context,
      application: application,
    );
    if (saved && mounted) await _reload();
  }

  Future<bool> _confirmDelete(JobApplication application) async {
    final confirmed = await showDeleteCompanyDialog(
      context,
      companyName: application.companyName,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteJobApplication(application.id);
    if (mounted) await _reload();
    return true;
  }

  Future<void> _onReordered(List<JobApplication> ordered) async {
    if (_sortByDate) return;
    final next = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
    ];
    setState(() => _items = next);
    await AppScope.of(context).reorderJobApplications(next);
  }

  Future<void> _toggleDateSort() async {
    HapticFeedback.selectionClick();
    final next = !_sortByDate;
    setState(() => _sortByDate = next);
    await AppScope.of(context).jobViewPreference.setSortByDate(next);
  }

  Future<void> _explainDateSortLock() {
    HapticFeedback.lightImpact();
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: AppStrings.dateSortLockBody,
    );
  }

  Future<void> _toggleCompact() async {
    final next = !_compact;
    setState(() => _compact = next);
    await AppScope.of(context).jobViewPreference.setCompact(next);
  }

  Future<void> _toggleSearch() async {
    if (_searchOpen) {
      _searchFocus.unfocus();
      await _searchAnimation.reverse();
      if (!mounted) return;
      setState(() {
        _searchOpen = false;
        _search.clear();
      });
      return;
    }

    setState(() => _searchOpen = true);
    await _searchAnimation.forward();
    if (mounted) _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppSkinBackground(
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: ThemedAsset(
          asset: AppIcons.jobLogo,
          height: 120,
          semanticLabel: AppStrings.jobScreenTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AppBarIconGroup(
                actions: [
                  AppBarIconAction(
                    asset: AppIcons.search,
                    label: AppStrings.searchHint,
                    selected: _searchOpen,
                    onPressed: _toggleSearch,
                  ),
                  AppBarIconAction(
                    asset: _compact
                        ? AppIcons.detailView
                        : AppIcons.quickView,
                    label: _compact
                        ? AppStrings.detailedView
                        : AppStrings.compactView,
                    onPressed: _toggleCompact,
                  ),
                  AppBarIconAction(
                    asset: _sortByDate
                        ? AppIcons.clock
                        : AppIcons.clockOutlined,
                    label: AppStrings.dateSortAction,
                    selected: _sortByDate,
                    onPressed: _toggleDateSort,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeIn(
              child: Column(
                children: [
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _searchFade,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _searchFade,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: TextField(
                          controller: _search,
                          focusNode: _searchFocus,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.searchHint,
                            hintStyle: TextStyle(
                              fontFamily: AppFonts.of(context),
                              color: AppColors.of(context).muted,
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: AppColors.of(context).card,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                  Expanded(
                    child: CompanyList(
                      applications: _visibleItems,
                      onAdd: _openAddSheet,
                      onOpen: _openEditSheet,
                      onDelete: _confirmDelete,
                      onReordered: _onReordered,
                      onReorderLocked:
                          _sortByDate ? _explainDateSortLock : null,
                      canReorder:
                          !_sortByDate &&
                          KoreanSearch.compact(_search.text).isEmpty,
                      compact: _compact,
                    ),
                  ),
                ],
              ),
            ),
    ),
    );
  }
}
