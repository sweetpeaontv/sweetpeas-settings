# setting_applier.gd
# Pushes stored setting values into the engine. Built-ins live here;
# games can register extra push-style keys via SettingsManager.
#
# Applier callables take either (value) or (key, value). apply() picks by
# Callable.get_argument_count().
class_name SettingApplier
extends RefCounted

enum DisplayMode {
	WINDOWED,
	BORDERLESS,
	FULLSCREEN,
}

const _VOLUME_BUSES := {
	"master_volume": "Master",
	"music_volume": "Music",
	"sfx_volume": "SFX",
	"ui_volume": "UI",
}

var data: SettingsData
var _appliers: Dictionary = {} # String key -> Callable(value) or Callable(key, value)

func _init() -> void:
	_appliers["language"] = _apply_language
	_appliers["display_mode"] = _apply_display_mode
	_appliers["resolution"] = _apply_resolution
	_appliers["vsync"] = _apply_vsync
	_appliers["max_fps"] = _apply_max_fps
	for key in _VOLUME_BUSES:
		_appliers[key] = _apply_volume

func setup(p_data: SettingsData) -> void:
	data = p_data

# REGISTRY
#================================================================================#
func register(key: String, applier: Callable) -> void:
	_appliers[key] = applier
	if data != null and data.has_key(key):
		apply(key, data.get_value(key))

func unregister(key: String) -> void:
	_appliers.erase(key)

func apply(key: String, value: Variant) -> void:
	if not _appliers.has(key):
		return

	var callable: Callable = _appliers[key]
	if callable.get_argument_count() >= 2:
		callable.call(key, value)
		return

	callable.call(value)

func apply_all() -> void:
	if not data:
		return

	for key in _appliers:
		if data.has_key(key):
			apply(key, data.get_value(key))
#================================================================================#

# LOCALE
#================================================================================#
func _apply_language(value: Variant) -> void:
	if value == null:
		return
	var code := str(value).strip_edges()
	if code.is_empty():
		return
	TranslationServer.set_locale(code)
#================================================================================#

# DISPLAY
#================================================================================#
func _apply_display_mode(value: Variant) -> void:
	var mode := _window_mode_for(value)
	DisplayServer.window_set_mode(mode)

	if mode == DisplayServer.WINDOW_MODE_WINDOWED and data != null:
		_apply_resolution(data.get_value("resolution"))

func _apply_resolution(value: Variant) -> void:
	if data != null and int(data.get_value("display_mode")) != DisplayMode.WINDOWED:
		return

	var size := SettingSources.parse_resolution(str(value))
	if size == Vector2i.ZERO:
		return
	DisplayServer.window_set_size(size)

func _apply_vsync(value: Variant) -> void:
	var mode := (
		DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED
	)
	DisplayServer.window_set_vsync_mode(mode)

func _window_mode_for(value: Variant) -> DisplayServer.WindowMode:
	match int(value):
		DisplayMode.BORDERLESS:
			return DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayMode.FULLSCREEN:
			return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		_:
			return DisplayServer.WINDOW_MODE_WINDOWED
#================================================================================#

# PERFORMANCE
#================================================================================#
func _apply_max_fps(value: Variant) -> void:
	Engine.max_fps = int(value)
#================================================================================#

# AUDIO
#================================================================================#
func _apply_volume(key: String, value: Variant) -> void:
	var bus_name := str(_VOLUME_BUSES[key])
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning(
			"Sweetpea's Settings: audio bus '%s' not found; skipped volume apply." % bus_name
		)
		return

	var linear := clampf(float(value), 0.0, 1.0)
	if linear <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(0.0001))
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear))
#================================================================================#

# CONTROLS
#================================================================================#
func _apply_keybind(key: String, value: Variant) -> void:
	InputBinding.apply_to_action(key, value)
#================================================================================#
