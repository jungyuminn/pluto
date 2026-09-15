import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/friend_category_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/event_category.dart';

Future<void> showCategoryShareSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const CategoryShareSheet(),
  );
}

class CategoryShareSheet extends StatefulWidget {
  const CategoryShareSheet({super.key});

  @override
  State<CategoryShareSheet> createState() => _CategoryShareSheetState();
}

class _CategoryShareSheetState extends State<CategoryShareSheet> {
  var _categories = <EventCategory>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await FriendCategoryPreference.instance.load();
    if (!mounted) return;
    final categories = await AppScope.of(context).getEventCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _setPublic(String id, bool public) async {
    await FriendCategoryPreference.instance.setPublic(id, public);
    unawaited(FriendService.instance.syncFromLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.groupedBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
            children: [
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
              Center(
                child: Text(
                  AppStrings.friendsCategoryShare,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.friendsCategoryShareHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _loading
                    ? const SizedBox(height: 72)
                    : ValueListenableBuilder<Set<String>>(
                        valueListenable:
                            FriendCategoryPreference.instance.listenable,
                        builder: (context, privateIds, _) {
                          return Column(
                            children: [
                              for (var i = 0; i < _categories.length; i++) ...[
                                _row(
                                  colors,
                                  _categories[i],
                                  public: !privateIds.contains(_categories[i].id),
                                ),
                                if (i != _categories.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 52),
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: colors.border,
                                    ),
                                  ),
                              ],
                            ],
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

  Widget _row(AppColors colors, EventCategory category, {required bool public}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: category.tint,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 12, height: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                color: colors.text,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: FittedBox(
              child: CupertinoSwitch(
                value: public,
                activeTrackColor: colors.accentBright,
                onChanged: (value) => _setPublic(category.id, value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
