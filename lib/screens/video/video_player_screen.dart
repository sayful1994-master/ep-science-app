import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'inapp_video.dart';

/// In-app video player — plays the YouTube embed INSIDE E&P Science.
class VideoPlayerScreen extends StatelessWidget {
  final VideoClass video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1524),
        title: Text(
          video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: InAppVideo(videoId: video.videoId),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.bg,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (video.className.isNotEmpty)
                        Pill(video.className, color: AppColors.primaryBlue),
                      if (video.subjectName.isNotEmpty)
                        Pill(video.subjectName, color: AppColors.teal),
                    ],
                  ),
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      video.description,
                      style: const TextStyle(fontSize: 13.5, height: 1.6),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 15, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ভিডিওটি E&P Science অ্যাপের ভেতরেই চলছে — কোনো বাইরের অ্যাপ বা ব্রাউজার খোলা হয় না।',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
