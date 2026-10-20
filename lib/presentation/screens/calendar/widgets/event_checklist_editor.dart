import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/event_checklist_item.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_complete_button.dart';

class EventChecklistEditor extends StatefulWidget {
  const EventChecklistEditor({
    super.key,
    required this.initial,
    required this.color,
    this.readOnly = false,
    this.autofocus = false,
  });

  final List<EventChecklistItem> initial;
  final Color color;
  final bool readOnly;
  final bool autofocus;

  @override
  State<EventChecklistEditor> createState() => EventChecklistEditorState();
}

class EventChecklistEditorState extends State<EventChecklistEditor> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _rows = <_ChecklistRow>[];
  final _leaving = <_ChecklistRow>[];
  var _nextId = DateTime.now().microsecondsSinceEpoch;
  static const _shift = Duration(milliseconds: 340);

  List<EventChecklistItem> cleaned() {
    return EventChecklistItem.cleaned([
      for (final row in _rows) row.item,
    ]);
  }

  @override
  void initState() {
    super.initState();
    for (final item in EventChecklistItem.cleaned(widget.initial)) {
      _rows.add(_ChecklistRow(item));
    }
    if (_rows.isEmpty) {
      _rows.add(_ChecklistRow.empty(_newId()));
    }
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _rows.isEmpty) return;
        _rows.last.focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    for (final row in _leaving) {
      row.dispose();
    }
    super.dispose();
  }

  String _newId() => 'c${_nextId++}';

  void _insertAfter(int index) {
    final row = _ChecklistRow.empty(_newId());
    _rows.insert(index + 1, row);
    _listKey.currentState?.insertItem(index + 1, duration: _shift);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      row.focus.requestFocus();
    });
  }

  void _removeAt(int index) {
    if (_rows.length <= 1 || index < 0 || index >= _rows.length) return;
    final row = _rows.removeAt(index);
    final previous = index == 0 ? _rows.first : _rows[index - 1];
    _leaving.add(row);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _tile(row, animation),
      duration: _shift,
    );
    previous.focus.requestFocus();
    previous.controller.selection = TextSelection.collapsed(
      offset: previous.controller.text.length,
    );
    Future<void>.delayed(_shift, () {
      _leaving.remove(row);
      row.dispose();
    });
  }

  void _onSubmitted(int index) {
    if (widget.readOnly) return;
    if (_rows[index].controller.text.trim().isEmpty) return;
    _insertAfter(index);
  }

  void _onChanged(int index, String value) {
    if (value.contains('\n')) {
      final clean = value.replaceAll('\n', '');
      final row = _rows[index];
      row.controller.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
      _onSubmitted(index);
      return;
    }
    setState(() {});
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (widget.readOnly) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onSubmitted(index);
      return KeyEventResult.handled;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_rows[index].controller.text.isNotEmpty) return KeyEventResult.ignored;
    if (_rows.length <= 1) return KeyEventResult.ignored;
    _removeAt(index);
    return KeyEventResult.handled;
  }

  int _indexOf(_ChecklistRow row) => _rows.indexOf(row);

  Widget _tile(_ChecklistRow row, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return ClipRect(
      child: SizeTransition(
        sizeFactor: curved,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: curved,
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                EventCompleteButton(
                  completed: row.completed,
                  color: widget.color,
                  onPressed: widget.readOnly ||
                          row.controller.text.trim().isEmpty
                      ? null
                      : () {
                          setState(() => row.completed = !row.completed);
                        },
                ),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      final index = _indexOf(row);
                      if (index < 0) return KeyEventResult.ignored;
                      return _onKey(index, event);
                    },
                    child: _ChecklistTextField(
                      controller: row.controller,
                      focusNode: row.focus,
                      completed: row.completed,
                      readOnly: widget.readOnly,
                      onSubmitted: () {
                        final index = _indexOf(row);
                        if (index < 0) return;
                        _onSubmitted(index);
                      },
                      onChanged: (value) {
                        final index = _indexOf(row);
                        if (index < 0) return;
                        _onChanged(index, value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: AnimatedList(
        key: _listKey,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        initialItemCount: _rows.length,
        itemBuilder: (context, index, animation) {
          return _tile(_rows[index], animation);
        },
      ),
    );
  }
}

class _ChecklistTextField extends StatefulWidget {
  const _ChecklistTextField({
    required this.controller,
    required this.focusNode,
    required this.completed,
    required this.readOnly,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool completed;
  final bool readOnly;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  State<_ChecklistTextField> createState() => _ChecklistTextFieldState();
}

class _ChecklistTextFieldState extends State<_ChecklistTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _line;

  @override
  void initState() {
    super.initState();
    _line = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    if (widget.completed) _line.value = 1;
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(_ChecklistTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (!oldWidget.completed && widget.completed) {
      _line.forward();
    } else if (oldWidget.completed && !widget.completed) {
      _line.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _line.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  double _textWidth(TextStyle style, double maxWidth) {
    final text = widget.controller.text;
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _line,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_line.value);
        final style = TextStyle(
          fontFamily: AppFonts.of(context),
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color.lerp(colors.secondary, colors.hint, t),
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
          decorationThickness: 0,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = _textWidth(style, constraints.maxWidth) * t;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    readOnly: widget.readOnly,
                    minLines: 1,
                    maxLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autocorrect: false,
                    enableSuggestions: false,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    onSubmitted: (_) => widget.onSubmitted(),
                    onChanged: widget.onChanged,
                    style: style,
                    decoration: const InputDecoration.collapsed(
                      hintText: null,
                    ),
                  ),
                ),
                if (width > 0)
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: width,
                        height: 1.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.hint,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ChecklistRow {
  _ChecklistRow(EventChecklistItem item)
      : controller = TextEditingController(text: item.text),
        focus = FocusNode(),
        id = item.id,
        completed = item.completed;

  _ChecklistRow.empty(this.id)
      : controller = TextEditingController(),
        focus = FocusNode(),
        completed = false;

  final TextEditingController controller;
  final FocusNode focus;
  final String id;
  var completed = false;

  EventChecklistItem get item {
    return EventChecklistItem(
      id: id,
      text: controller.text,
      completed: completed,
    );
  }

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}
