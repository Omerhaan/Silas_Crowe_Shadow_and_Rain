extends Node

## Central Asset Manager for Gölge ve Yağmur
## Provides centralized access to all assets via manifest ID as specified in Section 8.

const MANIFEST_PATH: String = "res://assets/asset_manifest.json"

var manifest: Dictionary = {}
var assets_by_id: Dictionary = {}
var _texture_cache: Dictionary = {}

func _ready() -> void:
	load_manifest()

func load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("[AssetManager] Manifest file not found: " + MANIFEST_PATH)
		return

	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		push_error("[AssetManager] Failed to open manifest: " + MANIFEST_PATH)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[AssetManager] JSON parse error in manifest: " + json.get_error_message())
		return

	if json.data is Dictionary:
		manifest = json.data
		_index_assets()
	else:
		push_error("[AssetManager] Manifest root is not a dictionary.")

func _index_assets() -> void:
	assets_by_id.clear()

	var index_section = func(sec_name: String):
		if manifest.has(sec_name) and manifest[sec_name] is Dictionary:
			for k in manifest[sec_name]:
				var entry = manifest[sec_name][k]
				if entry is Dictionary:
					assets_by_id[k] = entry
					if entry.has("id"):
						assets_by_id[entry["id"]] = entry

	# Index old sections first, then top-level 'assets' so final new_assets entries take precedence
	index_section.call("props")
	index_section.call("characters")
	index_section.call("rooms")
	index_section.call("assets")

func has_asset(asset_id: String) -> bool:
	return assets_by_id.has(asset_id)

func get_asset(asset_id: String) -> Dictionary:
	return assets_by_id.get(asset_id, {})

func get_asset_path(asset_id: String) -> String:
	var asset = get_asset(asset_id)
	if asset.has("path") and asset["path"] != "":
		return asset["path"]
	elif asset.has("texture") and asset["texture"] != "":
		return asset["texture"]
	return ""

func get_status(asset_id: String) -> String:
	var asset = get_asset(asset_id)
	return asset.get("status", "placeholder")

func get_type(asset_id: String) -> String:
	var asset = get_asset(asset_id)
	return asset.get("type", "")

func get_size(asset_id: String) -> Vector2i:
	var asset = get_asset(asset_id)
	var sz = asset.get("size", [0, 0])
	if sz is Array and sz.size() >= 2:
		return Vector2i(int(sz[0]), int(sz[1]))
	return Vector2i.ZERO

func get_texture(asset_id: String) -> Texture2D:
	if _texture_cache.has(asset_id):
		return _texture_cache[asset_id]

	var asset = get_asset(asset_id)
	if asset.is_empty():
		return null

	var path = get_asset_path(asset_id)
	if path == "":
		return null

	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	else:
		var global_path = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(global_path):
			var img = Image.load_from_file(global_path)
			if img:
				tex = ImageTexture.create_from_image(img)

	if tex:
		_texture_cache[asset_id] = tex
	return tex
