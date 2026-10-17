// Platform-selecting export for the in-app YouTube player.
// Web → iframe embed; Android/iOS → WebView with the YouTube embed URL.
// Nothing ever opens the external YouTube app or browser.
export 'inapp_video_stub.dart'
    if (dart.library.js_interop) 'inapp_video_web.dart'
    if (dart.library.io) 'inapp_video_io.dart';
