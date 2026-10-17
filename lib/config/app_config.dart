/// E&P Science — runtime configuration.
///
/// Zero-credential demo runs on the built-in local backend. Supply the
/// Firebase Admin SDK JSON (to seed Firestore + set rules) and enable the
/// Email/Password provider to switch to the live cloud backend.
class AppConfig {
  AppConfig._();

  static const String appName = 'E&P Science';
  static const String appTagline = 'Academic & Admission Care';

  // ── Firebase ──────────────────────────────────────────────
  /// Flip to `true` after Firestore rules + Email/Password auth are enabled.
  static const bool useFirebase = false;

  static const String firebaseProjectId = 'e-p-science';
  static const String firebaseApiKey = 'AIzaSyCD11E9qZTY0i8qKVYAFlsoKDvx-eAjUSg';
  static const String firebaseAuthDomain = 'e-p-science.firebaseapp.com';
  static const String firebaseStorageBucket =
      'e-p-science.firebasestorage.app';
  static const String firebaseMessagingSenderId = '1072521588353';
  static const String firebaseAndroidAppId =
      '1:1072521588353:android:9436ee21b80a5b4c13e780';
  static const String firebaseWebAppId =
      '1:1072521588353:web:2a74f89bbf288e2713e780';

  // ── Gemini (Smart Generator / Tutor) ──────────────────────
  /// Pass a PERMANENT key via --dart-define=GEMINI_API_KEY=AIza...
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6LltDxMT3WMquJFcFvNxLNweb8ns8hn2ngyBNaZmfF-Xg',
  );

  static bool get hasGeminiKey => geminiApiKey.trim().isNotEmpty;
  static const String geminiModel = 'gemini-2.5-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── Admin credentials (as specified) ──────────────────────
  static const String adminEmail = 'e&pscience@learning.com';
  static const String adminPassword = 'e&pscience@2026';

  /// Primary administrator — full permissions identical to [adminEmail].
  /// Removing this ID from Firestore (`admin_accounts`) removes admin access.
  static const String primaryAdminId = 'SAYFUL';
  static const String primaryAdminPassword = 'Janina@1996';

  // ── Freemium ──────────────────────────────────────────────
  static const int freeChapterLimit = 2;
  static const double negativeMarking = 0.50;

  // ── Contact / Coaching ────────────────────────────────────
  static const String institute = 'E&P Science';
  static const String instructor = 'Shamim Sir';
  static const String instituteAddress =
      'জাকির হোসেন রোড, লালমাটিয়া, ঢাকা';
  static const String institutePhone = '01627-444526';
  static const String instituteEmail = 'ayatislam5555@gmail.com';
  static const String messenger = 'Shamim Sir - E&P Science';

  static const String facebookPage =
      'https://www.facebook.com/share/19WCFCunHV/';
  static const String facebookGroup =
      'https://www.facebook.com/share/g/18dLn5G2oW/';

  // ── Payment (Bhikash) ─────────────────────────────────────
  static const String paymentNumber = '01627444526';
  static const String paymentAmount = '500';
  static const String whatsapp1 = '8801627444526';
  static const String whatsapp2 = '8801676714139';

  // ── Creator ───────────────────────────────────────────────
  static const String creatorName = 'সাইফুল ইসলাম (Sayful Islam)';
  static const String creatorTitle = 'সিনিয়র এক্সিকিউটিভ – কমার্শিয়াল';
  static const String creatorOrg = 'ইউনুসকো টি অ্যান্ড এ (বিডি) লিঃ';
  static const String creatorWorkplace = 'তেজগাঁও, ঢাকা, বাংলাদেশ';
  static const String creatorPhone = '01676714139';
  static const String creatorEmail = 'sayful.commercial@gmail.com';
  static const String creatorDegree = 'এমবিএ (অ্যাকাউন্টিং)';
  static const String creatorUniversity = 'জাতীয় বিশ্ববিদ্যালয়, বাংলাদেশ';
  static const String creatorPhoto = 'assets/images/creator_sayful.jpg';
  static const String creatorPhotoRemote =
      'https://www.genspark.ai/api/files/s/MV8Umu9q';
  static const String creatorLinkedIn =
      'https://www.linkedin.com/in/sayful-islam-commercial';

  // ── Founder / Lead Instructor (Engr. Md. Rahman) ──────────
  static const String founderName = 'ইঞ্জিনিয়ার শামীম স্যার (Engr. Md. Rahman)';
  static const String founderRole = 'ফাউন্ডার ও পরিচালক — E&P SCIENCE';
  static const String founderDesignation =
      'প্রভাষক (পদার্থবিজ্ঞান ও উচ্চতর গণিত বিশেষজ্ঞ)';
  static const String founderPhoto = 'assets/images/teacher_shamim.jpg';
  static const String founderFacebook = 'https://www.facebook.com/share/1F8vPnvTcv/';
}
