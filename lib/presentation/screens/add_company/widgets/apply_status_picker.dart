import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/presentation/screens/add_company/widgets/apply_status_dropdown.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';

class ApplyStatusPicker extends StatefulWidget {
  const ApplyStatusPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.color,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Color color;

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
  var _open = false;
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
    if (_open) {
      await _close();
    } else {
      setState(() => _open = true);
      _portal.show();
      _animation.forward(from: 0);
    }
  }

  Future<void> _close() async {
    if (!_open || _closing) return;
    _closing = true;
    await _animation.reverse();
    if (mounted) {
      _portal.hide();
      setState(() => _open = false);
    }
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
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
                offset: const Offset(0, -6),
                child: UnconstrainedBox(
                  alignment: Alignment.bottomRight,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment: Alignment.bottomRight,
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
        child: EventActionIcon(
          label: AppStrings.colApplyStatus,
          text: widget.value,
          color: widget.color,
          selected: _open,
          onPressed: _toggle,
          child: Image.asset(
            AppIcons.status,
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}
