import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void syncWebThemeColor(Color color) {
  final hex =
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  var engine = web.document.querySelector('#flutterweb-theme');
  if (engine == null) {
    final meta = web.HTMLMetaElement()
      ..id = 'flutterweb-theme'
      ..name = 'theme-color'
      ..content = hex;
    web.document.head?.append(meta);
  } else if (engine is web.HTMLMetaElement) {
    engine.content = hex;
  }

  final metas = web.document.querySelectorAll('meta[name="theme-color"]');
  for (var i = 0; i < metas.length; i++) {
    final node = metas.item(i);
    if (node is web.HTMLMetaElement) {
      node.content = hex;
    }
  }
}
