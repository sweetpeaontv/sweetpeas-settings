# data.gd
# Resource subclass representing the full settings schema.
# Handles defaults, serialization, and save/load.
class_name SettingsData
extends Resource

const SAVE_PATH: String = "user://settings.json"

enum Section { GAMEPLAY, GRAPHICS, AUDIO, CONTROLS }

# GAMEPLAY
#================================================================================#
@export var language: String = "en"
@export var sensitivity: float = 1.0
#================================================================================#

# GRAPHICS
#================================================================================#
enum DisplayMode { WINDOWED, BORDERLESS, FULLSCREEN }
@export var display_mode: DisplayMode = DisplayMode.WINDOWED
@export var resolution: Vector2i = Vector2i(1920, 1080)
@export var vsync: bool = false
@export var max_fps: int = 60
#================================================================================#

# AUDIO
#================================================================================#
@export var master_volume: float = 0.1
@export var music_volume: float = 0.1
@export var sfx_volume: float = 0.1
@export var ui_volume: float = 0.1
#================================================================================#

# CONTROLS
#================================================================================#
@export var input_bindings: Dictionary = {}
#================================================================================#

# SAVE/LOAD
#================================================================================#
func _setting_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(prop.name)
	return names

func to_dict() -> Dictionary:
	var dict: Dictionary = {}
	for prop_name in _setting_names():
		dict[prop_name] = _to_json_value(get(prop_name))
	return dict

func from_dict(dict: Dictionary) -> void:
	for prop_name in _setting_names():
		if dict.has(prop_name):
			set(prop_name, _from_json_value(get(prop_name), dict[prop_name]))

static func load_or_create() -> SettingsData:
	var data := SettingsData.new()
	if FileAccess.file_exists(SAVE_PATH):
		var text := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			data.from_dict(parsed)
	return data

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SweetPeas Settings: failed to open '%s' for writing." % SAVE_PATH)
		return
	file.store_string(JSON.stringify(to_dict(), "\t"))
#================================================================================#

# JSON TYPE CONVERSION
#================================================================================#
# JSON only supports null, bool, number, String, Array and Dictionary. Non-native
# types (vectors, etc.) are encoded as dictionaries with named components so the
# file stays clean and human-editable.
func _to_json_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2I, TYPE_VECTOR2:
			return {"x": value.x, "y": value.y}
		TYPE_VECTOR3I, TYPE_VECTOR3:
			return {"x": value.x, "y": value.y, "z": value.z}
		_:
			return value

# Converts a parsed JSON value back into the type of the existing property.
# `current` is the property's present value, used only as a type reference; it is
# also returned unchanged when the stored value is malformed, so a corrupt entry
# falls back to the default instead of crashing.
func _from_json_value(current: Variant, value: Variant) -> Variant:
	match typeof(current):
		TYPE_VECTOR2I:
			if value is Dictionary and value.has("x") and value.has("y"):
				return Vector2i(int(value["x"]), int(value["y"]))
			return current
		TYPE_VECTOR2:
			if value is Dictionary and value.has("x") and value.has("y"):
				return Vector2(value["x"], value["y"])
			return current
		TYPE_VECTOR3I:
			if value is Dictionary and value.has("x") and value.has("y") and value.has("z"):
				return Vector3i(int(value["x"]), int(value["y"]), int(value["z"]))
			return current
		TYPE_VECTOR3:
			if value is Dictionary and value.has("x") and value.has("y") and value.has("z"):
				return Vector3(value["x"], value["y"], value["z"])
			return current
		TYPE_INT:
			return int(value)
	return value
#================================================================================#

# RESET
#================================================================================#
func reset_to_defaults() -> void:
	var defaults := SettingsData.new()
	_copy_from(defaults)

func reset_section(section: Section) -> void:
	var defaults: SettingsData = SettingsData.new()
	match section:
		Section.GAMEPLAY:
			language = defaults.language
			sensitivity = defaults.sensitivity
		Section.GRAPHICS:
			display_mode = defaults.display_mode
			resolution = defaults.resolution
			vsync = defaults.vsync
			max_fps = defaults.max_fps
		Section.AUDIO:
			master_volume = defaults.master_volume
			music_volume = defaults.music_volume
			sfx_volume = defaults.sfx_volume
			ui_volume = defaults.ui_volume
		Section.CONTROLS:
			input_bindings = defaults.input_bindings
#================================================================================#

# HELPERS
#================================================================================#
func _copy_from(other: SettingsData) -> void:
	for prop_name in _setting_names():
		set(prop_name, other.get(prop_name))
#================================================================================#