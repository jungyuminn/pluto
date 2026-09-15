String? focusedImeText() => null;

class ImeTextWatcher {
  ImeTextWatcher(void Function(String text) onText);

  void dispose() {}
}
