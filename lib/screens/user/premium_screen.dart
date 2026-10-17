import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// প্রিমিয়াম সাবস্ক্রিপশন আনলক — dynamic 1 / 2 / 3-month plans fetched from
/// the data layer (admin-configurable), bKash Send Money + WhatsApp verify.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedIndex = 0;

  Future<void> _openBkash() async {
    final uris = [Uri.parse('bkash://'), Uri.parse('https://www.bkash.com/')];
    for (final u in uris) {
      try {
        if (await canLaunchUrl(u)) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বিকাশ অ্যাপ খুলতে পারেনি — ম্যানুয়ালি খুলুন')),
      );
    }
  }

  Future<void> _openWhatsapp(String number, SubscriptionPlan plan) async {
    final auth = context.read<AuthProvider>();
    final u = auth.user;
    final msg = Uri.encodeComponent(
      '(১) নিবন্ধিত মোবাইল নম্বর: ${u?.phone.isNotEmpty == true ? u!.phone : "____"}\n'
      '(২) অ্যাপ অ্যাকাউন্ট ইমেইল: ${u?.email ?? "____"}\n'
      '(৩) বিকাশ ট্রানজেকশন আইডি (TrxID): ____\n'
      '(৪) সাবস্ক্রিপশন মেয়াদ: ${plan.labelBn} (${plan.months} মাস)\n'
      '(৫) পরিশোধিত পরিমাণ: ৳${plan.price.toStringAsFixed(0)}\n\n'
      'দয়া করে প্রিমিয়াম অ্যাক্সেস সক্রিয় করে দিন।',
    );
    final uri = Uri.parse('https://wa.me/$number?text=$msg');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp খুলতে পারেনি: $number')),
        );
      }
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('কপি হয়েছে: $value')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final plans = data.activePlans;
    if (_selectedIndex >= plans.length) _selectedIndex = 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'প্রিমিয়াম সাবস্ক্রিপশন আনলক করুন',
              subtitle:
                  'ষষ্ঠ থেকে দ্বাদশ শ্রেণি এবং বিসিএস/চাকরি প্রস্তুতি — আপনার পছন্দমতো মেয়াদি প্ল্যান বেছে নিন',
              showBack: true,
              trailing: auth.isPremium
                  ? const Pill('PRO', color: AppColors.gold, filled: true)
                  : null,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (auth.isPremium)
                    _alreadyPremium(auth)
                  else ...[
                    _benefitsCard(data.smartGeneratorEnabled),
                    const SizedBox(height: 16),
                    _planSelector(plans),
                    const SizedBox(height: 16),
                    if (plans.isNotEmpty) ...[
                      _stepCard(
                        step: '১',
                        title: 'বিকাশে সেন্ড মানি করুন',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _amountRow(plans[_selectedIndex]),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openBkash,
                                icon: const Icon(Icons.account_balance_wallet),
                                label: const Text('বিকাশ (Send Money) খুলুন'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE2136E),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _stepCard(
                        step: '২',
                        title: 'WhatsApp-এ পেমেন্ট ভেরিফিকেশন পাঠান',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'টাকা পাঠানোর পর নিচের তথ্যগুলো আমাদের WhatsApp নম্বরে পাঠিয়ে দিন '
                              '(অথবা সরাসরি WhatsApp বাটনে ট্যাপ করুন):',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _bullet('• আপনার নিবন্ধিত মোবাইল নম্বর'),
                            _bullet('• বিকাশ ট্রানজেকশন আইডি (TrxID)'),
                            _bullet(
                              '• আপনি কত মাসের সাবস্ক্রিপশন (১/২/৩/৬/৯ মাস নাকি ১ বছর) নিতে চান',
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '৫-১০ মিনিটের মধ্যে আপনার প্রিমিয়াম এক্সেস সক্রিয় করে দেওয়া হবে।',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _whatsappButton(
                                    AppConfig.whatsapp1,
                                    '01627-444526',
                                    plans[_selectedIndex],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _whatsappButton(
                                    AppConfig.whatsapp2,
                                    '01676-714139',
                                    plans[_selectedIndex],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _noteCard(),
                    ] else
                      const Center(child: Text('কোনো প্ল্যান পাওয়া যায়নি')),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: Text(
          t,
          style: const TextStyle(fontSize: 12.5, height: 1.4),
        ),
      );

  Widget _alreadyPremium(AuthProvider auth) {
    final exp = auth.user?.subscriptionEndDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 46),
          const SizedBox(height: 12),
          const Text(
            'আপনি ইতিমধ্যেই প্রিমিয়াম সদস্য!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (exp != null && exp.isNotEmpty)
                ? 'মেয়াদ শেষ: ${exp.substring(0, 10)}'
                : 'সব অধ্যায়, প্রশ্নব্যাংক, ভিডিও ক্লাস ও ই-বুক সম্পূর্ণ আনলকড।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard(bool genOn) {
    final items = <(String, String)>[
      (
        '📚',
        'একাডেমিক ও চাকরি প্রিপারেশন: ষষ্ঠ-দ্বাদশ শ্রেণির (বিজ্ঞান, মানবিক, ব্যবসায় শিক্ষা) সব অধ্যায় এবং বিসিএস ও সব সরকারি চাকরির সিলেবাস সম্পূর্ণ আনলক।'
      ),
      (
        '📝',
        'প্রশ্নব্যাংক ও নেগেটিভ মার্কিং এক্সাম: বিগত বছরের বোর্ড ও বিসিএস প্রশ্নব্যাংক এবং ২০০ মার্কের মডেল টেস্ট (−০.৫০ নেগেটিভ মার্কিং সহ)।'
      ),
      (
        '🎥',
        'বিষয়ভিত্তিক ইন-অ্যাপ ভিডিও ক্লাস: দক্ষ শিক্ষক দ্বারা পরিচালিত অধ্যায়ভিত্তিক বিশেষ লাইভ ও রেকর্ডকৃত ভিডিও ক্লাসে এক্সেস।'
      ),
      if (genOn)
        (
          '🤖',
          'স্মার্ট এআই টিউটর (AI Tutor): যেকোনো কঠিন প্রশ্ন ও পড়ার সমস্যায় ২৪/৭ তাৎক্ষণিক এআই গাইডেন্স ও উত্তর।'
        ),
      (
        '📖',
        'সিকিউর ই-বুক ও নোট লাইব্রেরি: অ্যাপের ভেতরেই সরাসরি সুরক্ষিত পিডিএফ/ডকুমেন্ট বই, গাইড ও লেকচার শিট পড়ার সুবিধা (ডাউনলোড বা শেয়ার করার ঝুঁকি ছাড়া)।'
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.gold),
              SizedBox(width: 8),
              Text(
                'প্রিমিয়ামে যা যা পাবেন',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      it.$2,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _planSelector(List<SubscriptionPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('সাবস্ক্রিপশন মেয়াদ নির্বাচন করুন'),
        LayoutBuilder(
          builder: (context, constraints) {
            // 2 columns on phones, 3 on wider screens — fits 1/2/3/6/9/12-month
            // plans without horizontal overflow.
            final cols = constraints.maxWidth >= 520 ? 3 : 2;
            final spacing = 10.0;
            final w =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < plans.length; i++)
                  SizedBox(
                    width: w,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedIndex == i
                              ? AppColors.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedIndex == i
                                ? AppColors.primaryBlue
                                : AppColors.divider,
                            width: 1.4,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              plans[i].labelBn.isNotEmpty
                                  ? plans[i].labelBn
                                  : '${plans[i].months} মাস',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: _selectedIndex == i
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳${plans[i].price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: _selectedIndex == i
                                    ? AppColors.gold
                                    : AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _stepCard({
    required String step,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _amountRow(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'সেন্ড মানি নম্বর',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppConfig.institutePhone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'পরিমাণ (${plan.labelBn})',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '৳${plan.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _copy(AppConfig.paymentNumber),
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'নম্বর কপি করুন',
          ),
        ],
      ),
    );
  }

  Widget _whatsappButton(
    String number,
    String label,
    SubscriptionPlan plan,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _openWhatsapp(number, plan),
      icon: const Icon(Icons.chat, size: 17, color: Color(0xFF25D366)),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Color(0xFF25D366)),
      ),
    );
  }

  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.gold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'সেন্ড মানি করার পর তথ্য পাঠালে ৫–১০ মিনিটের মধ্যে অ্যাডমিন আপনার '
              'অ্যাকাউন্টে প্রিমিয়াম চালু করে দেবেন। যেকোনো সমস্যায় WhatsApp-এ যোগাযোগ করুন।',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
