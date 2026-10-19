import os
import sys
import time
import urllib.request

sys.stdout.reconfigure(encoding='utf-8')

DEST_DIR = os.path.abspath("assets/audio/music")
os.makedirs(DEST_DIR, exist_ok=True)

TRACKS = [
    {
        "filename": "bgm_noir_office.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/91/Satie_-_Gnossienne_1.ogg",
        "title": "Erik Satie - Gnossienne No. 1"
    },
    {
        "filename": "bgm_manor_crime.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/d/d0/Moonlight_Sonata.ogg",
        "title": "Beethoven - Moonlight Sonata"
    },
    {
        "filename": "bgm_docks_fog.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/a/a2/Ivan_Ili%C4%87-Chopin_Prelude_Opus_28_n.4.ogg",
        "title": "Chopin - Prelude in E Minor Op. 28 No. 4"
    },
    {
        "filename": "bgm_docks_tavern.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/a/a6/Maple_Leaf_RagQ.ogg",
        "title": "Scott Joplin - Maple Leaf Rag"
    },
    {
        "filename": "bgm_opera_foyer.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/b/be/Clair_de_lune_%28Claude_Debussy%29_Suite_bergamasque.ogg",
        "title": "Debussy - Clair de Lune"
    },
    {
        "filename": "bgm_opera_aria.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/6/66/Emmy_Destinn%2C_Vissi_d%27arte_%28Tosca%29.ogg",
        "title": "Puccini - Tosca: Vissi d'arte"
    },
    {
        "filename": "bgm_opera_roof.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/a/a9/Saint-Saens%2C_Camille_-_Danse_macabre_Opus_40_-_Computer_generated%2C_transcribed_by_MacLeod.ogg",
        "title": "Saint-Saens - Danse Macabre"
    },
    {
        "filename": "bgm_tension_confront.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/e/e1/Tomaso_Giovanni_Albinoni_-_Adagio_in_G_minor_-_Arr_for_alto_saxophone_and_piano_-_David_Hernando_Vitores.ogg",
        "title": "Albinoni - Adagio in G minor (Sax & Piano)"
    },
    {
        "filename": "bgm_ending_credits.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/f/fd/Chopin_Nocturne_Op_9_No_2.ogg",
        "title": "Chopin - Nocturne Op. 9 No. 2"
    }
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Referer': 'https://commons.wikimedia.org/'
}

for i, track in enumerate(TRACKS, 1):
    target_path = os.path.join(DEST_DIR, track["filename"])
    print(f"[{i}/{len(TRACKS)}] Downloading {track['title']} -> {track['filename']}...")
    try:
        req = urllib.request.Request(track["url"], headers=headers)
        with urllib.request.urlopen(req) as resp, open(target_path, "wb") as out_f:
            total_size = int(resp.getheader('Content-Length', 0))
            downloaded = 0
            while True:
                chunk = resp.read(64 * 1024)
                if not chunk:
                    break
                out_f.write(chunk)
                downloaded += len(chunk)
        size_mb = os.path.getsize(target_path) / (1024 * 1024)
        print(f"    ✔ Successfully saved {track['filename']} ({size_mb:.2f} MB)")
        time.sleep(1.0) # Polite delay for Wikimedia servers
    except Exception as e:
        print(f"    ❌ Failed to download {track['filename']}: {e}")

print("\nDownload process completed.")
