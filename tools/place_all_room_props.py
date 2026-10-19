#!/usr/bin/env python3
"""
Populate all room scenes with the new sliced props from new_assets with refined positions.
"""

import re

def add_nodes_to_tscn(tscn_path: str, new_nodes_str: str):
    with open(tscn_path, "r", encoding="utf-8") as f:
        content = f.read()

    marker = "# --- AUTO NEW_ASSETS PROPS ---"
    if marker in content:
        content = re.sub(rf"{re.escape(marker)}.*", "", content, flags=re.DOTALL)

    content = content.strip() + "\n\n" + marker + "\n" + new_nodes_str.strip() + "\n"

    with open(tscn_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Updated {tscn_path}")

def main():
    # 1. Silas Office
    silas_nodes = """
[node name="Prop_CoatRack" parent="." instance=ExtResource("3_interact")]
position = Vector2(25, 137)
object_id = "silas_coat_rack"
display_name = "Palto Askılığı"
prop_type = "prop"

[node name="Prop_FilingCabinet" parent="." instance=ExtResource("3_interact")]
position = Vector2(48, 137)
object_id = "silas_filing_cabinet"
display_name = "Evrak Dolabı"
prop_type = "prop"

[node name="Prop_Armchair" parent="." instance=ExtResource("3_interact")]
position = Vector2(200, 137)
object_id = "silas_armchair"
display_name = "Deri Koltuk"
prop_type = "armchair"

[node name="Prop_CeilingLamp" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "ceiling_lamp_pendant"
display_name = "Tavan Lambası"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/hub/silas_office.tscn", silas_nodes)

    # 2. Main Hall
    hall_nodes = """
[node name="Prop_GrandfatherClock" parent="." instance=ExtResource("3_interact")]
position = Vector2(58, 137)
object_id = "hall_grandfather_clock"
display_name = "Büyükbaba Saati"
prop_type = "prop"

[node name="Prop_GrandMirror" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 50)
object_id = "hall_grand_mirror"
display_name = "Altın Varaklı Ayna"
prop_type = "wall"

[node name="Prop_CoatRack" parent="." instance=ExtResource("3_interact")]
position = Vector2(195, 137)
object_id = "hall_coat_rack"
display_name = "Palto ve Şapka Askılığı"
prop_type = "prop"

[node name="Prop_UmbrellaStand" parent="." instance=ExtResource("3_interact")]
position = Vector2(208, 137)
object_id = "hall_umbrella_stand"
display_name = "Islak Şemsiyelik"
prop_type = "prop"

[node name="Prop_MarbleBust" parent="." instance=ExtResource("3_interact")]
position = Vector2(255, 137)
object_id = "hall_marble_bust"
display_name = "Kaideli Mermer Büst"
prop_type = "prop"

[node name="Prop_Chandelier" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "chandelier_grand"
display_name = "Büyük Hol Avizesi"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/main_hall.tscn", hall_nodes)

    # 3. Study
    study_nodes = """
[node name="Prop_StudySafe" parent="." instance=ExtResource("3_interact")]
position = Vector2(115, 60)
object_id = "study_safe"
display_name = "Kilitli Duvar Kasası"
prop_type = "wall"

[node name="Prop_StudyPainting" parent="." instance=ExtResource("3_interact")]
position = Vector2(205, 50)
object_id = "landscape_painting"
display_name = "Karanlık Manzara Tablosu"
prop_type = "wall"

[node name="Prop_StudyCabinet" parent="." instance=ExtResource("3_interact")]
position = Vector2(58, 137)
object_id = "study_cabinet"
display_name = "Arka Konsol Dolabı"
prop_type = "prop"

[node name="Prop_StudyChandelier" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "chandelier_small"
display_name = "Kristal Avize"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/study.tscn", study_nodes)

    # 4. Library
    library_nodes = """
[node name="Prop_LibraryLadder" parent="." instance=ExtResource("3_interact")]
position = Vector2(92, 137)
object_id = "library_ladder"
display_name = "Raylı Kitaplık Merdiveni"
prop_type = "prop"

[node name="Prop_LibraryGlobe" parent="." instance=ExtResource("3_interact")]
position = Vector2(145, 137)
object_id = "library_globe"
display_name = "Ayaklı Pirinç Küre"
prop_type = "prop"

[node name="Prop_ReadingDesk" parent="." instance=ExtResource("3_interact")]
position = Vector2(210, 137)
object_id = "library_reading_desk"
display_name = "Büyük Okuma Masası"
prop_type = "desk"

[node name="Prop_LibraryBust" parent="." instance=ExtResource("3_interact")]
position = Vector2(285, 137)
object_id = "library_bust_pedestal"
display_name = "Mermer Kaideli Büst"
prop_type = "prop"

[node name="Prop_LibraryChandelier" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "chandelier_grand"
display_name = "Kütüphane Avizesi"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/library.tscn", library_nodes)

    # 5. Dining Room
    dining_nodes = """
[node name="Prop_DiningCandelabra" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 103)
object_id = "dining_candelabra"
display_name = "Gümüş Şamdan"
prop_type = "lamp"

[node name="Prop_DiningSideboard" parent="." instance=ExtResource("3_interact")]
position = Vector2(70, 137)
object_id = "dining_sideboard"
display_name = "Yemek Büfesi"
prop_type = "prop"

[node name="Prop_DiningChinaCabinet" parent="." instance=ExtResource("3_interact")]
position = Vector2(245, 137)
object_id = "dining_china_cabinet"
display_name = "Porselen Vitrini"
prop_type = "prop"

[node name="Prop_DiningServiceCart" parent="." instance=ExtResource("3_interact")]
position = Vector2(115, 137)
object_id = "dining_service_cart"
display_name = "Servis Arabası"
prop_type = "prop"

[node name="Prop_DiningChandelier" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "chandelier_grand"
display_name = "Yemek Salonu Avizesi"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/dining_room.tscn", dining_nodes)

    # 6. Kitchen
    kitchen_nodes = """
[node name="Prop_KitchenSink" parent="." instance=ExtResource("3_interact")]
position = Vector2(110, 137)
object_id = "kitchen_sink_counter"
display_name = "Evye ve Mutfak Tezgahı"
prop_type = "prop"

[node name="Prop_KitchenMeatBlock" parent="." instance=ExtResource("3_interact")]
position = Vector2(175, 137)
object_id = "kitchen_meat_block"
display_name = "Masif Et Kütüğü"
prop_type = "prop"

[node name="Prop_KitchenShelves" parent="." instance=ExtResource("3_interact")]
position = Vector2(75, 55)
object_id = "kitchen_wall_shelves"
display_name = "Duvar Tencere Rafı"
prop_type = "wall"

[node name="Prop_KitchenPantry" parent="." instance=ExtResource("3_interact")]
position = Vector2(25, 137)
object_id = "kitchen_pantry_cupboard"
display_name = "Kiler Dolabı"
prop_type = "prop"

[node name="Prop_KitchenPotRack" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "kitchen_pot_rack"
display_name = "Tava ve Tencere Askılığı"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/kitchen.tscn", kitchen_nodes)

    # 7. Billiard Room
    billiard_nodes = """
[node name="Prop_BilliardCueRack" parent="." instance=ExtResource("3_interact")]
position = Vector2(65, 137)
object_id = "billiard_cue_rack"
display_name = "İsteka Rafı"
prop_type = "prop"

[node name="Prop_BilliardBarCart" parent="." instance=ExtResource("3_interact")]
position = Vector2(105, 137)
object_id = "billiard_bar_cart"
display_name = "İçki Arabası"
prop_type = "prop"

[node name="Prop_BilliardTrophy" parent="." instance=ExtResource("3_interact")]
position = Vector2(155, 45)
object_id = "billiard_trophy_stag"
display_name = "Geyik Kafası Trofe"
prop_type = "wall"

[node name="Prop_BilliardArmchair" parent="." instance=ExtResource("3_interact")]
position = Vector2(285, 137)
object_id = "billiard_armchair"
display_name = "Kulüp Koltuğu"
prop_type = "armchair"

[node name="Prop_BilliardLamp" parent="." instance=ExtResource("3_interact")]
position = Vector2(155, 10)
object_id = "billiard_lamp"
display_name = "Bilardo Lambası"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/billiard_room.tscn", billiard_nodes)

    # 8. Upper Floor
    upper_nodes = """
[node name="Prop_UpperBed" parent="." instance=ExtResource("3_interact")]
position = Vector2(135, 137)
object_id = "upper_bed_grand"
display_name = "Büyük Kadife Yatak"
prop_type = "prop"

[node name="Prop_UpperNightstand" parent="." instance=ExtResource("3_interact")]
position = Vector2(175, 137)
object_id = "upper_nightstand"
display_name = "Komodin ve Abajur"
prop_type = "lamp"

[node name="Prop_UpperWardrobe" parent="." instance=ExtResource("3_interact")]
position = Vector2(215, 137)
object_id = "upper_wardrobe"
display_name = "Masif Gardırop"
prop_type = "prop"

[node name="Prop_UpperDresser" parent="." instance=ExtResource("3_interact")]
position = Vector2(285, 137)
object_id = "upper_dresser_mirror"
display_name = "Aynalı Tuvalet Masası"
prop_type = "prop"

[node name="Prop_UpperTrunk" parent="." instance=ExtResource("3_interact")]
position = Vector2(60, 137)
object_id = "upper_vintage_trunk"
display_name = "Deri Seyahat Sandığı"
prop_type = "prop"

[node name="Prop_UpperChandelier" parent="." instance=ExtResource("3_interact")]
position = Vector2(160, 10)
object_id = "chandelier_small"
display_name = "Koridor Avizesi"
prop_type = "ceiling"
"""
    add_nodes_to_tscn("scenes/rooms/upper_floor.tscn", upper_nodes)

if __name__ == "__main__":
    main()
