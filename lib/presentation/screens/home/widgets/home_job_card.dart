import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/job/widgets/company_list.dart';
import 'package:pluto/presentation/screens/job/widgets/delete_company_dialog.dart';
import 'package:pluto/presentation/screens/job/widgets/job_overflow_menu_button.dart';
import 'package:pluto/presentation/screens/license/widgets/add_license_sheet.dart';
import 'package:pluto/presentation/screens/license/widgets/delete_license_dialog.dart';
import 'package:pluto/presentation/screens/license/widgets/license_list.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';

class HomeJobCard extends StatefulWidget {
  const HomeJobCard({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<HomeJobCard> createState() => _HomeJobCardState();
}

class _HomeJobCardState extends State<HomeJobCard> {
  var _items = <JobApplication>[];
  var _licenses = <License>[];
  var _companyCategories = <EventCategory>[];
  var _licenseCategories = <EventCategory>[];
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _sortByDate = false;
  var _sortByStatus = false;
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
    AppBackupService.revision.addListener(_onBackupRestored);
  }

  void _readPrefs() {
    final scope = AppScope.of(context);
    _compact = scope.jobViewPreference.isCompact;
    _sortByDate = scope.jobViewPreference.sortByDate;
    _sortByStatus = scope.jobViewPreference.sortByStatus;
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
    super.dispose();
  }

  List<JobApplication> get _orderedJobs {
    if (_sortByStatus) {
      return List.of(_items)..sort(JobApplication.compareStatusOrder);
    }
    if (!_sortByDate) return _items;
    return List.of(_items)..sort(JobApplication.compareHomeOrder);
  }

  List<License> get _orderedLicenses {
    if (!_licenseSortByDate) return _licenses;
    return List.of(_licenses)..sort(License.compareDateOrder);
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
    if (saved && mounted) {
      await _reload();
      widget.onChanged();
    }
  }

  Future<void> _openEditJob(JobApplication application) async {
    final saved = await showAddCompanySheet(
      context,
      application: application,
    );
    if (saved && mounted) {
      await _reload();
      widget.onChanged();
    }
  }

  Future<void> _openEditLicense(License license) async {
    final saved = await showAddLicenseSheet(context, license: license);
    if (saved && mounted) {
      await _reload();
      widget.onChanged();
    }
  }

  Future<bool> _confirmDeleteJob(JobApplication application) async {
    final confirmed = await showDeleteCompanyDialog(
      context,
      companyName: application.companyName,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteJobApplication(application.id);
    if (mounted) {
      await _reload();
      widget.onChanged();
    }
    return true;
  }

  Future<bool> _confirmDeleteLicense(License license) async {
    final confirmed = await showDeleteLicenseDialog(
      context,
      name: license.name,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteLicense(license.id);
    if (mounted) {
      await _reload();
      widget.onChanged();
    }
    return true;
  }

  Future<void> _onJobsReordered(List<JobApplication> ordered) async {
    if (_sortByDate || _sortByStatus || _categoryView) return;
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
    final sortByStatus = !license && _sortByStatus;
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: categoryView
          ? AppStrings.categoryViewLockBody
          : sortByStatus
              ? AppStrings.statusSortLockBody
              : AppStrings.timeSortLockBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TutorialAnchor(
      id: TutorialAnchorId.homeJob,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.homeCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: colors.shadow.a * 0.55),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0, top: 4),
                      child: Text(
                        _showLicense
                            ? AppStrings.licenseScreenTitle
                            : AppStrings.jobScreenTitle,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                  JobOverflowMenuButton(
                    muted: true,
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
                      setState(() {
                        _sortByDate = value;
                        if (value) _sortByStatus = false;
                      });
                      await AppScope.of(context)
                          .jobViewPreference
                          .setSortByDate(value);
                    },
                    sortByStatus: _sortByStatus,
                    onSortByStatusChanged: (value) async {
                      if (value == _sortByStatus) return;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _sortByStatus = value;
                        if (value) _sortByDate = false;
                      });
                      await AppScope.of(context)
                          .jobViewPreference
                          .setSortByStatus(value);
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
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _showLicense
                      ? LicenseList(
                          key: const ValueKey('licenses'),
                          licenses: _orderedLicenses,
                          onAdd: _openAddSheet,
                          onOpen: _openEditLicense,
                          onDelete: _confirmDeleteLicense,
                          onReordered: _onLicensesReordered,
                          onReorderLocked:
                              (_licenseSortByDate || _licenseCategoryView)
                                  ? () => _explainReorderLock(license: true)
                                  : null,
                          canReorder:
                              !_licenseSortByDate && !_licenseCategoryView,
                          compact: _licenseCompact,
                          showExpired: _showExpired,
                          categoryView: _licenseCategoryView,
                          categories: _licenseCategories,
                          embedded: true,
                        )
                      : CompanyList(
                          key: const ValueKey('jobs'),
                          applications: _orderedJobs,
                          onAdd: _openAddSheet,
                          onOpen: _openEditJob,
                          onDelete: _confirmDeleteJob,
                          onReordered: _onJobsReordered,
                          onReorderLocked: (_sortByDate ||
                                  _sortByStatus ||
                                  _categoryView)
                              ? () => _explainReorderLock(license: false)
                              : null,
                          canReorder: !_sortByDate &&
                              !_sortByStatus &&
                              !_categoryView,
                          compact: _compact,
                          showRejected: _showRejected,
                          categoryView: _categoryView,
                          categories: _companyCategories,
                          embedded: true,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
