import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Payment popup for individual books that require payment.
/// Returns `true` when the user confirms they have sent the money.
class BookPaymentSheet {
  static Future<bool?> show(BuildContext context, Ebook book) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookPayment(book: book),
    );
  }
}

class _BookPayment extends StatelessWidget {
  final Ebook book;
  const _BookPayment({required this.book});

  Future<void> _openBkash() async {
    for (final u in [Uri.parse('bkash://'), Uri.parse('https://www.bkash.com/')]) {
      try {
        if (await canLaunchUrl(u)) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _openWhatsapp(String number) async {
    final u = Uri.parse('https://wa.me/$number');
    try {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.menu_book, color: AppColors.primaryBlue, size: 36),
              const SizedBox(height: 10),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'এই বইটি পেতে ৳${book.price.toStringAsFixed(0)} পেমেন্ট করতে হবে।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            color: AppColors.teal),
                        const SizedBox(width: 10),
                        const Text(
                          'বিকাশ সেন্ড মানি',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '৳${book.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppConfig.institutePhone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: AppConfig.paymentNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('নম্বর কপি হয়েছে')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openBkash,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('বিকাশ (Send Money) খুলুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2136E),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsapp(AppConfig.whatsapp1),
                      icon: const Icon(Icons.chat,
                          size: 16, color: Color(0xFF25D366)),
                      label: const Text('01627-444526',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsapp(AppConfig.whatsapp2),
                      icon: const Icon(Icons.chat,
                          size: 16, color: Color(0xFF25D366)),
                      label: const Text('01676-714139',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'পেমেন্টের স্ক্রিনশট WhatsApp-এ পাঠান। অ্যাডমিন যাচাই করে '
                '৫–১০ মিনিটের মধ্যে বইটি আপনার অ্যাকাউন্টে চালু করে দেবেন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('পেমেন্ট করেছি — অ্যাক্সেসের অনুরোধ পাঠান'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'বাতিল',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
