import 'package:flutter/material.dart';

/// Fallback in-app video renderer (unsupported platforms).
class InAppVideo extends StatelessWidget {
  final String videoId;
  const InAppVideo({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'এই প্ল্যাটফর্মে ইন-অ্যাপ ভিডিও উপলব্ধ নয়।\n$videoId',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
