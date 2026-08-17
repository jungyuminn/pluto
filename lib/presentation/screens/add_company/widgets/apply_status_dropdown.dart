import 'package:flutter/material.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_menu_item.dart';

class ApplyStatusDropdown extends StatelessWidget {
  const ApplyStatusDropdown({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;

  static const _maxHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: IntrinsicWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  ApplyStatusMenuItem(
                    label: option,
                    onPressed: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
