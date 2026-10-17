"""
E&P Science — admin accounts + subscription plans + feature toggles seeder.

Creates the app-owner admin ("SAYFUL") and seeds the dynamic subscription
plans and feature toggles in Firestore. Idempotent (merge writes).

⚠️ Removing an admin account: delete its doc from the `admin_accounts`
collection in Firestore → the app no longer recognises that ID as admin.
Add a new admin doc the same way and it works as an admin immediately.
"""
import json
import os
import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT = "/opt/flutter/firebase-admin-sdk.json"

ADMIN_ACCOUNTS = [
    {
        "login_id": "e&pscience@learning.com",
        "email": "e&pscience@learning.com",
        "password": "e&pscience@2026",
        "name": "E&P Science Admin",
        "role": "admin",
        "permissions": "all",
        "is_primary": False,
    },
    {
        "login_id": "SAYFUL",
        "email": "SAYFUL",
        "password": "Janina@1996",
        "name": "Sayful Islam",
        "role": "admin",
        "permissions": "all",
        "is_primary": True,
    },
]

# Dynamic subscription plans — admin can edit prices anytime from Firestore.
# Six durations: 1 / 2 / 3 / 6 / 9 / 12 months → 30 / 60 / 90 / 180 / 270 / 365 days.
SUBSCRIPTION_PLANS = [
    {"id": "plan_1m", "months": 1, "price": 500, "label_bn": "১ মাস", "label_en": "1 Month", "days": 30, "is_active": True},
    {"id": "plan_2m", "months": 2, "price": 900, "label_bn": "২ মাস", "label_en": "2 Months", "days": 60, "is_active": True},
    {"id": "plan_3m", "months": 3, "price": 1200, "label_bn": "৩ মাস", "label_en": "3 Months", "days": 90, "is_active": True},
    {"id": "plan_6m", "months": 6, "price": 2200, "label_bn": "৬ মাস", "label_en": "6 Months", "days": 180, "is_active": True},
    {"id": "plan_9m", "months": 9, "price": 3000, "label_bn": "৯ মাস", "label_en": "9 Months", "days": 270, "is_active": True},
    {"id": "plan_12m", "months": 12, "price": 3800, "label_bn": "১ বছর", "label_en": "1 Year", "days": 365, "is_active": True},
]

APP_SETTINGS = {
    "features": {
        "smart_generator_enabled": True,   # admin can deactivate → hides AI everywhere
        "video_classes_enabled": True,
        "ebooks_enabled": True,
        "announcements_enabled": True,
    },
    "payment": {
        "bkash_number": "01627444526",
        "whatsapp1": "8801627444526",
        "whatsapp2": "8801676714139",
    },
}


def main():
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    try:
        firebase_admin.initialize_app(cred)
    except ValueError:
        pass
    db = firestore.client()

    for acc in ADMIN_ACCOUNTS:
        db.collection("admin_accounts").document(acc["login_id"]).set(acc, merge=True)
        # mirror a user profile doc with role=admin so rules grant full access
        db.collection("users").document(f"admin_{acc['login_id']}").set({
            "uid": f"admin_{acc['login_id']}",
            "name": acc["name"],
            "email": acc["email"],
            "role": "admin",
            "is_premium": True,
            "is_approved": True,
            "can_download_pdf": True,
        }, merge=True)
    print(f"Seeded {len(ADMIN_ACCOUNTS)} admin accounts.")

    for p in SUBSCRIPTION_PLANS:
        db.collection("subscription_plans").document(p["id"]).set(p, merge=True)
    print(f"Seeded {len(SUBSCRIPTION_PLANS)} subscription plans.")

    db.collection("app_settings").document("global").set(APP_SETTINGS, merge=True)
    print("Seeded app_settings.global feature toggles + payment config.")

    # write local mirror
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "data", "admin_config.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({
            "admin_accounts": ADMIN_ACCOUNTS,
            "subscription_plans": SUBSCRIPTION_PLANS,
            "app_settings": APP_SETTINGS,
        }, f, ensure_ascii=False, indent=2)
    print(f"Local mirror → {out}")


if __name__ == "__main__":
    main()
