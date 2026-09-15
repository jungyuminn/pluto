export 'focused_ime_text_stub.dart'
    if (dart.library.html) 'focused_ime_text_web.dart'
    if (dart.library.js_interop) 'focused_ime_text_web.dart';

String mergeSuggestTitle({required String flutter, String? ime}) {
  if (ime == null || ime.isEmpty) return flutter;
  if (flutter.isEmpty) return ime;
  if (ime.startsWith(flutter) || flutter.startsWith(ime)) {
    return ime.length >= flutter.length ? ime : flutter;
  }
  return flutter;
}
