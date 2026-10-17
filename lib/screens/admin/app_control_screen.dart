import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Admin — live feature switches & dynamic subscription pricing.
///
/// • Smart Generator: এক ক্লিকে লাইভ / বন্ধ (বন্ধ করলে অ্যাপের সব "AI"
///   উল্লেখ এমনিতেই লুকিয়ে যায়)।
/// • ভিডিও ক্লাস: পুরো সেকশন চালু / বন্ধ।
/// • সাবস্ক্রিপশন প্ল্যান (১/২/৩ মাস): দাম অ্যাপ আপডেট ছাড়াই পরিবর্তন।
class AppControlScreen extends StatefulWidget {
  const AppControlScreen({super.key});

  @override
  State<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends State<AppControlScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final plans = data.allPlans;

    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপ কন্ট্রোল ও ফিচার')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── feature switches ──
          const SectionTitle('ফিচার চালু / বন্ধ'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _toggleTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'স্মার্ট জেনারেটর',
                  subtitle:
                      'বন্ধ করলে অ্যাপের সব জায়গা থেকে জেনারেটর ও এর উল্লেখ লুকিয়ে যাবে।',
                  value: data.smartGeneratorEnabled,
                  onChanged: (v) => _setFeature(context, data, v),
                ),
                const Divider(height: 1),
                _toggleTile(
                  icon: Icons.video_library_outlined,
                  title: 'ভিডিও ক্লাস সেকশন',
                  subtitle: 'ভিডিও ক্লাস ট্যাব ও প্লেয়ার চালু / বন্ধ করুন।',
                  value: data.feature('video_classes_enabled'),
                  onChanged: (v) => data.setFeature('video_classes_enabled', v),
                ),
                const Divider(height: 1),
                _toggleTile(
                  icon: Icons.menu_book_outlined,
                  title: 'ই-বুক লাইব্রেরি',
                  subtitle: 'ই-বুক স্টোর দৃশ্যমান থাকুক কি না।',
                  value: data.feature('ebooks_enabled'),
                  onChanged: (v) => data.setFeature('ebooks_enabled', v),
                ),
                const Divider(height: 1),
                _toggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'পপআপ ঘোষণা',
                  subtitle: 'হোম স্ক্রিনে ঘোষণা পপআপ দেখানো হবে কি না।',
                  value: data.feature('announcements_enabled'),
                  onChanged: (v) => data.setFeature('announcements_enabled', v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── subscription plans ──
          const SectionTitle('সাবস্ক্রিপশন প্ল্যান ও মূল্য'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'দাম পরিবর্তন করলে অ্যাপ আপডেট ছাড়াই ইউজারদের প্রিমিয়াম পেজে আপডেট হয়ে যাবে।',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          for (final p in plans) _planCard(context, data, p),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppColors.teal,
      secondary: Icon(icon, color: AppColors.primaryBlue, size: 22),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
      onChanged: onChanged,
    );
  }

  Future<void> _setFeature(
      BuildContext context, DataProvider data, bool value) async {
    await data.setFeature('smart_generator_enabled', value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'স্মার্ট জেনারেটর চালু করা হয়েছে ✓'
              : 'স্মার্ট জেনারেটর বন্ধ — অ্যাপের সব AI উল্লেখ লুকানো হয়েছে',
        ),
        backgroundColor: value ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Widget _planCard(BuildContext context, DataProvider data, SubscriptionPlan p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.labelBn.isEmpty ? '${p.months} মাস' : p.labelBn,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                Text(
                  '${p.months} মাস • ${p.days} দিন',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '৳ ${p.price.toStringAsFixed(0)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.primaryBlue),
          ),
          IconButton(
            onPressed: () => _editPrice(context, data, p),
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primaryBlue, size: 18),
          ),
          Switch(
            value: p.isActive,
            activeThumbColor: AppColors.green,
            onChanged: (v) => data.savePlan(_planWith(p, isActive: v)),
          ),
        ],
      ),
    );
  }

  SubscriptionPlan _planWith(SubscriptionPlan p,
      {double? price, bool? isActive}) {
    return SubscriptionPlan(
      id: p.id,
      months: p.months,
      price: price ?? p.price,
      labelBn: p.labelBn,
      labelEn: p.labelEn,
      days: p.days,
      isActive: isActive ?? p.isActive,
    );
  }

  Future<void> _editPrice(
      BuildContext context, DataProvider data, SubscriptionPlan p) async {
    final ctrl =
        TextEditingController(text: p.price.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${p.labelBn} — মূল্য নির্ধারণ'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'মূল্য (৳)',
            prefixIcon: Icon(Icons.currency_exchange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = double.tryParse(ctrl.text.trim());
      if (v != null && v >= 0) {
        await data.savePlan(_planWith(p, price: v));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('মূল্য আপডেট হয়েছে ✓'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }
}
