// Platform-selecting export for the secure in-app document renderer.
//
// Renders an externally-hosted PDF **and** Word (.doc/.docx) INSIDE the app —
// web uses a sandboxed `<iframe srcdoc>`, Android/iOS uses an in-app WebView.
// No download / share / print / copy affordances are exposed.
export 'external_doc_view_stub.dart'
    if (dart.library.js_interop) 'external_doc_view_web.dart'
    if (dart.library.io) 'external_doc_view_io.dart';
