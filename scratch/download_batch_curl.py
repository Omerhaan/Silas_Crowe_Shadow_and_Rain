import os
import subprocess
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')

DEST_DIR = os.path.abspath("assets/audio/music")
os.makedirs(DEST_DIR, exist_ok=True)

REMAINING_TRACKS = [
    ("bgm_manor_crime.ogg", "https://upload.wikimedia.org/wikipedia/commons/d/d0/Moonlight_Sonata.ogg", "Beethoven - Moonlight Sonata"),
    ("bgm_docks_fog.ogg", "https://upload.wikimedia.org/wikipedia/commons/a/a2/Ivan_Ili%C4%87-Chopin_Prelude_Opus_28_n.4.ogg", "Chopin - Prelude in E Minor"),
    ("bgm_docks_tavern.ogg", "https://upload.wikimedia.org/wikipedia/commons/a/a6/Maple_Leaf_RagQ.ogg", "Scott Joplin - Maple Leaf Rag"),
    ("bgm_opera_foyer.ogg", "https://upload.wikimedia.org/wikipedia/commons/b/be/Clair_de_lune_%28Claude_Debussy%29_Suite_bergamasque.ogg", "Debussy - Clair de Lune"),
    ("bgm_opera_aria.ogg", "https://upload.wikimedia.org/wikipedia/commons/6/66/Emmy_Destinn%2C_Vissi_d%27arte_%28Tosca%29.ogg", "Puccini - Tosca: Vissi d'arte"),
    ("bgm_opera_roof.ogg", "https://upload.wikimedia.org/wikipedia/commons/a/a9/Saint-Saens%2C_Camille_-_Danse_macabre_Opus_40_-_Computer_generated%2C_transcribed_by_MacLeod.ogg", "Saint-Saens - Danse Macabre"),
    ("bgm_tension_confront.ogg", "https://upload.wikimedia.org/wikipedia/commons/e/e1/Tomaso_Giovanni_Albinoni_-_Adagio_in_G_minor_-_Arr_for_alto_saxophone_and_piano_-_David_Hernando_Vitores.ogg", "Albinoni - Adagio in G minor (Sax & Piano)"),
    ("bgm_ending_credits.ogg", "https://upload.wikimedia.org/wikipedia/commons/f/fd/Chopin_Nocturne_Op_9_No_2.ogg", "Chopin - Nocturne Op. 9 No. 2")
]

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

for idx, (filename, url, title) in enumerate(REMAINING_TRACKS, 1):
    target_path = os.path.join(DEST_DIR, filename)
    print(f"[{idx}/{len(REMAINING_TRACKS)}] Downloading {title} -> {filename}...", flush=True)
    cmd = [
        "curl.exe", "-sS", "-L",
        "-A", UA,
        "-o", target_path,
        url
    ]
    res = subprocess.run(cmd)
    if res.returncode == 0 and os.path.exists(target_path) and os.path.getsize(target_path) > 1000:
        size_mb = os.path.getsize(target_path) / (1024 * 1024)
        print(f"    ✔ Successfully downloaded {filename} ({size_mb:.2f} MB)", flush=True)
    else:
        print(f"    ❌ Download failed for {filename} (code {res.returncode})", flush=True)
    time.sleep(1.0)

print("\nAll downloads finished successfully.", flush=True)
