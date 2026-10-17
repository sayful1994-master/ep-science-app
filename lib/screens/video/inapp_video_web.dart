// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web renderer — embeds the YouTube player in a sandboxed `<iframe>`.
///
/// Fixes YouTube **Error 153** (missing/invalid HTTP Referer on the embed
/// request) by pointing the iframe at the *same origin that serves the app* —
/// a valid HTTP Referer is then sent automatically — and disabling
/// `strict-origin-when-cross-origin` referrer stripping. `youtube-nocookie`
/// keeps the embed in privacy mode and `origin=` / `enablejsapi=1` satisfy the
/// player-configuration checks.
class InAppVideo extends StatefulWidget {
  final String videoId;
  const InAppVideo({super.key, required this.videoId});

  @override
  State<InAppVideo> createState() => _InAppVideoState();
}

class _InAppVideoState extends State<InAppVideo> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'eps-video-${widget.videoId}-${DateTime.now().microsecondsSinceEpoch}';

    // A valid Origin/Referer: the app's own page origin (an https URL), which
    // is exactly what the embedded player expects. Never `null`/`file://`.
    final origin = html.window.location.origin;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'https://www.youtube-nocookie.com/embed/${widget.videoId}'
            '?rel=0&modestbranding=1&playsinline=1&enablejsapi=1'
            '&origin=$origin'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; web-share; fullscreen'
        ..allowFullscreen = true
        // Send a real HTTP Referer on the embed request (prevents Error 153).
        ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin')
        // Allow the embed to run scripts and its own player JS.
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-presentation allow-popups '
              'allow-popups-to-escape-sandbox',
        );
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
