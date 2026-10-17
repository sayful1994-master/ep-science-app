import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android / iOS renderer — loads the YouTube embed inside an in-app WebView.
///
/// Fixes YouTube **Error 153** (invalid/missing HTTP Referer) by rendering the
/// embed from a tiny wrapper page whose `baseUrl` is a valid YouTube origin, so
/// the WebView sends a legitimate `Referer`/`Origin` on the embed request.
/// JavaScript (and therefore the player's DOM storage) is enabled, playback
/// stays inside the app, and external navigation is blocked.
class InAppVideo extends StatefulWidget {
  final String videoId;
  const InAppVideo({super.key, required this.videoId});

  @override
  State<InAppVideo> createState() => _InAppVideoState();
}

class _InAppVideoState extends State<InAppVideo> {
  late final WebViewController _controller;
  bool _loading = true;

  static const _referer = 'https://www.youtube.com';

  @override
  void initState() {
    super.initState();

    // Self-contained wrapper: the iframe is created from inside a document
    // whose origin is youtube.com, which makes the embed receive a valid
    // Referer header (the root cause of Error 153).
    final html = '''
<!DOCTYPE html><html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
  html,body{margin:0;padding:0;height:100%;background:#000;overflow:hidden;}
  iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:0;}
</style></head>
<body>
<iframe
  src="https://www.youtube-nocookie.com/embed/${widget.videoId}?rel=0&modestbranding=1&playsinline=1&enablejsapi=1&origin=$_referer"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
  allowfullscreen
  referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body></html>''';

    _controller = WebViewController()
      // Unrestricted JS → the player initialises and its DOM storage works.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          // Keep playback inside the app: allow only the embed + its CDN
          // sub-resources; block anything that tries to open YouTube proper or
          // leave for an external browser.
          onNavigationRequest: (req) {
            final u = req.url;
            if (u.startsWith('about:') ||
                u.startsWith('data:') ||
                u.contains('/embed/') ||
                u.contains('youtube-nocookie.com') ||
                u.contains('youtube.com/embed') ||
                u.contains('googlevideo.com') ||
                u.contains('ytimg.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      // baseUrl = a valid YouTube origin → sends a proper Referer (Error 153 fix).
      ..loadHtmlString(html, baseUrl: _referer);
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
