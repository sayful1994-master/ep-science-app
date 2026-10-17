"""
E&P Science — Academic catalogue schema seeder.

Builds the full NCTB Class 6–12 (Junior / SSC / HSC), Madrasah, Technical and
Job-Preparation taxonomy (re-using `seed_curriculum.build_curriculum`) and then
scaffolds a ready-to-publish *slot* for every leaf subject/paper in three
content collections:

    books             — text books / সহায়ক বই
    question_banks    — MCQ + CQ question banks
    study_resources   — notes, lectures, suggestions, guides

Every slot carries the full taxonomy breadcrumb (class → section → subject →
paper) so the Admin Panel can publish content under the exact NCTB categories.
All writes use deterministic IDs → the script is idempotent (safe to re-run).

Collections written:
    curriculum          (taxonomy — also written by seed_curriculum.py)
    job_preparation     (taxonomy — also written by seed_curriculum.py)
    books
    question_banks
    study_resources
    meta/academic_catalog_schema   (schema descriptor for the admin panel)
    meta/curriculum_summary        (counts)

Local mirror: assets/data/academic_catalog.json
"""
import json
import os
import sys

import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, SCRIPT_DIR)

from seed_curriculum import build_curriculum, sid  # noqa: E402

OUT_JSON = os.path.join(APP_DIR, "assets", "data", "academic_catalog.json")
SERVICE_ACCOUNT = "/opt/flutter/firebase-admin-sdk.json"


def leaves(data):
    """Yield (class, section, subject, paper) tuples for every content leaf.

    `section` and `paper` may be None (junior classes have no sections;
    single-paper subjects have no papers).
    """
    for cls in data["classes"]:
        if cls.get("sections"):
            for sec in cls["sections"]:
                for subj in sec.get("subjects", []):
                    papers = subj.get("papers") or []
                    if papers:
                        for p in papers:
                            yield cls, sec, subj, p
                    else:
                        yield cls, sec, subj, None
        else:
            for subj in cls.get("subjects", []):
                yield cls, None, subj, None

    # Job-preparation categories share the same content pipeline.
    for cat in data.get("job_categories", []):
        for sec in cat.get("sections", []):
            for subj in sec.get("subjects", []):
                yield cat, sec, subj, None


def leaf_id(kind, cls, sec, subj, paper):
    parts = [kind, cls["id"]]
    if sec:
        parts.append(sec.get("stream_key") or sec["id"])
    parts.append(sid("s", subj["name_en"] or subj["name"]))
    if paper:
        parts.append(f"p{paper.get('paper_no', 1)}")
    return "_".join(parts)


def breadcrumb(cls, sec, subj, paper):
    """Full taxonomy reference embedded in every content document."""
    d = {
        "class_id": cls["id"],
        "class_name": cls["name"],
        "class_name_en": cls["name_en"],
        "class_level": cls.get("level", ""),
        "section_id": sec["id"] if sec else "",
        "section_name": sec["name"] if sec else "",
        "section_name_en": sec["name_en"] if sec else "",
        "stream_key": (sec.get("stream_key", "") if sec else ""),
        "subject_id": sid("subj", subj["name_en"] or subj["name"]),
        "subject_name": subj["name"],
        "subject_name_en": subj["name_en"],
        "is_compulsory": bool(subj.get("is_compulsory", False)),
        "paper_id": paper["id"] if paper else "",
        "paper_name": paper["name"] if paper else "",
        "paper_name_en": paper["name_en"] if paper else "",
        "paper_no": paper.get("paper_no", 0) if paper else 0,
    }
    return d


def build_catalog(data):
    books, banks, resources = [], [], []
    for i, (cls, sec, subj, paper) in enumerate(leaves(data)):
        bc = breadcrumb(cls, sec, subj, paper)

        books.append({
            "id": leaf_id("bk", cls, sec, subj, paper),
            **bc,
            "title": f"{subj['name']}" + (f" — {paper['name']}" if paper else ""),
            "title_en": f"{subj['name_en']}" + (f" — {paper['name_en']}" if paper else ""),
            "author": "",
            "publisher": "",
            "edition": "",
            "cover_url": "",
            "pdf_url": "",
            "external_url": "",
            "is_premium": False,
            "status": "draft",           # draft | published
            "order": i,
            "created_at": firestore.SERVER_TIMESTAMP,
        })

        banks.append({
            "id": leaf_id("qb", cls, sec, subj, paper),
            **bc,
            "title": f"{subj['name']} প্রশ্নব্যাংক" + (f" — {paper['name']}" if paper else ""),
            "types": ["mcq", "cq"],       # mcq | cq | board | admission
            "chapters": [],
            "mcq_count": 0,
            "cq_count": 0,
            "is_premium": False,
            "status": "draft",
            "order": i,
            "created_at": firestore.SERVER_TIMESTAMP,
        })

        resources.append({
            "id": leaf_id("sr", cls, sec, subj, paper),
            **bc,
            "title": f"{subj['name']} নোট ও লেকচার" + (f" — {paper['name']}" if paper else ""),
            "resource_type": "note",      # note | lecture | suggestion | guide
            "file_url": "",
            "video_url": "",
            "external_url": "",
            "is_premium": False,
            "status": "draft",
            "order": i,
            "created_at": firestore.SERVER_TIMESTAMP,
        })
    return books, banks, resources


SCHEMA = {
    "version": 1,
    "description": "E&P Science academic catalogue — NCTB Class 6-12 + Job Preparation.",
    "collections": {
        "curriculum": "Taxonomy: classes -> sections(streams) -> subjects -> papers.",
        "job_preparation": "Taxonomy: job categories -> subjects -> topics.",
        "books": {
            "purpose": "Text books / সহায়ক বই, one doc per subject (or paper).",
            "fields": [
                "id", "title", "title_en", "author", "publisher", "edition",
                "cover_url", "pdf_url", "external_url", "is_premium",
                "status(draft|published)", "order",
                "class_id", "class_name", "class_name_en", "class_level",
                "section_id", "section_name", "section_name_en", "stream_key",
                "subject_id", "subject_name", "subject_name_en", "is_compulsory",
                "paper_id", "paper_name", "paper_name_en", "paper_no",
            ],
        },
        "question_banks": {
            "purpose": "MCQ + CQ question banks per subject/paper.",
            "fields": [
                "id", "title", "types[mcq,cq,board,admission]", "chapters",
                "mcq_count", "cq_count", "is_premium", "status(draft|published)",
                "order", "class_id", "section_id", "subject_id", "paper_id",
            ],
        },
        "study_resources": {
            "purpose": "Notes, lectures, suggestions & guides per subject/paper.",
            "fields": [
                "id", "title", "resource_type(note|lecture|suggestion|guide)",
                "file_url", "video_url", "external_url", "is_premium",
                "status(draft|published)", "order", "class_id", "section_id",
                "subject_id", "paper_id",
            ],
        },
    },
}


def _commit_batches(db, collection, docs):
    """Write docs in batches of 400 (Firestore limit is 500)."""
    total = 0
    for start in range(0, len(docs), 400):
        batch = db.batch()
        for d in docs[start:start + 400]:
            batch.set(db.collection(collection).document(d["id"]), d, merge=True)
        batch.commit()
        total += len(docs[start:start + 400])
    return total


def main():
    data = build_curriculum()
    books, banks, resources = build_catalog(data)

    cred = credentials.Certificate(SERVICE_ACCOUNT)
    try:
        firebase_admin.initialize_app(cred)
    except ValueError:
        pass
    db = firestore.client()

    # ── taxonomy (idempotent merge) ──
    for cls in data["classes"]:
        db.collection("curriculum").document(cls["id"]).set(cls, merge=True)
    for cat in data["job_categories"]:
        db.collection("job_preparation").document(cat["id"]).set(cat, merge=True)

    # ── content scaffolds ──
    nb = _commit_batches(db, "books", books)
    nq = _commit_batches(db, "question_banks", banks)
    nr = _commit_batches(db, "study_resources", resources)

    # ── schema + summary metadata ──
    db.collection("meta").document("academic_catalog_schema").set(SCHEMA, merge=True)
    db.collection("meta").document("curriculum_summary").set({
        "classes": [c["id"] for c in data["classes"]],
        "job_categories": [c["id"] for c in data["job_categories"]],
        "class_count": len(data["classes"]),
        "job_count": len(data["job_categories"]),
        "books_slots": nb,
        "question_bank_slots": nq,
        "study_resource_slots": nr,
    }, merge=True)

    # ── local mirror ──
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump({
            "schema": SCHEMA,
            "counts": {
                "classes": len(data["classes"]),
                "job_categories": len(data["job_categories"]),
                "books": nb,
                "question_banks": nq,
                "study_resources": nr,
            },
        }, f, ensure_ascii=False, indent=2)

    print(f"curriculum classes : {len(data['classes'])}")
    print(f"job categories     : {len(data['job_categories'])}")
    print(f"books slots        : {nb}")
    print(f"question_bank slots: {nq}")
    print(f"study_resource slots:{nr}")
    print(f"Local mirror → {OUT_JSON}")


if __name__ == "__main__":
    main()
