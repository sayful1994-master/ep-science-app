/// Parses a YouTube video id from the many link shapes users paste.
/// Supports: watch?v=, youtu.be/, /shorts/, /embed/, /live/, and bare ids.
String? parseYoutubeId(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;

  // Bare id (11 chars, url-safe)
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(s)) return s;

  Uri? uri;
  try {
    uri = Uri.parse(s.startsWith('http') ? s : 'https://$s');
  } catch (_) {
    return null;
  }

  // youtu.be/<id>
  if (uri.host.contains('youtu.be')) {
    final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    if (seg.isNotEmpty) return seg;
  }

  // watch?v=<id>
  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) return v;

  // /shorts/<id>, /embed/<id>, /live/<id>, /v/<id>
  final segs = uri.pathSegments;
  for (var i = 0; i < segs.length - 1; i++) {
    if (['shorts', 'embed', 'live', 'v'].contains(segs[i])) {
      return segs[i + 1];
    }
  }
  return null;
}

String youtubeThumb(String videoId) =>
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
