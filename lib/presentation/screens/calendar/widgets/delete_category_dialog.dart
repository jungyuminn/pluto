import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/event_category.dart';

enum CategoryDeleteScope { categoryOnly, withItems }

Future<CategoryDeleteScope?> showDeleteCategoryDialog(
  BuildContext context, {
  String? categoryName,
  bool multiple = false,
  CategoryKind kind = CategoryKind.event,
}) {
  return showDialog<CategoryDeleteScope>(
    context: context,
    builder: (context) => DeleteCategoryDialog(
      categoryName: categoryName,
      multiple: multiple,
      kind: kind,
    ),
  );
}

class DeleteCategoryDialog extends StatelessWidget {
  const DeleteCategoryDialog({
    super.key,
    this.categoryName,
    this.multiple = false,
    this.kind = CategoryKind.event,
  });

  final String? categoryName;
  final bool multiple;
  final CategoryKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = categoryName?.trim() ?? '';
    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      constraints: PcLayout.isPc
          ? const BoxConstraints.tightFor(width: PcLayout.pcDayDialogWidth)
          : const BoxConstraints(minWidth: 280, maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (multiple || name.isEmpty)
              Text(
                AppStrings.deleteSelectedCategoriesBody,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              )
            else
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.danger,
                      ),
                    ),
                    TextSpan(text: ' ${AppStrings.deleteCategoryBody}'),
                  ],
                ),
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
            const SizedBox(height: 20),
            _OptionButton(
              label: AppStrings.deleteCategoryOnly,
              onPressed: () {
                Navigator.of(context).pop(CategoryDeleteScope.categoryOnly);
              },
            ),
            const SizedBox(height: 10),
            _OptionButton(
              label: switch (kind) {
                CategoryKind.company => AppStrings.deleteCategoryWithApplications,
                CategoryKind.ledger => AppStrings.deleteCategoryWithLedgers,
                CategoryKind.license => AppStrings.deleteCategoryWithLicenses,
                CategoryKind.event => AppStrings.deleteCategoryWithItems,
              },
              onPressed: () {
                Navigator.of(context).pop(CategoryDeleteScope.withItems);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.pressed,
      pressedColor: Color.lerp(colors.pressed, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
