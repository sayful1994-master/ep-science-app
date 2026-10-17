"""
Generates lib/data/curriculum_seed.dart from the NCTB + Job-Prep taxonomy in
seed_curriculum.py.

Output: a self-contained Dart source file with the full academic hierarchy
(Class 6–12 with SSC/HSC streams, Madrasah, Technical) and the four job
categories — as Category / SubCategory / Subject (with stream tag) / Chapter
entries the Flutter app can seed straight into LocalDb.

Idempotent — safe to re-run.
"""
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, SCRIPT_DIR)

from seed_curriculum import (  # noqa: E402
    build_curriculum, sid, JUNIOR_COMMON, RELIGIONS,
)

OUT = os.path.join(APP_DIR, "lib", "data", "curriculum_seed.dart")


def ds(text):
    return text.replace("\\", "\\\\").replace("'", "\\'")


def slug(text):
    keep = [c.lower() if c.isalnum() else "_" for c in text]
    s = "".join(keep)
    while "__" in s:
        s = s.replace("__", "_")
    return s.strip("_")


# ── curated chapter lists (keyed by English subject base name) ──────────────
CHAPTERS = {
    "Bangla": ["গদ্য", "পদ্য", "সহপাঠ", "ব্যাকরণ", "নির্মিতি"],
    "English": ["Grammar", "Vocabulary", "Reading Comprehension", "Writing", "Seen & Unseen Passage"],
    "Mathematics": ["বাস্তব সংখ্যা", "সেট ও ফাংশন", "বীজগণিত", "জ্যামিতি", "ত্রিকোণমিতি", "পরিসংখ্যান"],
    "Science": ["জীবজগৎ", "পদার্থ ও শক্তি", "রাসায়নিক বিক্রিয়া", "পৃথিবী ও মহাকাশ", "প্রযুক্তি"],
    "Digital Technology": ["কম্পিউটার পরিচিতি", "ইন্টারনেট", "ডিজিটাল নিরাপত্তা", "প্রোগ্রামিং ধারণা"],
    "History and Social Science": ["প্রাচীন বাংলা", "সামাজিক প্রতিষ্ঠান", "অর্থনীতি", "নাগরিকতা"],
    "Life and Livelihood": ["পেশা পরিচিতি", "কর্মদক্ষতা", "উদ্যোক্তা মনোভাব"],
    "Health Protection": ["শরীর পরিচর্যা", "পুষ্টি", "রোগ প্রতিরোধ", "প্রাথমিক চিকিৎসা"],
    "Art and Culture": ["চারুশিল্প", "সংগীত", "নৃত্য", "সাংস্কৃতিক ঐতিহ্য"],
    "Physics": ["ভৌত রাশি ও পরিমাপ", "গতি", "বল ও নিউটনের সূত্র", "কাজ, শক্তি ও ক্ষমতা", "তরঙ্গ ও শব্দ", "আলো", "বিদ্যুৎ", "আধুনিক পদার্থবিজ্ঞান"],
    "Chemistry": ["পদার্থের অবস্থা", "পরমাণুর গঠন", "পর্যায় সারণি", "রাসায়নিক বন্ধন", "এসিড-ক্ষারক", "ধাতু নিষ্কাশন", "জৈব রসায়ন", "তড়িৎ রসায়ন"],
    "Biology": ["কোষ ও টিস্যু", "জীবনের ধারা", "শ্রেণিবিন্যাস", "উদ্ভিদ শারীরবৃত্ত", "প্রাণী শারীরবৃত্ত", "বংশগতি", "পরিবেশ ও বাস্তুতন্ত্র"],
    "Higher Mathematics": ["ম্যাট্রিক্স ও নির্ণায়ক", "সরলরেখা", "বৃত্ত", "ত্রিকোণমিতি", "অবকলন", "যোগজীকরণ", "জটিল সংখ্যা", "সম্ভাব্যতা"],
    "ICT": ["তথ্য ও যোগাযোগ প্রযুক্তি", "কম্পিউটার নেটওয়ার্ক", "ডেটাবেজ", "সাইবার নিরাপত্তা", "স্প্রেডশিট"],
    "Bangladesh & Global Studies": ["বাংলাদেশের ইতিহাস", "মুক্তিযুদ্ধ", "সংবিধান", "ভূগোল ও পরিবেশ", "বিশ্বসভ্যতা", "আন্তর্জাতিক সংস্থা"],
    "History of Bangladesh & World Civilization": ["প্রাচীন সভ্যতা", "মধ্যযুগ", "ব্রিটিশ শাসন", "মুক্তিযুদ্ধ", "বিশ্বযুদ্ধ"],
    "Geography and Environment": ["ভৌত ভূগোল", "জলবায়ু", "জনসংখ্যা", "পরিবেশ ও দুর্যোগ"],
    "Geography": ["ভৌত ভূগোল", "জলবায়ু পরিবর্তন", "জনসংখ্যা", "প্রাকৃতিক দুর্যোগ"],
    "Economics": ["চাহিদা ও যোগান", "বাজার", "অর্থনৈতিক উন্নয়ন", "ব্যাংক ও অর্থ"],
    "Civics and Citizenship": ["রাষ্ট্র ও নাগরিক", "সংবিধান", "গণতন্ত্র", "মানবাধিকার"],
    "Civics & Good Governance": ["রাষ্ট্র ও নাগরিক", "সুশাসন", "গণতন্ত্র", "মানবাধিকার"],
    "Agricultural Studies": ["কৃষি ও পরিবেশ", "ফসল উৎপাদন", "মৎস্য ও প্রাণিসম্পদ", "কৃষি প্রযুক্তি"],
    "Home Science": ["খাদ্য ও পুষ্টি", "পোশাক ও বস্ত্র", "গৃহ ও পরিবেশ", "পরিবার"],
    "Accounting": ["হিসাবের মূলনীতি", "জাবেদা ও খতিয়ান", "রেওয়ামিল", "অংশীদারি হিসাব", "আর্থিক বিবরণী"],
    "Business Entrepreneurship": ["ব্যবসায় পরিচিতি", "উদ্যোক্তা", "ব্যবসায়িক পরিকল্পনা"],
    "Finance & Banking": ["অর্থের সময়মূল্য", "ব্যাংকিং", "বিমা", "পুঁজিবাজার"],
    "Finance, Banking & Insurance": ["অর্থের সময়মূল্য", "ব্যাংকিং", "বিমা", "পুঁজিবাজার"],
    "Business Organization & Management": ["ব্যবসায় সংগঠন", "ব্যবস্থাপনার নীতি", "উৎপাদন ও বিপণন"],
    "Production Management & Marketing": ["উৎপাদন ব্যবস্থাপনা", "বিপণন", "ব্র্যান্ডিং"],
    "Logic": ["যুক্তির ধারণা", "সিদ্ধান্ত গ্রহণ", "আরোহ ও অনুমান"],
    "Sociology": ["সমাজ ও সংস্কৃতি", "সামাজিক প্রতিষ্ঠান", "সামাজিক পরিবর্তন"],
    "Social Work": ["সমাজকর্মের ধারণা", "সমাজকর্ম পদ্ধতি", "সমাজকল্যাণ"],
    "History of Islam & Culture": ["ইসলামের আবির্ভাব", "খিলাফত", "মুসলিম সংস্কৃতি"],
    "Psychology": ["মনোবিজ্ঞানের ধারণা", "শিখন ও স্মৃতি", "ব্যক্তিত্ব"],
    "Islamic Studies": ["কুরআন ও হাদিস", "ইসলামি অর্থনীতি", "নৈতিকতা"],
    "Islamic Education": ["কুরআন মাজীদ", "হাদিস", "আকাইদ ও ফিকহ", "ইসলামি ইতিহাস"],
    "Hindu Religious Education": ["ধর্মীয় মূল্যবোধ", "আচার-অনুষ্ঠান", "নৈতিক শিক্ষা"],
    "Christian Religious Education": ["বাইবেল পরিচিতি", "নৈতিক শিক্ষা", "গির্জা"],
    "Buddhist Religious Education": ["ত্রিপিটক", "বৌদ্ধ আচার", "নৈতিক শিক্ষা"],
    "Quran & Tajweed": ["তাজভিদ", "সূরা পরিচিতি"],
    "Arabic Language & Literature": ["আরবি ব্যাকরণ", "সাহিত্য", "অনুবাদ"],
}

# Admission-prep subjects (extra, not part of a single class)
ADMISSION_SUBJECTS = [
    ("Physics (Admission)", "bolt"),
    ("Chemistry (Admission)", "science"),
    ("Biology (Admission)", "eco"),
    ("Math (Admission)", "calculate"),
    ("English (Admission)", "language"),
    ("Bangla (Admission)", "translate"),
    ("General Knowledge (Admission)", "public"),
]

ICON_BY_NAME = {
    "Physics": "bolt", "Chemistry": "science", "Biology": "eco",
    "Mathematics": "calculate", "Higher Mathematics": "calculate",
    "English": "language", "Bangla": "translate", "ICT": "science",
}


def icon_for(en):
    return ICON_BY_NAME.get(en, "book")


def chapters_for(en, base_name):
    for key in (en, base_name):
        if key in CHAPTERS:
            return CHAPTERS[key]
    return []


def main():
    data = build_curriculum()
    cats = [
        ("cat_academic", "একাডেমিক স্টাডি", "Academic Study", "school"),
        ("cat_job", "চাকুরি প্রস্তুতি", "Job Preparation", "workspace_premium"),
    ]

    subs = []      # (id, cat, name, stream)
    subjects = []  # (id, subId, name, icon, stream)
    chapters = []  # (id, subjectId, name, order)

    def add_subject(sub_id, cat_id, cls_name, subj, stream):
        en = subj.get("name_en") or subj["name"]
        papers = subj.get("papers") or []
        if papers:
            for p in papers:
                pen = p.get("name_en") or p["name"]
                sidx = f"subj_{slug(sub_id)}_{slug(pen)}"
                if any(s[0] == sidx for s in subjects):
                    continue
                subjects.append((sidx, sub_id, p["name"], icon_for(en), stream))
                _add_chapters(chapters, sidx, en, p["name"])
        else:
            sidx = f"subj_{slug(sub_id)}_{slug(en)}"
            if any(s[0] == sidx for s in subjects):
                return
            subjects.append((sidx, sub_id, subj["name"], icon_for(en), stream))
            _add_chapters(chapters, sidx, en, subj["name"])

    # Junior classes (6–8)
    for cls in data["classes"]:
        if cls["level"] == "Junior Secondary":
            subs.append((cls["id"], "cat_academic", cls["name"], "general"))
            for s in cls["subjects"]:
                add_subject(cls["id"], "cat_academic", cls["name"], s, "general")
        elif cls["level"] in ("SSC", "HSC"):
            for sec in cls["sections"]:
                sub_id = f"{cls['id']}__{sec['stream_key']}"
                name = f"{cls['name']} — {sec['name']}"
                if not any(s[0] == sub_id for s in subs):
                    subs.append((sub_id, "cat_academic", name, sec["stream_key"]))
                for s in sec["subjects"]:
                    add_subject(sub_id, "cat_academic", cls["name"], s, sec["stream_key"])
        elif cls["level"] == "Madrasah":
            sub_id = cls["id"]
            subs.append((sub_id, "cat_academic", cls["name"], "madrasah"))
            for sec in cls["sections"]:
                for s in sec["subjects"]:
                    add_subject(sub_id, "cat_academic", cls["name"], s, sec["stream_key"])
        elif cls["level"] == "Technical":
            sub_id = cls["id"]
            subs.append((sub_id, "cat_academic", cls["name"], "technical"))
            for sec in cls["sections"]:
                for s in sec["subjects"]:
                    add_subject(sub_id, "cat_academic", cls["name"], s, sec["stream_key"])

    # Admission-prep block (kept for the existing sample questions)
    subs.append(("sub_admission", "cat_academic", "এডমিশন / ভর্তি প্রস্তুতি", "general"))
    for name, icon in ADMISSION_SUBJECTS:
        sidx = f"subj_admission_{slug(name)}"
        subjects.append((sidx, "sub_admission", name, icon, "general"))
        _add_chapters(chapters, sidx, name.replace(" (Admission)", ""), name)

    # Job categories
    for cat in data["job_categories"]:
        subs.append((cat["id"], "cat_job", cat["name"], "job"))
        for sec in cat["sections"]:
            for s in sec["subjects"]:
                add_subject(cat["id"], "cat_job", cat["name"], s, "job")

    # ── emit Dart ──
    lines = [
        "// GENERATED FILE — do not edit by hand.",
        "// Regenerate with: python3 scripts/gen_curriculum_dart.py",
        "import '../models/models.dart';",
        "",
        "class CurriculumSeed {",
        "  static final List<Category> categories = [",
    ]
    for cid, name, en, icon in cats:
        lines.append(f"    Category(id: '{cid}', name: '{ds(name)}', nameEn: '{ds(en)}', icon: '{icon}'),")
    lines += ["  ];", "", "  static final List<SubCategory> subCategories = ["]
    for sidx, cat, name, stream in subs:
        lines.append(f"    SubCategory(id: '{sidx}', categoryId: '{cat}', name: '{ds(name)}'),")
    lines += ["  ];", "", "  static final List<Subject> subjects = ["]
    for sidx, sub, name, icon, stream in subjects:
        lines.append(
            f"    Subject(id: '{sidx}', subCategoryId: '{sub}', name: '{ds(name)}', "
            f"icon: '{icon}', stream: '{stream}'),"
        )
    lines += ["  ];", "", "  static final List<Chapter> chapters = ["]
    for cid, sub, name, order in chapters:
        lines.append(
            f"    Chapter(id: '{cid}', subjectId: '{sub}', name: '{ds(name)}', order: {order}),"
        )
    lines += ["  ];", "}", ""]

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"categories : {len(cats)}")
    print(f"subCategories: {len(subs)}")
    print(f"subjects   : {len(subjects)}")
    print(f"chapters   : {len(chapters)}")
    print(f"→ {OUT}")


def _add_chapters(chapters, subj_id, en, base_name):
    names = chapters_for(en, base_name)
    for i, n in enumerate(names):
        chapters.append((f"{subj_id}_ch{i + 1}", subj_id, n, i))


if __name__ == "__main__":
    main()
