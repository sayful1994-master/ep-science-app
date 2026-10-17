import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'doc_viewer_html.dart';

/// Android / iOS renderer — loads a hardened, self-contained document page into
/// an in-app WebView. PDF (pdf.js) and Word (docx-preview) both render INSIDE
/// the app: no external app, no browser hand-off, no intent, and no file is
/// written to local storage.
///
/// Download / share / print / copy are suppressed at the JS layer (see
/// [buildDocViewerHtml]); navigation away from the embedded document is blocked.
class ExternalDocView extends StatefulWidget {
  final String url;
  final String fileType; // pdf | doc | docx | other
  final String title;
  const ExternalDocView({
    super.key,
    required this.url,
    this.fileType = 'pdf',
    this.title = '',
  });

  @override
  State<ExternalDocView> createState() => _ExternalDocViewState();
}

class _ExternalDocViewState extends State<ExternalDocView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final htmlDoc = buildDocViewerHtml(
      url: widget.url,
      fileType: widget.fileType,
      title: widget.title,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1B2E))
      ..setNavigationDelegate(
        NavigationDelegate(
          // Block any attempt to leave the in-app viewer (external browser,
          // Google Docs viewer fallback, share intents, …). Only in-page
          // navigation (data:/about:) is allowed.
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.startsWith('data:') ||
                url.startsWith('about:') ||
                url.startsWith('blob:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(htmlDoc);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}
