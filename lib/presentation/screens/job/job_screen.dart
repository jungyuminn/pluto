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
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/entities/license.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/job/widgets/company_list.dart';
import 'package:job_planner/presentation/screens/job/widgets/delete_company_dialog.dart';
import 'package:job_planner/presentation/screens/job/widgets/job_overflow_menu_button.dart';
import 'package:job_planner/presentation/screens/license/widgets/add_license_sheet.dart';
import 'package:job_planner/presentation/screens/license/widgets/delete_license_dialog.dart';
import 'package:job_planner/presentation/screens/license/widgets/license_list.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';
import 'package:job_planner/presentation/widgets/app_bar_wordmark.dart';
import 'package:job_planner/presentation/widgets/overlay_app_bar.dart';

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
  var _licenses = <License>[];
  var _companyCategories = <EventCategory>[];
  var _licenseCategories = <EventCategory>[];
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _searchOpen = false;
  var _sortByDate = false;
  var _showRejected = true;
  var _categoryView = false;
  var _showLicense = false;
  var _licenseCompact = false;
  var _licenseSortByDate = false;
  var _showExpired = true;
  var _licenseCategoryView = false;

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
    AppBackupService.revision.addListener(_onBackupRestored);
  }

  void _readPrefs() {
    final scope = AppScope.of(context);
    _compact = scope.jobViewPreference.isCompact;
    _sortByDate = scope.jobViewPreference.sortByDate;
    _showRejected = scope.jobViewPreference.showRejected;
    _categoryView = scope.jobViewPreference.categoryView;
    _showLicense = scope.jobViewPreference.showLicense;
    _licenseCompact = scope.licenseViewPreference.isCompact;
    _licenseSortByDate = scope.licenseViewPreference.sortByDate;
    _showExpired = scope.licenseViewPreference.showExpired;
    _licenseCategoryView = scope.licenseViewPreference.categoryView;
  }

  void _onBackupRestored() {
    if (!mounted) return;
    _readPrefs();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _readPrefs();
    _reload();
  }

  @override
  void dispose() {
    AppBackupService.revision.removeListener(_onBackupRestored);
    _searchFade.dispose();
    _searchAnimation.dispose();
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  List<JobApplication> get _orderedJobs {
    if (!_sortByDate) return _items;
    return List.of(_items)..sort(JobApplication.compareHomeOrder);
  }

  List<License> get _orderedLicenses {
    if (!_licenseSortByDate) return _licenses;
    return List.of(_licenses)..sort(License.compareDateOrder);
  }

  String _jobCategoryName(JobApplication item) {
    final id = item.categoryId;
    if (id != null && id.isNotEmpty) {
      for (final category in _companyCategories) {
        if (category.id == id) return category.name;
      }
    }
    return item.categoryName;
  }

  String _licenseCategoryName(License item) {
    final id = item.categoryId;
    if (id != null && id.isNotEmpty) {
      for (final category in _licenseCategories) {
        if (category.id == id) return category.name;
      }
    }
    return item.categoryName;
  }

  List<JobApplication> get _visibleJobs {
    final query = _search.text;
    final items = _orderedJobs;
    if (KoreanSearch.compact(query).isEmpty) return items;
    return items.where((item) {
      return KoreanSearch.matchesAny(
        [item.companyName, item.position, _jobCategoryName(item)],
        query,
      );
    }).toList();
  }

  List<License> get _visibleLicenses {
    final query = _search.text;
    final items = _orderedLicenses;
    if (KoreanSearch.compact(query).isEmpty) return items;
    return items.where((item) {
      return KoreanSearch.matchesAny(
        [
          item.name,
          item.issuer,
          item.number,
          item.grade,
          item.fileName ?? '',
          _licenseCategoryName(item),
        ],
        query,
      );
    }).toList();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final items = await scope.getJobApplications();
    final licenses = await scope.getLicenses();
    final companyCategories = await scope.fetchCategories(CategoryKind.company);
    final licenseCategories = await scope.fetchCategories(CategoryKind.license);
    if (!mounted) return;
    setState(() {
      _items = items;
      _licenses = licenses;
      _companyCategories = companyCategories;
      _licenseCategories = licenseCategories;
      _loading = false;
    });
  }

  Future<void> _openAddSheet() async {
    final saved = _showLicense
        ? await showAddLicenseSheet(context)
        : await showAddCompanySheet(context);
    if (saved && mounted) await _reload();
  }

  Future<void> _openEditJob(JobApplication application) async {
    final saved = await showAddCompanySheet(
      context,
      application: application,
    );
    if (saved && mounted) await _reload();
  }

  Future<void> _openEditLicense(License license) async {
    final saved = await showAddLicenseSheet(context, license: license);
    if (saved && mounted) await _reload();
  }

  Future<bool> _confirmDeleteJob(JobApplication application) async {
    final confirmed = await showDeleteCompanyDialog(
      context,
      companyName: application.companyName,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteJobApplication(application.id);
    if (mounted) await _reload();
    return true;
  }

  Future<bool> _confirmDeleteLicense(License license) async {
    final confirmed = await showDeleteLicenseDialog(
      context,
      name: license.name,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteLicense(license.id);
    if (mounted) await _reload();
    return true;
  }

  Future<void> _onJobsReordered(List<JobApplication> ordered) async {
    if (_sortByDate || _categoryView) return;
    final next = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
    ];
    setState(() => _items = next);
    await AppScope.of(context).reorderJobApplications(next);
  }

  Future<void> _onLicensesReordered(List<License> ordered) async {
    if (_licenseSortByDate || _licenseCategoryView) return;
    final next = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
    ];
    setState(() => _licenses = next);
    await AppScope.of(context).reorderLicenses(next);
  }

  Future<void> _explainReorderLock({required bool license}) {
    HapticFeedback.lightImpact();
    final categoryView = license ? _licenseCategoryView : _categoryView;
    final sortByDate = license ? _licenseSortByDate : _sortByDate;
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: categoryView
          ? AppStrings.categoryViewLockBody
          : (sortByDate
              ? AppStrings.timeSortLockBody
              : AppStrings.timeSortLockBody),
    );
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
    final searching = KoreanSearch.compact(_search.text).isNotEmpty;
    final barOverlap = OverlayAppBar.overlapOf(context);
    return AppSkinBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: OverlayAppBar(
          title: AppBarWordmark(
            slot: _showLicense ? WordmarkSlot.license : WordmarkSlot.job,
          ),
          actions: TutorialAnchor(
            id: TutorialAnchorId.jobTools,
            child: AppBarIconGroup(
              actions: [
                AppBarIconAction(
                  asset: AppIcons.search,
                  label: _showLicense
                      ? AppStrings.licenseSearchHint
                      : AppStrings.searchHint,
                  selected: _searchOpen,
                  onPressed: _toggleSearch,
                ),
              ],
              trailing: [
                JobOverflowMenuButton(
                  compact: _compact,
                  onCompactChanged: (value) async {
                    if (value == _compact) return;
                    setState(() => _compact = value);
                    await AppScope.of(context)
                        .jobViewPreference
                        .setCompact(value);
                  },
                  showRejected: _showRejected,
                  onShowRejectedChanged: (value) async {
                    if (value == _showRejected) return;
                    setState(() => _showRejected = value);
                    await AppScope.of(context)
                        .jobViewPreference
                        .setShowRejected(value);
                  },
                  sortByTime: _sortByDate,
                  onSortByTimeChanged: (value) async {
                    if (value == _sortByDate) return;
                    HapticFeedback.selectionClick();
                    setState(() => _sortByDate = value);
                    await AppScope.of(context)
                        .jobViewPreference
                        .setSortByDate(value);
                  },
                  categoryView: _categoryView,
                  onCategoryViewChanged: (value) async {
                    if (value == _categoryView) return;
                    HapticFeedback.selectionClick();
                    setState(() => _categoryView = value);
                    await AppScope.of(context)
                        .jobViewPreference
                        .setCategoryView(value);
                  },
                  showLicense: _showLicense,
                  onShowLicenseChanged: (value) async {
                    if (value == _showLicense) return;
                    setState(() => _showLicense = value);
                    await AppScope.of(context)
                        .jobViewPreference
                        .setShowLicense(value);
                  },
                  licenseCompact: _licenseCompact,
                  onLicenseCompactChanged: (value) async {
                    if (value == _licenseCompact) return;
                    setState(() => _licenseCompact = value);
                    await AppScope.of(context)
                        .licenseViewPreference
                        .setCompact(value);
                  },
                  showExpired: _showExpired,
                  onShowExpiredChanged: (value) async {
                    if (value == _showExpired) return;
                    setState(() => _showExpired = value);
                    await AppScope.of(context)
                        .licenseViewPreference
                        .setShowExpired(value);
                  },
                  licenseSortByTime: _licenseSortByDate,
                  onLicenseSortByTimeChanged: (value) async {
                    if (value == _licenseSortByDate) return;
                    HapticFeedback.selectionClick();
                    setState(() => _licenseSortByDate = value);
                    await AppScope.of(context)
                        .licenseViewPreference
                        .setSortByDate(value);
                  },
                  licenseCategoryView: _licenseCategoryView,
                  onLicenseCategoryViewChanged: (value) async {
                    if (value == _licenseCategoryView) return;
                    HapticFeedback.selectionClick();
                    setState(() => _licenseCategoryView = value);
                    await AppScope.of(context)
                        .licenseViewPreference
                        .setCategoryView(value);
                  },
                  onCategoriesChanged: _reload,
                ),
              ],
            ),
          ),
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
                            padding: EdgeInsets.fromLTRB(
                              20,
                              barOverlap,
                              20,
                              12,
                            ),
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
                                hintText: _showLicense
                                    ? AppStrings.licenseSearchHint
                                    : AppStrings.searchHint,
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
                      child: AnimatedBuilder(
                        animation: _searchFade,
                        builder: (context, _) {
                          final paddingTop =
                              barOverlap * (1 - _searchFade.value);
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _showLicense
                                ? LicenseList(
                                    key: const ValueKey('licenses'),
                                    licenses: _visibleLicenses,
                                    onAdd: _openAddSheet,
                                    onOpen: _openEditLicense,
                                    onDelete: _confirmDeleteLicense,
                                    onReordered: _onLicensesReordered,
                                    onReorderLocked: (_licenseSortByDate ||
                                            _licenseCategoryView)
                                        ? () => _explainReorderLock(
                                            license: true)
                                        : null,
                                    canReorder: !_licenseSortByDate &&
                                        !_licenseCategoryView &&
                                        !searching,
                                    compact: _licenseCompact,
                                    showExpired: _showExpired,
                                    categoryView: _licenseCategoryView,
                                    categories: _licenseCategories,
                                    paddingTop: paddingTop,
                                  )
                                : CompanyList(
                                    key: const ValueKey('jobs'),
                                    applications: _visibleJobs,
                                    onAdd: _openAddSheet,
                                    onOpen: _openEditJob,
                                    onDelete: _confirmDeleteJob,
                                    onReordered: _onJobsReordered,
                                    onReorderLocked:
                                        (_sortByDate || _categoryView)
                                            ? () => _explainReorderLock(
                                                license: false)
                                            : null,
                                    canReorder: !_sortByDate &&
                                        !_categoryView &&
                                        !searching,
                                    compact: _compact,
                                    showRejected: _showRejected,
                                    categoryView: _categoryView,
                                    categories: _companyCategories,
                                    paddingTop: paddingTop,
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
