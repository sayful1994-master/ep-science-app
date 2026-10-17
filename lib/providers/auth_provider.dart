import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/local_db.dart';

/// E&P Science — authentication + access-control state.
class AuthProvider extends ChangeNotifier {
  final LocalDb _db = LocalDb.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _user;
  bool _isGuest = false;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null && !_isGuest;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isPremium => _user?.hasActivePremium ?? false;
  bool get canDownloadPdf => _user?.canDownloadPdf ?? false;
  bool get busy => _busy;
  String? get error => _error;

  /// True when a signed-in user still needs to pick Class / Job (mandatory).
  bool get needsOnboarding =>
      isLoggedIn && !isAdmin && (_user?.studyFor.isEmpty ?? true);

  /// Access-control: guest → previews only; free → chapters 1 & 2;
  /// premium → everything.
  bool canAccessChapter(int chapterIndex, {required bool questionPremium}) {
    if (isPremium) return true;
    if (_isGuest) return false;
    if (chapterIndex < AppConfig.freeChapterLimit) return true;
    return false;
  }

  bool canAccessQuestion(Question q, int chapterIndex) {
    if (isPremium) return true;
    if (_isGuest) return false;
    return !q.isPremium && chapterIndex < AppConfig.freeChapterLimit;
  }

  void continueAsGuest() {
    _isGuest = true;
    _user = AppUser.guest();
    _error = null;
    notifyListeners();
  }

  /// ১. লগইন হ্যান্ডলার (ফায়ারবেস + অ্যাডমিন ম্যানুয়াল অ্যাকাউন্ট + ভেরিফিকেশন চেক)
  Future<bool> login(String email, String password) async {
    _setBusy(true);
    final e = email.trim().toLowerCase();

    // অ্যাডমিন লগইন (Primary Admin / Institute Admin)
    final isInstituteAdmin =
        e == AppConfig.adminEmail.toLowerCase() &&
        password == AppConfig.adminPassword;
    final isPrimaryAdmin =
        email.trim() == AppConfig.primaryAdminId &&
        password == AppConfig.primaryAdminPassword;

    if (isInstituteAdmin || isPrimaryAdmin) {
      final adminKey = isPrimaryAdmin
          ? AppConfig.primaryAdminId
          : AppConfig.adminEmail.toLowerCase();
      var admin = _db.users.where((u) => u.role == 'admin' && u.email == adminKey).firstOrNull;
      if (admin == null) {
        admin = AppUser(
          uid: 'admin_$adminKey',
          name: isPrimaryAdmin ? 'Sayful Islam' : 'E&P Science Admin',
          email: adminKey,
          role: 'admin',
          isPremium: true,
          isApproved: true,
          canDownloadPdf: true,
        );
        await _db.upsertUser(admin);
      }
      _user = admin;
      _isGuest = false;
      _error = null;
      _setBusy(false);
      return true;
    }

    try {
      // Firebase Auth দিয়ে সাইন ইন চেষ্টা
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: e,
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        // ডেটাবেজ থেকে ইউজারের তথ্য আনুন (অ্যাডমিন দ্বারা তৈরি কি না চেক করার জন্য)
        var existingUser = _db.users.where((x) => x.email.toLowerCase() == e).firstOrNull;

        // অ্যাডমিন ক্রিয়েটেড অ্যাকাউন্ট হলে অথবা ইমেইল ভেরিফাইড হলে ঢুকতে দেবে
        bool createdByAdmin = existingUser?.createdByAdmin ?? false;

        if (!firebaseUser.emailVerified && !createdByAdmin) {
          // নিজে সাইন-আপ করেছে কিন্তু ইমেইল ভেরিফাই করেনি
          await firebaseUser.sendEmailVerification(); // পুনরায় ইমেইল পাঠাবে
          _error = 'আপনার জিমেইল ভেরিফাই করা হয়নি! অনুগ্রহ করে জিমেইল চেক করে ভেরিফিকেশন সম্পন্ন করুন।';
          await _auth.signOut();
          _setBusy(false);
          return false;
        }

        // ভেরিফাইড ইউজার অথবা অ্যাডমিন কর্তৃক তৈরি ইউজার
        if (existingUser != null) {
          _user = _revertIfExpired(existingUser);
        } else {
          _user = AppUser(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? e.split('@').first,
            email: e,
          );
        }

        await _db.upsertUser(_user!);
        _isGuest = false;
        _error = null;
        _setBusy(false);
        return true;
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'user-not-found') {
        _error = 'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি';
      } else if (err.code == 'wrong-password') {
        _error = 'পাসওয়ার্ড ভুল হয়েছে';
      } else {
        _error = err.message ?? 'লগইন ফেইল করেছে';
      }
    } catch (err) {
      _error = 'লগইন করতে সমস্যা হচ্ছে, আবার চেষ্টা করুন';
    }

    _setBusy(false);
    return false;
  }

  /// ২. ইউজার দ্বারা সাধারণ রেজিস্ট্রেশন (জিমেইলে অটোমেটিক ভেরিফিকেশন পাঠানো হবে)
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    int intendedPlanMonths = 0,
  }) async {
    _setBusy(true);
    if (!email.contains('@') || password.length < 4 || name.trim().isEmpty) {
      _error = 'সব তথ্য সঠিকভাবে পূরণ করুন';
      _setBusy(false);
      return false;
    }

    try {
      // ফায়ারবেসে ইউজার ক্রিয়েট
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        // জিমেইলে ভেরিফিকেশন ইমেইল পাঠানো
        await firebaseUser.sendEmailVerification();

        final nu = AppUser(
          uid: firebaseUser.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          intendedPlanMonths: intendedPlanMonths,
          createdByAdmin: false, // ইউজার নিজে সাইনআপ করেছে
        );

        await _db.upsertUser(nu);
        
        // ভেরিফাই না করা পর্যন্ত লগআউট রাখা হবে
        await _auth.signOut();

        _error = 'আপনার জিমেইলে ভেরিফিকেশন লিংক পাঠানো হয়েছে। জিমেইল থেকে ইমেইলটি ভেরিফাই করে লগইন করুন।';
        _setBusy(false);
        return true;
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'email-already-in-use') {
        _error = 'এই ইমেইল দিয়ে অলরেডি অ্যাকাউন্ট তৈরি করা আছে';
      } else {
        _error = err.message ?? 'রেজিস্ট্রেশন ফেইল করেছে';
      }
    } catch (err) {
      _error = 'রেজিস্ট্রেশন করতে সমস্যা হচ্ছে';
    }

    _setBusy(false);
    return false;
  }

  /// ৩. অ্যাডমিন প্যানেল থেকে ম্যানুয়ালি ইউজার তৈরি করা (ইমেইল ভেরিফিকেশন লাগবে না)
  Future<bool> createUserByAdmin({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    bool isPremium = false,
  }) async {
    try {
      // Firebase Auth-এ অ্যাডমিন কর্তৃক ইউজার ক্রিয়েট
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
          isPremium: isPremium,
          isApproved: true,
          createdByAdmin: true, // এটি সত্য হওয়ায় ইমেইল ভেরিফিকেশন ছাড়াই সরাসরি লগইন করতে পারবে
        );

        await _db.upsertUser(newUser);
        return true;
      }
    } catch (e) {
      debugPrint('Admin create user error: $e');
    }
    return false;
  }

  /// Mandatory onboarding: class / job selection (+ optional plan duration).
  Future<void> completeOnboarding({
    required String studyFor, // 'class' | 'job'
    required String studyLevel,
    int intendedPlanMonths = 0,
  }) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      studyFor: studyFor,
      studyLevel: studyLevel,
      intendedPlanMonths: intendedPlanMonths,
    );
    _user = updated;
    await _db.upsertUser(updated);
    notifyListeners();
  }

  /// Profile edits (name / phone / photoUrl).
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    if (_user == null) return;
    final updated =
        _user!.copyWith(name: name, phone: phone, photoUrl: photoUrl);
    _user = updated;
    await _db.upsertUser(updated);
    
    // Keep linked teacher profile in sync if applicable
    final linked =
        _db.teachers.where((t) => t.linkedUserId == updated.uid).firstOrNull;
    if (linked != null) {
      await _db.upsertTeacher(
        linked.copyWith(
          name: updated.name,
          phone: updated.phone,
          photoUrl: updated.photoUrl,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _isGuest = false;
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  AppUser _revertIfExpired(AppUser u) {
    if (u.isPremium && !u.hasActivePremium) {
      return u.copyWith(isPremium: false, subscriptionEndDate: null);
    }
    return u;
  }

  /// Refresh the signed-in profile.
  Future<void> refresh() async {
    if (_user == null) return;
    final fresh = _db.userById(_user!.uid) ?? _user;
    _user = _revertIfExpired(fresh!);
    await _db.upsertUser(_user!);
    notifyListeners();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
