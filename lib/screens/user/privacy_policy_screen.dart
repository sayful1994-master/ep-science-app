import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// In-app প্রাইভেসি পলিসি — opened from the Profile screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রাইভেসি পলিসি')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GradientHeader(
            title: 'প্রাইভেসি পলিসি',
            subtitle: 'Privacy Policy — E&P Science',
            showBack: true,
          ),
          const SizedBox(height: 16),
          _section(
            '১. ভূমিকা',
            '${AppConfig.appName} অ্যাপটি শিক্ষার্থীদের একাডেমিক ও প্রতিযোগিতামূলক '
                'পরীক্ষার প্রস্তুতিতে সহায়তা করার জন্য তৈরি। আপনার গোপনীয়তা আমাদের '
                'নিকট 중요। এই নীতিমালায় আমরা কী তথ্য সংগ্রহ করি এবং কীভাবে তা ব্যবহার '
                'করি তা ব্যাখ্যা করা হয়েছে।',
          ),
          _section(
            '২. আমরা কী তথ্য সংগ্রহ করি',
            '• নাম, ইমেইল ও মোবাইল নম্বর (অ্যাকাউন্ট তৈরি ও লগইনের জন্য)\n'
                '• শ্রেণি / লক্ষ্য (ক্লাস বা চাকরি প্রস্তুতি) — কনটেন্ট কাস্টমাইজের জন্য\n'
                '• প্রশ্ন সমাধান ও অগ্রগতির তথ্য — আপনার পারফরম্যান্স দেখানোর জন্য\n'
                '• প্রোফাইল ছবি (ঐচ্ছিক) — শুধু আপনি নিজে আপলোড করলে',
          ),
          _section(
            '৩. তথ্য কীভাবে ব্যবহার করা হয়',
            'সংগৃহীত তথ্য শুধুমাত্র অ্যাপের সেবা প্রদান, কনটেন্ট কাস্টমাইজেশন, '
                'অগ্রগতি বিশ্লেষণ ও সাপোর্টের জন্য ব্যবহৃত হয়। আমরা আপনার ব্যক্তিগত '
                'তথ্য কোনো তৃতীয় পক্ষের কাছে বিক্রি বা বিনিময় করি না।',
          ),
          _section(
            '৪. ডেটা সুরক্ষা',
            'আপনার তথ্য নিরাপদ সার্ভারে সংরক্ষিত হয় এবং শুধুমাত্র অনুমোদিত '
                'অ্যাডমিন/শিক্ষক প্রবেশ করতে পারেন। ভিডিও ক্লাস সম্পূর্ণভাবে YouTube-এ '
                'হোস্ট করা হয় — অ্যাপে কোনো ভিডিও ফাইল সংরক্ষণ করা হয় না।',
          ),
          _section(
            '৫. কনটেন্ট নিরাপত্তা',
            'ই-বুক ও নোট সুরক্ষিত ইন-অ্যাপ রিডারে পড়া যায় — স্ক্রিনশট নেওয়া যায়, '
                'তবে টেক্সট কপি, ডাউনলোড ও অননুমোদিত শেয়ারিং নিষ্ক্রিয় রাখা হয়েছে।',
          ),
          _section(
            '৬. শিশুদের গোপনীয়তা',
            'আমাদের অ্যাপ শিক্ষার্থীদের জন্য নিরাপদ। আমরা অপ্রাপ্তবয়স্কদের কাছ থেকে '
                'প্রয়োজনীয় তথ্যের বেশি কিছু সংগ্রহ করি না। অভিভাবকের সম্মতির ভিত্তিতে '
                'অপ্রাপ্তবয়স্করা অ্যাপ ব্যবহার করতে পারেন।',
          ),
          _section(
            '৭. যোগাযোগ',
            'প্রাইভেসি সংক্রান্ত যেকোনো প্রশ্নে যোগাযোগ করুন:\n'
                '📞 ${AppConfig.institutePhone}\n'
                '✉️ ${AppConfig.instituteEmail}\n'
                '🏫 ${AppConfig.instituteAddress}',
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'সর্বশেষ আপডেট: ২০২৫ • ${AppConfig.appName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
