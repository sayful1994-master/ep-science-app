import 'package:flutter/material.dart';

/// Fallback renderer (unsupported platforms).
class ExternalDocView extends StatelessWidget {
  final String url;
  final String fileType;
  final String title;
  const ExternalDocView({
    super.key,
    required this.url,
    this.fileType = 'pdf',
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'এই প্ল্যাটফর্মে ইন-অ্যাপ রিডার উপলব্ধ নয়।\n$url',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
