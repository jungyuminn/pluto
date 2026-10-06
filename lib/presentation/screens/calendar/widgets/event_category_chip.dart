import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/event_category.dart';

class EventCategoryChip extends StatelessWidget {
  const EventCategoryChip({
    super.key,
    required this.name,
    required this.color,
    required this.onPressed,
    this.selected = true,
    this.mark,
    this.caption,
  });

  final String name;
  final Color color;
  final VoidCallback onPressed;
  final bool selected;
  final Widget? mark;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    final ink = EventCategory.labelOf(color);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: PressBounce(
        onPressed: onPressed,
        color: AppColors.of(context).card,
        pressedColor: AppColors.of(context).pressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 8, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark ??
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: selected ? ink : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selected
                          ? null
                          : Border.all(color: ink, width: 1.4),
                    ),
                  ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: caption ??
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
