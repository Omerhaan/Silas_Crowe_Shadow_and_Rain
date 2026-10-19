import os
import urllib.request
import zipfile
import shutil

def main():
    # 1. Download platform-33 into Sdk/platforms/android-33
    platforms_dir = r"C:\Users\omerh\AppData\Local\Android\Sdk\platforms"
    android33_dir = os.path.join(platforms_dir, "android-33")
    if not os.path.exists(os.path.join(android33_dir, "android.jar")):
        print("Downloading platform-33...")
        os.makedirs(platforms_dir, exist_ok=True)
        zip_path = os.path.join(platforms_dir, "platform-33.zip")
        url = "https://dl.google.com/android/repository/platform-33_r01.zip"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp, open(zip_path, "wb") as out:
            shutil.copyfileobj(resp, out)
        print("Extracting platform-33...")
        with zipfile.ZipFile(zip_path, "r") as z:
            z.extractall(platforms_dir)
        if os.path.exists(zip_path):
            os.remove(zip_path)
    print("android.jar exists:", os.path.exists(os.path.join(android33_dir, "android.jar")))

    # 2. Copy debug.keystore to Godot default path
    src_keystore = r"C:\Users\omerh\AppData\Local\Android\debug.keystore"
    godot_keystore_dir = os.path.expandvars(r"%APPDATA%\Godot\keystores")
    os.makedirs(godot_keystore_dir, exist_ok=True)
    dst_keystore = os.path.join(godot_keystore_dir, "debug.keystore")
    if os.path.exists(src_keystore):
        shutil.copy2(src_keystore, dst_keystore)
        print("Keystore copied to:", dst_keystore)

    # 3. Update editor_settings-4.3.tres
    settings_file = os.path.expandvars(r"%APPDATA%\Godot\editor_settings-4.3.tres")
    with open(settings_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    keystore_slash = dst_keystore.replace("\\", "/")
    for line in lines:
        if line.startswith("export/android/java_sdk_path ="):
            new_lines.append('export/android/java_sdk_path = "C:/Users/omerh/AppData/Local/Android/jdk-17"\n')
        elif line.startswith("export/android/android_sdk_path ="):
            new_lines.append('export/android/android_sdk_path = "C:/Users/omerh/AppData/Local/Android/Sdk"\n')
        elif line.startswith("export/android/debug_keystore ="):
            new_lines.append(f'export/android/debug_keystore = "{keystore_slash}"\n')
        else:
            new_lines.append(line)

    with open(settings_file, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print("Updated editor_settings-4.3.tres successfully!")

if __name__ == "__main__":
    main()
