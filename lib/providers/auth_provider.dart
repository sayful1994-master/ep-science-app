import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/local_db.dart';

/// E&P Science — authentication + access-control state.
/// Local backend backed by [LocalDb.users]; swap for FirebaseAuth in production.
class AuthProvider extends ChangeNotifier {
  final LocalDb _db = LocalDb.instance;

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

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    await Future.delayed(const Duration(milliseconds: 400));
    final e = email.trim().toLowerCase();

    // Admin credentials (institute admin + primary administrator SAYFUL).
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

    final u = _db.users
        .where((x) => x.email.toLowerCase() == e)
        .firstOrNull;
    if (u != null) {
      if (password.length < 4) {
        _error = 'পাসওয়ার্ড কমপক্ষে ৪ অক্ষর হতে হবে';
        _setBusy(false);
        return false;
      }
      _user = _revertIfExpired(u);
      await _db.upsertUser(_user!);
      _isGuest = false;
      _error = null;
      _setBusy(false);
      return true;
    }
    // Convenience: create a free student account for any valid email.
    if (email.contains('@') && password.length >= 4) {
      final nu = AppUser(
        uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email.trim(),
      );
      await _db.upsertUser(nu);
      _user = nu;
      _isGuest = false;
      _error = null;
      _setBusy(false);
      return true;
    }
    _error = 'সঠিক ইমেইল ও পাসওয়ার্ড দিন (কমপক্ষে ৪ অক্ষর)';
    _setBusy(false);
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    int intendedPlanMonths = 0,
  }) async {
    _setBusy(true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!email.contains('@') || password.length < 4 || name.trim().isEmpty) {
      _error = 'সব তথ্য সঠিকভাবে পূরণ করুন';
      _setBusy(false);
      return false;
    }
    final nu = AppUser(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      intendedPlanMonths: intendedPlanMonths,
    );
    await _db.upsertUser(nu);
    _user = nu;
    _isGuest = false;
    _error = null;
    _setBusy(false);
    return true;
  }

  /// Auto-revert: if the subscription window has passed, drop premium.
  AppUser _revertIfExpired(AppUser u) {
    if (u.isPremium && !u.hasActivePremium) {
      return u.copyWith(isPremium: false, subscriptionEndDate: null);
    }
    return u;
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

  /// Profile edits (name / photo / phone).
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
    // Keep an approved teacher's public listing in sync with the profile —
    // if a teacher uploads/changes a photo, the teacher card shows it too.
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

  Future<void> upgradeToPremium({int days = 30}) async {
    if (_user == null) return;
    final now = DateTime.now();
    final updated = _user!.copyWith(
      isPremium: true,
      premiumActivatedAt: now.toIso8601String(),
      subscriptionEndDate: now.add(Duration(days: days)).toIso8601String(),
    );
    _user = updated;
    await _db.upsertUser(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _isGuest = false;
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  /// Refresh the signed-in profile (used by the admin panel & role changes).
  /// Also applies the premium-expiry auto-revert on every app entry.
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
