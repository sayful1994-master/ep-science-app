"""
E&P Science — NCTB curriculum + Job-Preparation schema builder.

Builds the full hierarchical list of classes, streams/sections, subjects and
papers (Class 6–12, HSC, plus Madrasah/Technical branches and the four Job
Preparation categories) and uploads it to Firestore under the `curriculum`
collection, plus writes a local JSON mirror to assets/data/.

Idempotent: uses deterministic doc IDs, so re-running overwrites cleanly.
"""
import json
import os
import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(SCRIPT_DIR)
OUT_JSON = os.path.join(APP_DIR, "assets", "data", "curriculum.json")
SERVICE_ACCOUNT = "/opt/flutter/firebase-admin-sdk.json"


def sid(prefix, text):
    """Slug-ish deterministic id."""
    keep = [c.lower() if c.isalnum() else "-" for c in text]
    slug = "".join(keep)
    while "--" in slug:
        slug = slug.replace("--", "-")
    return f"{prefix}_{slug.strip('-')}"


def subj(name, en, compulsory=True, papers=None):
    return {
        "name": name,
        "name_en": en,
        "is_compulsory": compulsory,
        "papers": papers or [],
    }


# ─────────────────────────── CLASS 6–8 (Junior Secondary) ───────────────────
JUNIOR_COMMON = [
    ("বাংলা", "Bangla"),
    ("ইংরেজি", "English"),
    ("গণিত", "Mathematics"),
    ("বিজ্ঞান", "Science"),
    ("ডিজিটাল প্রযুক্তি", "Digital Technology"),
    ("ইতিহাস ও সামাজিক বিজ্ঞান", "History and Social Science"),
    ("জীবন ও জীবিকা", "Life and Livelihood"),
    ("স্বাস্থ্য সুরক্ষা", "Health Protection"),
    ("ধর্ম ও নৈতিক শিক্ষা", "Religious & Moral Education"),
    ("শিল্প ও সংস্কৃতি", "Art and Culture"),
]
RELIGIONS = [
    ("ইসলাম শিক্ষা", "Islamic Education"),
    ("হিন্দুধর্ম শিক্ষা", "Hindu Religious Education"),
    ("খ্রিস্টধর্ম শিক্ষা", "Christian Religious Education"),
    ("বৌদ্ধধর্ম শিক্ষা", "Buddhist Religious Education"),
]


def build_junior(cls_id, cls_name, cls_en, order):
    subjects = []
    for name, en in JUNIOR_COMMON:
        if name == "ধর্ম ও নৈতিক শিক্ষা":
            # Religious education expands into 4 elective religions
            for rn, ren in RELIGIONS:
                subjects.append(subj(rn, ren, compulsory=False))
        else:
            subjects.append(subj(name, en, compulsory=True))
    return {
        "id": cls_id,
        "name": cls_name,
        "name_en": cls_en,
        "level": "Junior Secondary",
        "order": order,
        "sections": [],
        "subjects": subjects,
    }


# ─────────────────────────── SSC (Class 9–10) ──────────────────────────────
SSC_STREAMS = {
    "science": {
        "name": "বিজ্ঞান",
        "name_en": "Science",
        "compulsory": [
            ("বাংলা", "Bangla"),
            ("ইংরেজি", "English"),
            ("গণিত", "Mathematics"),
            ("তথ্য ও যোগাযোগ প্রযুক্তি", "ICT"),
            ("বাংলাদেশ ও বিশ্বপরিচয়", "Bangladesh & Global Studies"),
            ("ধর্ম ও নৈতিক শিক্ষা", "Religious & Moral Education"),
        ],
        "group": [
            ("পদার্থবিজ্ঞান", "Physics"),
            ("রসায়ন", "Chemistry"),
            ("জীববিজ্ঞান", "Biology"),
            ("উচ্চতর গণিত", "Higher Mathematics"),
        ],
    },
    "humanities": {
        "name": "মানবিক",
        "name_en": "Humanities",
        "compulsory": [
            ("বাংলা", "Bangla"),
            ("ইংরেজি", "English"),
            ("গণিত", "Mathematics"),
            ("তথ্য ও যোগাযোগ প্রযুক্তি", "ICT"),
            ("বাংলাদেশ ও বিশ্বপরিচয়", "Bangladesh & Global Studies"),
            ("ধর্ম ও নৈতিক শিক্ষা", "Religious & Moral Education"),
        ],
        "group": [
            ("বাংলাদেশের ইতিহাস ও বিশ্বসভ্যতা", "History of Bangladesh & World Civilization"),
            ("ভূগোল ও পরিবেশ", "Geography and Environment"),
            ("অর্থনীতি", "Economics"),
            ("পৌরনীতি ও নাগরিকতা", "Civics and Citizenship"),
            ("কৃষিশিক্ষা", "Agricultural Studies"),
            ("গার্হস্থ্য বিজ্ঞান", "Home Science"),
        ],
    },
    "business": {
        "name": "ব্যবসায় শিক্ষা",
        "name_en": "Business Studies",
        "compulsory": [
            ("বাংলা", "Bangla"),
            ("ইংরেজি", "English"),
            ("গণিত", "Mathematics"),
            ("তথ্য ও যোগাযোগ প্রযুক্তি", "ICT"),
            ("বাংলাদেশ ও বিশ্বপরিচয়", "Bangladesh & Global Studies"),
            ("ধর্ম ও নৈতিক শিক্ষা", "Religious & Moral Education"),
        ],
        "group": [
            ("হিসাববিজ্ঞান", "Accounting"),
            ("ব্যবসায় উদ্যোগ", "Business Entrepreneurship"),
            ("ফিন্যান্স ও ব্যাংকিং", "Finance & Banking"),
            ("কৃষিশিক্ষা", "Agricultural Studies"),
            ("গার্হস্থ্য বিজ্ঞান", "Home Science"),
        ],
    },
}


def build_ssc(cls_id, cls_name, cls_en, order):
    sections = []
    for key, s in SSC_STREAMS.items():
        subjects = [subj(n, e, compulsory=True) for n, e in s["compulsory"]]
        subjects += [subj(n, e, compulsory=False) for n, e in s["group"]]
        sections.append({
            "id": sid("sec", f"{cls_id}-{key}"),
            "name": s["name"],
            "name_en": s["name_en"],
            "stream_key": key,
            "subjects": subjects,
        })
    return {
        "id": cls_id,
        "name": cls_name,
        "name_en": cls_en,
        "level": "SSC",
        "order": order,
        "sections": sections,
        "subjects": [],
    }


# ─────────────────────────── HSC (Class 11–12) ─────────────────────────────
def two_papers(name, en):
    return subj(name, en, papers=[
        {"id": sid("paper", f"{en}-1"), "name": f"{name} ১ম পত্র", "name_en": f"{en} 1st Paper", "paper_no": 1},
        {"id": sid("paper", f"{en}-2"), "name": f"{name} ২য় পত্র", "name_en": f"{en} 2nd Paper", "paper_no": 2},
    ])


HSC_COMMON = [
    ("বাংলা", "Bangla"),
    ("ইংরেজি", "English"),
    ("তথ্য ও যোগাযোগ প্রযুক্তি", "ICT"),
]
HSC_STREAMS = {
    "science": {
        "name": "বিজ্ঞান", "name_en": "Science",
        "group": [
            ("পদার্থবিজ্ঞান", "Physics"),
            ("রসায়ন", "Chemistry"),
            ("জীববিজ্ঞান", "Biology"),
            ("উচ্চতর গণিত", "Higher Mathematics"),
        ],
    },
    "humanities": {
        "name": "মানবিক", "name_en": "Humanities",
        "group": [
            ("পৌরনীতি ও সুশাসন", "Civics & Good Governance"),
            ("অর্থনীতি", "Economics"),
            ("যুক্তিবিদ্যা", "Logic"),
            ("সমাজবিজ্ঞান", "Sociology"),
            ("সমাজকর্ম", "Social Work"),
            ("ভূগোল", "Geography"),
            ("ইসলামের ইতিহাস ও সংস্কৃতি", "History of Islam & Culture"),
            ("মনোবিজ্ঞান", "Psychology"),
            ("ইসলাম শিক্ষা", "Islamic Studies"),
        ],
    },
    "business": {
        "name": "ব্যবসায় শিক্ষা", "name_en": "Business Studies",
        "group": [
            ("হিসাববিজ্ঞান", "Accounting"),
            ("ব্যবসায় সংগঠন ও ব্যবস্থাপনা", "Business Organization & Management"),
            ("ফিন্যান্স, ব্যাংকিং ও বিমা", "Finance, Banking & Insurance"),
            ("উৎপাদন ব্যবস্থাপনা ও বিপণন", "Production Management & Marketing"),
            ("অর্থনীতি", "Economics"),
        ],
    },
}


def build_hsc(cls_id, cls_name, cls_en, order):
    sections = []
    for key, s in HSC_STREAMS.items():
        subjects = [subj(n, e, compulsory=True) for n, e in HSC_COMMON]
        subjects += [two_papers(n, e) for n, e in s["group"]]
        sections.append({
            "id": sid("sec", f"{cls_id}-{key}"),
            "name": s["name"],
            "name_en": s["name_en"],
            "stream_key": key,
            "subjects": subjects,
        })
    return {
        "id": cls_id,
        "name": cls_name,
        "name_en": cls_en,
        "level": "HSC",
        "order": order,
        "sections": sections,
        "subjects": [],
    }


# ─────────────────────────── Madrasah & Technical ──────────────────────────
MADRASAH = {
    "id": "cls_dakhil_alim",
    "name": "মাদ্রাসা (দাখিল ও আলিম)",
    "name_en": "Madrasah (Dakhil & Alim)",
    "level": "Madrasah",
    "order": 13,
    "subjects": [],
    "sections": [
        {
            "id": "sec_dakhil", "name": "দাখিল", "name_en": "Dakhil", "stream_key": "dakhil",
            "subjects": [
                subj("কুরআন মাজীদ ও তাজভিদ", "Quran & Tajweed", compulsory=True),
                subj("আরবি ভাষা ও সাহিত্য", "Arabic Language & Literature", compulsory=True),
                subj("হাদিস ও উসুলুল হাদিস", "Hadith & Usul al-Hadith", compulsory=True),
                subj("আকাইদ ও ফিকহ", "Aqaid & Fiqh", compulsory=True),
                subj("বাংলা", "Bangla", compulsory=True),
                subj("ইংরেজি", "English", compulsory=True),
                subj("গণিত", "Mathematics", compulsory=True),
                subj("বিজ্ঞান", "Science", compulsory=True),
            ],
        },
        {
            "id": "sec_alim", "name": "আলিম", "name_en": "Alim", "stream_key": "alim",
            "subjects": [
                two_papers("কুরআন মাজীদ ও তাজভিদ", "Quran & Tajweed"),
                two_papers("হাদিস ও উসুলুল হাদিস", "Hadith & Usul al-Hadith"),
                two_papers("ফিকহ ও উসুলুল ফিকহ", "Fiqh & Usul al-Fiqh"),
                two_papers("আরবি সাহিত্য", "Arabic Literature"),
                subj("বাংলা", "Bangla", compulsory=True),
                subj("ইংরেজি", "English", compulsory=True),
                subj("তথ্য ও যোগাযোগ প্রযুক্তি", "ICT", compulsory=True),
            ],
        },
    ],
}
TECHNICAL = {
    "id": "cls_vocational",
    "name": "কারিগরি ও ভোকেশনাল",
    "name_en": "Technical & Vocational",
    "level": "Technical",
    "order": 14,
    "subjects": [],
    "sections": [
        {
            "id": "sec_voc_trades", "name": "ট্রেড / ভোকেশনাল", "name_en": "Trade / Vocational",
            "stream_key": "trades",
            "subjects": [
                subj("ইলেকট্রিক্যাল ওয়ার্ক", "Electrical Work", compulsory=False),
                subj("ইলেকট্রনিক্স", "Electronics", compulsory=False),
                subj("মোটর মেকানিক্স", "Motor Mechanics", compulsory=False),
                subj("কম্পিউটার ও আইটি", "Computer & IT", compulsory=False),
                subj("ফিশারিজ", "Fisheries", compulsory=False),
                subj("কৃষি (ভোকেশনাল)", "Agriculture (Vocational)", compulsory=False),
                subj("বিল্ডিং কনস্ট্রাকশন", "Building Construction", compulsory=False),
                subj("আপ্যারেল / টেইলরিং", "Apparel / Tailoring", compulsory=False),
            ],
        },
    ],
}


# ─────────────────────────── Job Preparation ───────────────────────────────
def build_job(cat_id, name, name_en, order, subjects):
    return {
        "id": cat_id,
        "name": name,
        "name_en": name_en,
        "level": "Job Preparation",
        "order": order,
        "subjects": [],
        "sections": [
            {
                "id": sid("sec", f"{cat_id}-main"),
                "name": "বিষয়সমূহ",
                "name_en": "Subjects",
                "stream_key": "job",
                "subjects": [subj(n, e, compulsory=False) for n, e in subjects],
            }
        ],
    }


def build_curriculum():
    classes = [
        build_junior("cls_6", "ষষ্ঠ শ্রেণি", "Class 6", 1),
        build_junior("cls_7", "সপ্তম শ্রেণি", "Class 7", 2),
        build_junior("cls_8", "অষ্টম শ্রেণি", "Class 8", 3),
        build_ssc("cls_9", "নবম শ্রেণি", "Class 9", 4),
        build_ssc("cls_10", "দশম শ্রেণি", "Class 10", 5),
        build_hsc("cls_11", "একাদশ শ্রেণি", "Class 11", 6),
        build_hsc("cls_12", "দ্বাদশ শ্রেণি", "Class 12", 7),
        MADRASAH,
        TECHNICAL,
    ]
    jobs = [
        build_job("job_bcs", "বিসিএস প্রস্তুতি", "BCS Preparation", 20, [
            ("বাংলা ভাষা ও সাহিত্য", "Bangla Language & Literature"),
            ("ইংরেজি ভাষা ও সাহিত্য", "English Language & Literature"),
            ("বাংলাদেশ বিষয়াবলী", "Bangladesh Affairs"),
            ("আন্তর্জাতিক বিষয়াবলী", "International Affairs"),
            ("ভূগোল, পরিবেশ ও দুর্যোগ ব্যবস্থাপনা", "Geography, Environment & Disaster Management"),
            ("সাধারণ বিজ্ঞান", "General Science"),
            ("কম্পিউটার ও তথ্যপ্রযুক্তি", "Computer & Information Technology"),
            ("গাণিতিক যুক্তি", "Mathematical Reasoning"),
            ("মানসিক দক্ষতা", "Mental Ability"),
            ("নৈতিকতা, মূল্যবোধ ও সুশাসন", "Ethics, Values & Good Governance"),
        ]),
        build_job("job_bank", "ব্যাংক চাকরি প্রস্তুতি", "Bank Job Preparation", 21, [
            ("গণিত ও কোয়ান্টিটেটিভ অ্যাপটিটিউড", "Mathematics & Quantitative Aptitude"),
            ("ইংরেজি ও অ্যানালিটিক্যাল রাইটিং", "English & Analytical Writing"),
            ("কম্পিউটার ও আইসিটি", "Computer & ICT Knowledge"),
            ("সাধারণ জ্ঞান ও ব্যাংকিং জ্ঞান", "General Knowledge & Banking Awareness"),
            ("অ্যানালিটিক্যাল মানসিক দক্ষতা", "Analytical Ability & Critical Reasoning"),
        ]),
        build_job("job_primary", "প্রাইমারি শিক্ষক নিয়োগ প্রস্তুতি", "Primary Teacher Recruitment", 22, [
            ("বাংলা", "Bangla"),
            ("ইংরেজি", "English"),
            ("গণিত", "Mathematics"),
            ("সাধারণ জ্ঞান ও সাম্প্রতিক বিষয়াবলী", "General Knowledge & Current Affairs"),
        ]),
        build_job("job_govt", "অন্যান্য সরকারি চাকরি (৯ম–২০তম গ্রেড)", "Other Government Jobs", 23, [
            ("বাংলা ব্যাকরণ ও সাহিত্য", "Bangla Grammar & Literature"),
            ("ইংরেজি ব্যাকরণ ও শব্দভাণ্ডার", "English Grammar & Vocabulary"),
            ("সাধারণ গণিত", "General Mathematics"),
            ("সাধারণ জ্ঞান, তথ্যপ্রযুক্তি ও দৈনন্দিন বিজ্ঞান", "General Knowledge, ICT & Everyday Science"),
        ]),
    ]
    return {"classes": classes, "job_categories": jobs}


def topic_map():
    """Topic lists per subject (for job-prep emphasis)."""
    return {
        "job_bcs": {
            "বাংলা ভাষা ও সাহিত্য": ["ব্যাকরণ", "চিরায়ত সাহিত্য", "আধুনিক সাহিত্য"],
            "ইংরেজি ভাষা ও সাহিত্য": ["Grammar", "Vocabulary", "Comprehension", "Literary History"],
            "বাংলাদেশ বিষয়াবলী": ["ইতিহাস", "মুক্তিযুদ্ধ", "সংবিধান", "অর্থনীতি", "ভূগোল", "সরকারি নীতি"],
            "আন্তর্জাতিক বিষয়াবলী": ["বিশ্ব রাজনীতি", "আন্তর্জাতিক সংস্থা", "চুক্তি", "সাম্প্রতিক বৈশ্বিক ঘটনাপ্রবাহ"],
            "ভূগোল, পরিবেশ ও দুর্যোগ ব্যবস্থাপনা": ["ভৌত ভূগোল", "জলবায়ু পরিবর্তন", "প্রাকৃতিক দুর্যোগ"],
            "সাধারণ বিজ্ঞান": ["ভৌত বিজ্ঞান", "জীব বিজ্ঞান", "ভূ-বিজ্ঞান ও মহাকাশ"],
            "কম্পিউটার ও তথ্যপ্রযুক্তি": ["হার্ডওয়্যার/সফটওয়্যার", "নেটওয়ার্কিং", "সাইবার সিকিউরিটি", "টেক ট্রেন্ড"],
            "গাণিতিক যুক্তি": ["পাটিগণিত", "বীজগণিত", "জ্যামিতি", "পরিসংখ্যান", "মানসিক গণনা"],
            "মানসিক দক্ষতা": ["স্থানিক যুক্তি", "নিগমিত যুক্তি", "সাংখ্যিক দক্ষতা", "মৌখিক যুক্তি"],
            "নৈতিকতা, মূল্যবোধ ও সুশাসন": ["নৈতিকতা", "সুশাসন", "সামাজিক মূল্যবোধ"],
        },
        "job_bank": {
            "গণিত ও কোয়ান্টিটেটিভ অ্যাপটিটিউড": ["পাটিগণিত", "বীজগণিত", "জ্যামিতি", "ডেটা ইন্টারপ্রিটেশন", "শর্টকাট টেকনিক"],
            "ইংরেজি ও অ্যানালিটিক্যাল রাইটিং": ["Grammar", "Analogy", "Sentence Correction", "Vocabulary", "Comprehension"],
            "কম্পিউটার ও আইসিটি": ["ব্যাংকিং সফটওয়্যার", "হার্ডওয়্যার", "নেটওয়ার্ক", "সাইবার সিকিউরিটি", "মৌলিক ধারণা"],
            "সাধারণ জ্ঞান ও ব্যাংকিং জ্ঞান": ["ব্যাংকিং টার্ম", "আর্থিক ব্যবস্থা", "অর্থনীতি", "বাংলাদেশ ও আন্তর্জাতিক বিষয়াবলী"],
            "অ্যানালিটিক্যাল মানসিক দক্ষতা": ["পাজল", "লজিক", "ডেটা সাফিসিয়েন্সি"],
        },
        "job_primary": {
            "বাংলা": ["কারক", "সমাস", "সন্ধি", "বানান", "সংক্ষিপ্ত সাহিত্যকর্ম"],
            "ইংরেজি": ["Parts of Speech", "Tense", "Prepositions", "Translation", "Synonyms/Antonyms"],
            "গণিত": ["শতকরা", "লাভ-ক্ষতি", "সুদকষা", "গড়", "প্রাথমিক বীজগণিত", "প্রাথমিক জ্যামিতি"],
            "সাধারণ জ্ঞান ও সাম্প্রতিক বিষয়াবলী": ["বাংলাদেশের ইতিহাস", "মুক্তিযুদ্ধ", "আইসিটি", "সাধারণ বিজ্ঞান", "বিশ্ব বিষয়াবলী"],
        },
        "job_govt": {
            "বাংলা ব্যাকরণ ও সাহিত্য": ["ব্যাকরণ", "সাহিত্য"],
            "ইংরেজি ব্যাকরণ ও শব্দভাণ্ডার": ["Grammar", "Vocabulary"],
            "সাধারণ গণিত": ["পাটিগণিত", "বীজগণিত", "জ্যামিতি"],
            "সাধারণ জ্ঞান, তথ্যপ্রযুক্তি ও দৈনন্দিন বিজ্ঞান": ["সাধারণ জ্ঞান", "তথ্যপ্রযুক্তি", "দৈনন্দিন বিজ্ঞান"],
        },
    }


def main():
    data = build_curriculum()
    topics = topic_map()

    # attach topics to job subjects
    for cat in data["job_categories"]:
        for sec in cat["sections"]:
            for s in sec["subjects"]:
                s["topics"] = topics.get(cat["id"], {}).get(s["name"], [])

    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Local JSON written → {OUT_JSON}")

    cred = credentials.Certificate(SERVICE_ACCOUNT)
    try:
        firebase_admin.initialize_app(cred)
    except ValueError:
        pass
    db = firestore.client()
    count = 0

    for cls in data["classes"]:
        db.collection("curriculum").document(cls["id"]).set(cls, merge=True)
        count += 1
    for cat in data["job_categories"]:
        db.collection("job_preparation").document(cat["id"]).set(cat, merge=True)
        count += 1

    # summary document
    db.collection("meta").document("curriculum_summary").set({
        "classes": [c["id"] for c in data["classes"]],
        "job_categories": [c["id"] for c in data["job_categories"]],
        "class_count": len(data["classes"]),
        "job_count": len(data["job_categories"]),
    }, merge=True)
    print(f"Uploaded {count} documents to Firestore (curriculum + job_preparation).")


if __name__ == "__main__":
    main()
