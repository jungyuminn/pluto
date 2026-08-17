import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_nav_item.dart';
import 'package:job_planner/presentation/screens/shell/widgets/sliding_nav_indicator.dart';

class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (filled: AppIcons.home, outlined: AppIcons.homeOutlined),
    (filled: AppIcons.calendar, outlined: AppIcons.calendarOutlined),
    (filled: AppIcons.office, outlined: AppIcons.officeOutlined),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: 4 + bottomInset),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: const StadiumBorder(),
        child: SizedBox(
          width: 240,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SlidingNavIndicator(
                    index: currentIndex,
                    itemCount: _items.length,
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: PillNavItem(
                          selected: i == currentIndex,
                          onTap: () => onChanged(i),
                          filledAsset: _items[i].filled,
                          outlinedAsset: _items[i].outlined,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
