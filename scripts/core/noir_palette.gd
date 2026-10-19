class_name NoirPalette
extends RefCounted

## Noir Palette Manager and Helpers (32 colors: 24 base + 8 midtones)

const HEX_CODES: Array[String] = [
	"0b0f1a", "0d1321", "1d2b53", "2a3a6b",
	"3a2e4f", "4b3b5c", "2b2a2f", "5a5560",
	"8a8691", "e6dccb", "f2eadc", "e8c872",
	"c9783a", "8a5a2b", "4a2f1d", "2e1d14",
	"7e2f3a", "a24a4f", "b0302c", "5c6b63",
	"3e4a47", "3f6b4f", "6b8fa3", "a9c4d4",
	"7f9186", "a3b5a8", "b5803f", "f6e3a1",
	"6a4a6e", "9b7a9f", "2f5a6e", "4f8aa0"
]

# Base 24 Semantic color definitions
const SHADOW_DEEP := Color("0b0f1a")
const SHADOW_DARK := Color("0d1321")
const NIGHT_NAVY_DEEP := Color("1d2b53")
const NIGHT_NAVY_MID := Color("2a3a6b")

const DUSK_PURPLE_DARK := Color("3a2e4f")
const DUSK_PURPLE_MID := Color("4b3b5c")
const SLATE_DARK := Color("2b2a2f")
const SLATE_MID := Color("5a5560")

const SLATE_LIGHT := Color("8a8691")
const PAPER_WARM := Color("e6dccb")
const PAPER_LIGHT := Color("f2eadc")
const CANDLE_GOLD := Color("e8c872")

const AMBER_WARM := Color("c9783a")
const WOOD_MEDIUM := Color("8a5a2b")
const WOOD_DARK := Color("4a2f1d")
const WOOD_DEEP := Color("2e1d14")

const CRIMSON_DEEP := Color("7e2f3a")
const CRIMSON_MID := Color("a24a4f")
const ACCENT_RED := Color("b0302c") # Reserved for blood/badge/key single focal accents
const GREEN_SAGE := Color("5c6b63")

const GREEN_DARK := Color("3e4a47")
const GREEN_MOSS := Color("3f6b4f")
const RAIN_BLUE := Color("6b8fa3")
const SKY_MIST := Color("a9c4d4")

# 8 Mid-tones for walls, atmosphere & lighting
const SAGE_MID := Color("7f9186")
const SAGE_LIGHT := Color("a3b5a8")
const AMBER_MID := Color("b5803f")
const CANDLE_CREAM := Color("f6e3a1")
const PLUM_DARK := Color("6a4a6e")
const PLUM_LIGHT := Color("9b7a9f")
const PETROL_DARK := Color("2f5a6e")
const PETROL_MID := Color("4f8aa0")

static var _colors_cache: Array[Color] = []

static func get_palette_colors() -> Array[Color]:
	if _colors_cache.is_empty():
		for h in HEX_CODES:
			_colors_cache.append(Color(h))
	return _colors_cache

static func get_nearest_color(c: Color) -> Color:
	var colors = get_palette_colors()
	var best_dist: float = 999999.0
	var best_col: Color = colors[0]
	for pal in colors:
		# Weighted RGB Euclidean distance (human perception)
		var dr = (c.r - pal.r) * 0.299
		var dg = (c.g - pal.g) * 0.587
		var db = (c.b - pal.b) * 0.114
		var d = dr * dr + dg * dg + db * db
		if d < best_dist:
			best_dist = d
			best_col = pal
	return best_col
