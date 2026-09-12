import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/wordmark_preference.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

export 'package:pluto/data/datasources/wordmark_preference.dart'
    show WordmarkSlot;

class AppBarWordmark extends StatelessWidget {
  const AppBarWordmark({super.key, required this.slot});

  final WordmarkSlot slot;

  static const _duration = Duration(milliseconds: 340);

  String _fallback() {
    return switch (slot) {
      WordmarkSlot.home => AppStrings.appName,
      WordmarkSlot.job => AppStrings.jobScreenTitle,
      WordmarkSlot.license => AppStrings.licenseScreenTitle,
    };
  }

  Future<void> _edit(BuildContext context) async {
    HapticFeedback.selectionClick();
    final preference = AppScope.of(context).wordmarkPreference;
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _WordmarkEditDialog(
        initial: preference.customOf(slot) ?? _fallback(),
        hint: _fallback(),
      ),
    );
    if (next == null) return;
    await preference.setCustom(slot, next);
  }

  @override
  Widget build(BuildContext context) {
    final preference = AppScope.of(context).wordmarkPreference;
    return ListenableBuilder(
      listenable: preference,
      builder: (context, _) {
        final label = preference.customOf(slot) ?? _fallback();
        final showLogo =
            slot == WordmarkSlot.home && label == AppStrings.appName;
        return PressBounce(
          onPressed: () => _edit(context),
          pressedScale: 0.96,
          pressedColor: AppColors.of(context).pressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppFonts.wordmarkLeftInset,
              8,
              12,
              8,
            ),
            child: AnimatedSwitcher(
              duration: _duration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ...previous,
                    ?current,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: Row(
                key: ValueKey('$showLogo-$label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLogo)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: _PopLogo(
                        child: AppAssetImage(
                          asset: AppIcons.plutoLogoWordmark,
                          width: 34,
                          height: 34,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.jalnan,
                        fontSize: AppFonts.wordmarkSize,
                        height: 1.1,
                        color: AppFonts.wordmarkColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PopLogo extends StatefulWidget {
  const _PopLogo({required this.child});

  final Widget child;

  @override
  State<_PopLogo> createState() => _PopLogoState();
}

class _PopLogoState extends State<_PopLogo> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      scale: _ready ? 1 : 0.55,
      child: widget.child,
    );
  }
}

class _WordmarkEditDialog extends StatefulWidget {
  const _WordmarkEditDialog({
    required this.initial,
    required this.hint,
  });

  final String initial;
  final String hint;

  @override
  State<_WordmarkEditDialog> createState() => _WordmarkEditDialogState();
}

class _WordmarkEditDialogState extends State<_WordmarkEditDialog> {
  late final PlainTextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = PlainTextEditingController(text: widget.initial);
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: SizedBox(
        width: PcLayout.isPc ? PcLayout.homeCardWidth : double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: 20,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.text,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontFamily: AppFonts.of(context),
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
              counterText: '',
              filled: true,
              fillColor: colors.pressed,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(_text.text),
                  color: colors.accentBright,
                  pressedColor:
                      Color.lerp(colors.accentBright, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
