#!/usr/bin/env python3
"""Patches the freshly generated android/ folder (run by the CI workflow).

 * adds CAMERA / VIBRATE / INTERNET permissions
 * localised launcher name (English / Arabic)
 * compileSdk / targetSdk >= 36 (Google Play requirement) and minSdk >= 23
 * raises (never lowers) Android Gradle Plugin / Gradle / Kotlin versions
 * release signing from android/key.properties (only active when that file exists)
 * optional custom applicationId (env APP_ID)
 * custom launcher icon (tool/make_icons.py)
 * AdMob APPLICATION_ID meta-data ONLY if env ADMOB_APP_ID is set
"""
import glob
import os
import re
import sys

MANIFEST = "android/app/src/main/AndroidManifest.xml"

# Minimums. A version already at or above these is left untouched, so the
# versions chosen by the Flutter template are never downgraded.
TARGET_SDK = 36
COMPILE_SDK = 36
MIN_SDK = 23                 # mobile_scanner / ML Kit
MIN_AGP = "8.13.0"           # supports API 36; needs Gradle >= 8.13 and JDK 17
MIN_GRADLE = "8.13"
MIN_KOTLIN = "2.2.20"        # do NOT move to AGP 9: Flutter does not support it yet


def vtuple(version: str):
    return tuple(int(x) for x in re.findall(r"\d+", version))


def raised(current: str, minimum: str) -> str:
    return minimum if vtuple(current) < vtuple(minimum) else current


def read(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def app_gradle() -> str:
    files = glob.glob("android/app/build.gradle.kts") + glob.glob("android/app/build.gradle")
    if not files:
        sys.exit("No android/app/build.gradle(.kts) found")
    return files[0]


# --------------------------------------------------------------- manifest

def patch_manifest() -> None:
    xml = read(MANIFEST)

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

    write(MANIFEST, xml)
    print("Manifest patched.")


# ------------------------------------------------------------ SDK levels

def patch_sdk_levels() -> None:
    """compileSdk/targetSdk >= 36 and minSdk >= 23, never lowering a higher value."""
    path = app_gradle()
    text = read(path)
    kts = path.endswith(".kts")

    def at_least(expr: str, value: int) -> str:
        return f"maxOf({expr}, {value})" if kts else f"Math.max({expr}, {value})"

    rules = [
        ("compileSdk", "compileSdkVersion", COMPILE_SDK),
        ("targetSdk", "targetSdkVersion", TARGET_SDK),
        ("minSdk", "minSdkVersion", MIN_SDK),
    ]
    for prop, flutter_prop, value in rules:
        pattern = rf"({prop}(?:Version)?\s*=?\s*)flutter\.{flutter_prop}"
        text, n = re.subn(pattern, lambda m: m.group(1) + at_least(f"flutter.{flutter_prop}", value), text)
        print(f"{prop} >= {value}: {'patched' if n else 'WARNING pattern not found'}")
    write(path, text)


# ------------------------------------------------- AGP / Gradle / Kotlin

def patch_gradle_versions() -> None:
    settings = glob.glob("android/settings.gradle.kts") + glob.glob("android/settings.gradle")
    if not settings:
        sys.exit("No android/settings.gradle(.kts) found")
    path = settings[0]
    text = read(path)

    def bump(plugin_regex: str, minimum: str, label: str) -> None:
        nonlocal text
        found = []

        def repl(m):
            found.append(m.group(2))
            return m.group(1) + raised(m.group(2), minimum)

        text = re.sub(
            rf'''({plugin_regex}["']\s*\)?\s*version\s*["'])([^"']+)''', repl, text
        )
        if not found:
            print(f"{label}: not declared in {path} (left as is)")
        else:
            print(f"{label}: {found[0]} -> {raised(found[0], minimum)}")

    bump(r"com\.android\.application", MIN_AGP, "Android Gradle Plugin")
    bump(r"org\.jetbrains\.kotlin\.android", MIN_KOTLIN, "Kotlin")
    write(path, text)

    wrapper = "android/gradle/wrapper/gradle-wrapper.properties"
    props = read(wrapper)
    m = re.search(r"gradle-([0-9.]+)-(all|bin)\.zip", props)
    if m:
        new = raised(m.group(1), MIN_GRADLE)
        props = props.replace(m.group(0), f"gradle-{new}-{m.group(2)}.zip")
        write(wrapper, props)
        print(f"Gradle: {m.group(1)} -> {new}")
    else:
        print("WARNING: Gradle wrapper version not found")


# ----------------------------------------------------------- app id / name

def patch_application_id() -> None:
    app_id = os.environ.get("APP_ID", "").strip()
    if not app_id:
        print("APP_ID not set -> keeping the generated applicationId.")
        return
    if not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+", app_id):
        sys.exit(f"APP_ID '{app_id}' is not a valid Android package name (example: com.yourname.qrmaster)")
    path = app_gradle()
    text = read(path)
    text, n = re.subn(r'(applicationId\s*=?\s*)"[^"]*"', lambda m: f'{m.group(1)}"{app_id}"', text)
    if not n:
        sys.exit("Could not find applicationId in the app Gradle file")
    write(path, text)
    print(f"applicationId set to {app_id}")


def write_app_names() -> None:
    """Localised launcher name: English by default, Arabic on Arabic devices."""
    names = {
        "values": "QR &amp; Barcode Master",
        "values-ar": "ماسح QR والباركود",
    }
    for folder, name in names.items():
        directory = os.path.join("android", "app", "src", "main", "res", folder)
        os.makedirs(directory, exist_ok=True)
        write(
            os.path.join(directory, "strings.xml"),
            '<?xml version="1.0" encoding="utf-8"?>\n'
            f'<resources>\n    <string name="app_name">{name}</string>\n</resources>\n',
        )
    print("Localised app names written (en, ar).")


# --------------------------------------------------------------- signing

SIGNING_HEADER = (
    "val keystoreProperties = Properties()\n"
    'val keystorePropertiesFile = rootProject.file("key.properties")\n'
    "if (keystorePropertiesFile.exists()) {\n"
    "    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }\n"
    "}\n\n"
)

SIGNING_BLOCK = (
    "    signingConfigs {\n"
    '        create("release") {\n'
    "            if (keystorePropertiesFile.exists()) {\n"
    '                keyAlias = keystoreProperties["keyAlias"] as String\n'
    '                keyPassword = keystoreProperties["keyPassword"] as String\n'
    '                storeFile = file(keystoreProperties["storeFile"] as String)\n'
    '                storePassword = keystoreProperties["storePassword"] as String\n'
    "            }\n"
    "        }\n"
    "    }\n\n"
)


def patch_signing() -> None:
    """Sign release builds with android/key.properties when that file exists,
    otherwise fall back to the debug key (so builds still work before the
    upload keystore is created)."""
    path = app_gradle()
    if not path.endswith(".kts"):
        sys.exit("Release signing patch supports build.gradle.kts only")
    text = read(path)
    if "keystoreProperties" in text:
        print("Signing already configured.")
        return

    if "import java.util.Properties" not in text:
        text = "import java.io.FileInputStream\nimport java.util.Properties\n\n" + text

    text, n1 = re.subn(r"^android\s*\{", lambda m: SIGNING_HEADER + "android {", text, count=1, flags=re.M)
    text, n2 = re.subn(r"^(\s*)buildTypes\s*\{", lambda m: SIGNING_BLOCK + m.group(0), text, count=1, flags=re.M)
    text, n3 = re.subn(
        r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
        'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") '
        'else signingConfigs.getByName("debug")',
        text,
    )
    if not (n1 and n2 and n3):
        sys.exit(f"Could not patch release signing (android block={n1}, buildTypes={n2}, signingConfig={n3})")
    write(path, text)
    print("Release signing configured (uses android/key.properties when present).")


# ----------------------------------------------------------------- icons

def patch_icons() -> None:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import make_icons

    make_icons.write_icons(os.path.join("android", "app", "src", "main", "res"))


if __name__ == "__main__":
    patch_manifest()
    patch_sdk_levels()
    patch_gradle_versions()
    patch_application_id()
    patch_signing()
    write_app_names()
    patch_icons()
