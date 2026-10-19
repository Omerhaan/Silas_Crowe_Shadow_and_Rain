import os
import sys
import urllib.request
import zipfile
import subprocess
import shutil

BASE_DIR = r"C:\Users\omerh\AppData\Local\Android"
SDK_DIR = os.path.join(BASE_DIR, "Sdk")
JDK_DIR = os.path.join(BASE_DIR, "jdk-17")
KEYSTORE_PATH = os.path.join(BASE_DIR, "debug.keystore")

def download_file(url, dest_path):
    print(f"Downloading {url} -> {dest_path}...")
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp, open(dest_path, "wb") as out:
        total = int(resp.headers.get("Content-Length", 0))
        downloaded = 0
        block_size = 1024 * 1024
        while True:
            chunk = resp.read(block_size)
            if not chunk:
                break
            out.write(chunk)
            downloaded += len(chunk)
            if total > 0:
                percent = downloaded / total * 100
                print(f"  {downloaded/1024/1024:.1f}/{total/1024/1024:.1f} MB ({percent:.1f}%)", end="\r")
        print("\nDownload complete.")

def extract_zip(zip_path, extract_to):
    print(f"Extracting {zip_path} -> {extract_to}...")
    os.makedirs(extract_to, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as z:
        z.extractall(extract_to)
    print("Extraction complete.")

def main():
    os.makedirs(BASE_DIR, exist_ok=True)

    # 1. Download & Extract JDK 17
    java_exe = os.path.join(JDK_DIR, "bin", "java.exe")
    keytool_exe = os.path.join(JDK_DIR, "bin", "keytool.exe")
    if not os.path.exists(java_exe):
        jdk_zip = os.path.join(BASE_DIR, "jdk17.zip")
        jdk_url = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"
        download_file(jdk_url, jdk_zip)
        
        tmp_extract = os.path.join(BASE_DIR, "jdk_tmp")
        extract_zip(jdk_zip, tmp_extract)
        # Find root folder in tmp_extract
        subdirs = [os.path.join(tmp_extract, d) for d in os.listdir(tmp_extract) if os.path.isdir(os.path.join(tmp_extract, d))]
        if subdirs:
            if os.path.exists(JDK_DIR):
                shutil.rmtree(JDK_DIR)
            shutil.move(subdirs[0], JDK_DIR)
        shutil.rmtree(tmp_extract, ignore_errors=True)
        if os.path.exists(jdk_zip):
            os.remove(jdk_zip)
    print(f"JDK verified at: {JDK_DIR}")

    # 2. Download & Extract Android Platform Tools (adb)
    adb_exe = os.path.join(SDK_DIR, "platform-tools", "adb.exe")
    if not os.path.exists(adb_exe):
        pt_zip = os.path.join(BASE_DIR, "platform-tools.zip")
        pt_url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
        download_file(pt_url, pt_zip)
        extract_zip(pt_zip, SDK_DIR)
        if os.path.exists(pt_zip):
            os.remove(pt_zip)
    print(f"Platform tools verified at: {os.path.dirname(adb_exe)}")

    # 3. Download & Extract Android Build Tools (zipalign, apksigner)
    bt_dir = os.path.join(SDK_DIR, "build-tools", "33.0.2")
    zipalign_exe = os.path.join(bt_dir, "zipalign.exe")
    if not os.path.exists(zipalign_exe):
        bt_zip = os.path.join(BASE_DIR, "build-tools.zip")
        bt_url = "https://dl.google.com/android/repository/build-tools_r33.0.2-windows.zip"
        download_file(bt_url, bt_zip)
        tmp_bt = os.path.join(BASE_DIR, "bt_tmp")
        extract_zip(bt_zip, tmp_bt)
        subdirs = [os.path.join(tmp_bt, d) for d in os.listdir(tmp_bt) if os.path.isdir(os.path.join(tmp_bt, d))]
        src_dir = subdirs[0] if subdirs else tmp_bt
        os.makedirs(os.path.dirname(bt_dir), exist_ok=True)
        if os.path.exists(bt_dir):
            shutil.rmtree(bt_dir)
        shutil.move(src_dir, bt_dir)
        shutil.rmtree(tmp_bt, ignore_errors=True)
        if os.path.exists(bt_zip):
            os.remove(bt_zip)
    print(f"Build tools verified at: {bt_dir}")

    # 4. Generate debug.keystore
    if not os.path.exists(KEYSTORE_PATH):
        print(f"Generating debug.keystore at {KEYSTORE_PATH}...")
        cmd = [
            keytool_exe,
            "-genkey", "-v",
            "-keystore", KEYSTORE_PATH,
            "-storepass", "android",
            "-alias", "androiddebugkey",
            "-keypass", "android",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Android Debug,O=Android,C=US"
        ]
        subprocess.run(cmd, check=True)
    print(f"Debug keystore verified at: {KEYSTORE_PATH}")

    # 5. Configure Godot editor settings
    appdata = os.environ.get("APPDATA", "")
    godot_dir = os.path.join(appdata, "Godot")
    os.makedirs(godot_dir, exist_ok=True)
    settings_file = os.path.join(godot_dir, "editor_settings-4.tres")
    
    sdk_path_escaped = SDK_DIR.replace("\\", "/")
    jdk_path_escaped = JDK_DIR.replace("\\", "/")
    keystore_path_escaped = KEYSTORE_PATH.replace("\\", "/")

    # Create or update editor settings
    content = f'''[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "{sdk_path_escaped}"
export/android/java_sdk_path = "{jdk_path_escaped}"
export/android/debug_keystore = "{keystore_path_escaped}"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
'''
    with open(settings_file, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Godot editor settings written to: {settings_file}")
    print("Android Build Environment Setup Complete!")

if __name__ == "__main__":
    main()
