#!/usr/bin/env python3
"""Patches the freshly generated android/ folder (run by the CI workflow).

 * adds CAMERA / VIBRATE / INTERNET permissions
 * sets the app label to "QR & Barcode Master"
 * raises minSdk to 23 (required by mobile_scanner / ML Kit)
 * upgrades Kotlin / Android Gradle Plugin / Gradle versions
 * writes the custom launcher icon (tool/make_icons.py)
 * inserts the AdMob APPLICATION_ID meta-data ONLY if env ADMOB_APP_ID is set
"""
import glob
import os
import re
import sys

MANIFEST = "android/app/src/main/AndroidManifest.xml"

KOTLIN_VERSION = "2.1.0"
AGP_VERSION = "8.7.3"
GRADLE_VERSION = "8.9"


def patch_manifest() -> None:
    with open(MANIFEST, encoding="utf-8") as f:
        xml = f.read()

    additions = ""
    for perm in ("CAMERA", "VIBRATE", "INTERNET"):
        name = f"android.permission.{perm}"
        if name not in xml:
            additions += f'    <uses-permission android:name="{name}"/>\n'
    if "android.hardware.camera" not in xml:
        additions += (
            '    <uses-feature android:name="android.hardware.camera" '
            'android:required="false"/>\n'
        )
    if additions:
        xml = xml.replace("<application", additions + "    <application", 1)

    # App name comes from res/values*/strings.xml (English + Arabic).
    xml = re.sub(r'android:label="[^"]*"', 'android:label="@string/app_name"', xml, count=1)

    app_id = os.environ.get("ADMOB_APP_ID", "").strip()
    if app_id and "com.google.android.gms.ads.APPLICATION_ID" not in xml:
        meta = (
            '        <meta-data\n'
            '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            f'            android:value="{app_id}"/>\n'
        )
        xml = xml.replace("</application>", meta + "    </application>", 1)
        print("AdMob application ID inserted into the manifest.")
    elif not app_id:
        print("ADMOB_APP_ID not set -> building without ads.")

    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Manifest patched.")


def patch_min_sdk() -> None:
    files = glob.glob("android/app/build.gradle.kts") + glob.glob("android/app/build.gradle")
    if not files:
        sys.exit("No android/app/build.gradle(.kts) found")
    path = files[0]
    with open(path, encoding="utf-8") as f:
        text = f.read()

    replacement = "minSdk = 23" if path.endswith(".kts") else "minSdkVersion 23"
    new_text, n = re.subn(r"minSdk(?:Version)?\s*=?\s*flutter\.minSdkVersion", replacement, text)
    if n == 0:
        print(f"WARNING: could not find flutter.minSdkVersion in {path}; leaving minSdk unchanged")
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_text)
        print(f"minSdk set to 23 in {path}")


def patch_gradle_versions() -> None:
    # Kotlin + Android Gradle Plugin versions live in settings.gradle(.kts)
    settings = glob.glob("android/settings.gradle.kts") + glob.glob("android/settings.gradle")
    if not settings:
        sys.exit("No android/settings.gradle(.kts) found")
    path = settings[0]
    with open(path, encoding="utf-8") as f:
        text = f.read()

    text, n1 = re.subn(
        r'''(org\.jetbrains\.kotlin\.android["']\s*\)?\s*version\s*["'])[^"']+''',
        r"\g<1>" + KOTLIN_VERSION,
        text,
    )
    text, n2 = re.subn(
        r'''(com\.android\.application["']\s*\)?\s*version\s*["'])[^"']+''',
        r"\g<1>" + AGP_VERSION,
        text,
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"{path}: kotlin updated={n1 > 0}, AGP updated={n2 > 0}")

    # Gradle wrapper
    wrapper = "android/gradle/wrapper/gradle-wrapper.properties"
    with open(wrapper, encoding="utf-8") as f:
        props = f.read()
    props, n3 = re.subn(r"gradle-[0-9.]+-(all|bin)\.zip", f"gradle-{GRADLE_VERSION}-all.zip", props)
    with open(wrapper, "w", encoding="utf-8") as f:
        f.write(props)
    print(f"Gradle wrapper updated={n3 > 0}")


def write_app_names() -> None:
    """Localised launcher name: English by default, Arabic on Arabic devices."""
    names = {
        "values": "QR &amp; Barcode Master",
        "values-ar": "ماسح QR والباركود",
    }
    for folder, name in names.items():
        directory = os.path.join("android", "app", "src", "main", "res", folder)
        os.makedirs(directory, exist_ok=True)
        with open(os.path.join(directory, "strings.xml"), "w", encoding="utf-8") as f:
            f.write(
                '<?xml version="1.0" encoding="utf-8"?>\n'
                f'<resources>\n    <string name="app_name">{name}</string>\n</resources>\n'
            )
    print("Localised app names written (en, ar).")


def patch_icons() -> None:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import make_icons

    make_icons.write_icons(os.path.join("android", "app", "src", "main", "res"))


if __name__ == "__main__":
    patch_manifest()
    patch_min_sdk()
    patch_gradle_versions()
    write_app_names()
    patch_icons()
