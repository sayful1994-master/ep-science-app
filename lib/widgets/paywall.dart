import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../screens/user/premium_screen.dart';

/// Dynamic Paywall modal — triggered when a Free/Guest user taps locked
/// (premium) content.
class Paywall {
  static Future<void> show(
    BuildContext context, {
    String title = 'প্রিমিয়াম কন্টেন্ট',
    String message =
        'এই অধ্যায়টি প্রিমিয়াম সদস্যদের জন্য সংরক্ষিত। সম্পূর্ণ প্রশ্নব্যাংক, বিগত বছরের প্রশ্ন এবং ২০০ মার্কের বিসিএস মডেল টেস্ট আনলক করুন।',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaywallSheet(title: title, message: message),
    );
  }
}

class _PaywallSheet extends StatelessWidget {
  final String title;
  final String message;
  const _PaywallSheet({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final genOn = context.watch<DataProvider>().smartGeneratorEnabled;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _benefitRow('📚', 'সব বিষয়ের সব অধ্যায় — সম্পূর্ণ আনলক'),
              _benefitRow('📝', 'বিগত বছরের প্রশ্নব্যাংক ও মডেল টেস্ট'),
              _benefitRow('🎥', 'বিষয়ভিত্তিক লাইভ ও রেকর্ডকৃত ভিডিও ক্লাস'),
              if (genOn) _benefitRow('🤖', 'স্মার্ট এআই টিউটর সহায়তা'),
              _benefitRow('📄', 'সিকিউর ইন-অ্যাপ ই-বুক ও নোট লাইব্রেরি'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('প্রিমিয়াম আনলক করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'পরে দেখব',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
