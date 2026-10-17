// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'doc_viewer_html.dart';

/// Web renderer — builds a hardened, self-contained document page and injects
/// it via a sandboxed `<iframe srcdoc>`. The document is fetched and rendered
/// client-side (PDF via pdf.js, Word via docx-preview), so nothing bulky is
/// downloaded to disk and no external app/browser is opened.
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
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'eps-doc-${widget.url.hashCode}-'
        '${DateTime.now().microsecondsSinceEpoch}';
    final htmlDoc = buildDocViewerHtml(
      url: widget.url,
      fileType: widget.fileType,
      title: widget.title,
    );
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('sandbox', 'allow-scripts')
        ..setAttribute('allow', 'fullscreen')
        ..setAttribute('referrerpolicy', 'no-referrer');
      iframe.srcdoc = htmlDoc;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
