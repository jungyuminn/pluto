import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_chip.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_dropdown.dart';

class ApplyStatusPicker extends StatefulWidget {
  const ApplyStatusPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<ApplyStatusPicker> createState() => _ApplyStatusPickerState();
}

class _ApplyStatusPickerState extends State<ApplyStatusPicker>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _fade = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(_fade);
  }

  @override
  void dispose() {
    _fade.dispose();
    _animation.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_portal.isShowing) {
      await _close();
    } else {
      _portal.show();
      _animation.forward(from: 0);
    }
  }

  Future<void> _close() async {
    if (!_portal.isShowing || _closing) return;
    _closing = true;
    await _animation.reverse();
    if (mounted) _portal.hide();
    _closing = false;
  }

  Future<void> _select(String value) async {
    widget.onChanged(value);
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _close,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 6),
                child: UnconstrainedBox(
                  alignment: Alignment.topRight,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment: Alignment.topRight,
                      scale: _scale,
                      child: ApplyStatusDropdown(
                        options: widget.options,
                        onSelected: _select,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: PressBounce(
          color: const Color(0xFFF1F5F9),
          pressedColor: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
          onPressed: _toggle,
          child: ApplyStatusChip(label: widget.value),
        ),
      ),
    );
  }
}
