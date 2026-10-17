import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_selector.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    size: 64,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'E&P Science',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'একাডেমিক ও এডমিশন কেয়ার',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ষষ্ঠ–দ্বাদশ • এইচএসসি • এডমিশন • বিসিএস • ব্যাংক • প্রাইমারি\n'
                  'সম্পূর্ণ প্রশ্নব্যাংক, ই-বুক লাইব্রেরি ও স্মার্ট টিউটর',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                    fontSize: 13.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('শুরু করুন'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().continueAsGuest();
                  },
                  child: Text(
                    'গেস্ট হিসেবে দেখুন',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'v1.0.0 • ${AppConfig.instituteAddress}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  int? _planMonths; // optional subscription duration chosen at signup
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    bool ok;
    if (_isLogin) {
      ok = await auth.login(_email.text, _pass.text);
    } else {
      ok = await auth.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _pass.text,
        intendedPlanMonths: _planMonths ?? 0,
      );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: AppColors.teal,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E&P Science',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'একাডেমিক ও এডমিশন কেয়ার',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  _isLogin ? 'স্বাগতম!' : 'নতুন অ্যাকাউন্ট',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'ষষ্ঠ-দ্বাদশ • এইচএসসি • এডমিশন • বিসিএস • ব্যাংক • প্রাইমারি'
                      : 'বিনামূল্যে রেজিস্টার করে পড়া শুরু করুন',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'পূর্ণ নাম',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ইমেইল',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!_isLogin) ...[
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'মোবাইল নম্বর',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'পাসওয়ার্ড',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        DurationSelector(
                          selectedMonths: _planMonths,
                          onSelect: (m) => setState(
                            () => _planMonths = _planMonths == m ? null : m,
                          ),
                          title: 'প্রিমিয়াম মেয়াদ (ঐচ্ছিক)',
                          subtitle:
                              'রেজিস্ট্রেশনের সময়ই মেয়াদ বেছে নিন — অথবা পরে প্রিমিয়াম পেজ থেকে।',
                          textColor: AppColors.textPrimary,
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: auth.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isLogin ? 'লগইন' : 'রেজিস্টার'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'অ্যাকাউন্ট নেই? রেজিস্টার করুন'
                              : 'আগে থেকেই অ্যাকাউন্ট আছে? লগইন',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().continueAsGuest();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'গেস্ট হিসেবে চালিয়ে যান',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
