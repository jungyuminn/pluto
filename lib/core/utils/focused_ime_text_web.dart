import 'dart:js_interop';

import 'package:web/web.dart' as web;

String? focusedImeText() {
  final active = _valueOf(web.document.activeElement);
  if (active != null && active.isNotEmpty) return active;
  final editing =
      web.document.querySelector('flt-text-editing-host .flt-text-editing') ??
      web.document.querySelector('.flt-text-editing');
  final fromEditing = _valueOf(editing);
  if (fromEditing != null && fromEditing.isNotEmpty) return fromEditing;
  return active ?? fromEditing;
}

String? _valueOf(web.Element? el) {
  if (el == null) return null;
  final tag = el.tagName.toUpperCase();
  if (tag == 'INPUT') return (el as web.HTMLInputElement).value;
  if (tag == 'TEXTAREA') return (el as web.HTMLTextAreaElement).value;
  return null;
}

class ImeTextWatcher {
  ImeTextWatcher(this._onText) {
    _listener = ((web.Event event) {
      final t = event.target;
      String? value;
      if (t != null && t.isA<web.HTMLInputElement>()) {
        value = (t as web.HTMLInputElement).value;
      } else if (t != null && t.isA<web.HTMLTextAreaElement>()) {
        value = (t as web.HTMLTextAreaElement).value;
      } else {
        value = focusedImeText();
      }
      if (value != null) _onText(value);
    }).toJS;
    _capture = true.toJS;
    web.document.addEventListener('input', _listener, _capture);
    web.document.addEventListener('compositionupdate', _listener, _capture);
    web.document.addEventListener('compositionend', _listener, _capture);
  }

  final void Function(String text) _onText;
  late final web.EventListener _listener;
  late final JSAny _capture;

  void dispose() {
    web.document.removeEventListener('input', _listener, _capture);
    web.document.removeEventListener('compositionupdate', _listener, _capture);
    web.document.removeEventListener('compositionend', _listener, _capture);
  }
}
