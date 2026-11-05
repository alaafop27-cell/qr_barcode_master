#!/usr/bin/env python3
"""Patches the freshly generated android/ folder (run by the CI workflow).

 * adds CAMERA / VIBRATE / INTERNET permissions
 * sets the app label to "QR & Barcode Master"
 * raises minSdk to 23 (required by mobile_scanner / ML Kit)
 * inserts the AdMob APPLICATION_ID meta-data ONLY if env ADMOB_APP_ID is set
"""
import glob
import os
import re
import sys

MANIFEST = "android/app/src/main/AndroidManifest.xml"


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

    xml = re.sub(r'android:label="[^"]*"', 'android:label="QR &amp; Barcode Master"', xml, count=1)

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


if __name__ == "__main__":
    patch_manifest()
    patch_min_sdk()
