export 'open_local_file_io.dart'
    if (dart.library.html) 'open_local_file_web.dart'
    if (dart.library.js_interop) 'open_local_file_web.dart';
