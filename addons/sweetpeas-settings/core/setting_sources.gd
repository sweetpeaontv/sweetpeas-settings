# setting_sources.gd
# Fills options / defaults from the runtime environment after JSON schema normalize.
class_name SettingSources
extends RefCounted

const OPTIONS_SOURCE := "options_source"
const DEFAULT_SOURCE := "default_source"

const _CURATED: Array[Vector2i] = [
	Vector2i(3840, 2160),
	Vector2i(3440, 1440),
	Vector2i(2560, 1600),
	Vector2i(2560, 1440),
	Vector2i(2560, 1080),
	Vector2i(1920, 1200),
	Vector2i(1920, 1080),
	Vector2i(1680, 1050),
	Vector2i(1600, 900),
	Vector2i(1440, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 800),
	Vector2i(1280, 720),
]
const _FALLBACK_SIZE := Vector2i(1920, 1080)

# APPLY
#================================================================================#
static func apply(schema: SettingsSchema) -> void:
	_inject_section_sources(schema)

	for key in schema.keys():
		_apply_setting(schema.get_setting(key))

	_fill_keybind_defaults(schema)

static func _inject_section_sources(schema: SettingsSchema) -> void:
	for section in schema.sections:
		match str(section.get("settings_source", "")):
			"":
				continue
			"input_map":
				_inject_input_map(schema, section)
			_:
				push_warning(
					"Sweetpea's Settings: unknown settings_source '%s' on section '%s'."
					% [section.get("settings_source"), section.get("id")]
				)

static func _inject_input_map(schema: SettingsSchema, section: Dictionary) -> void:
	var section_id := str(section.get("id", ""))
	var exclude_prefixes: Array = section.get("exclude_prefixes", [])
	var actions: Array = InputMap.get_actions()
	actions.sort()

	for action in actions:
		var name := str(action)
		if _excluded_by_prefix(name, exclude_prefixes):
			continue
		if schema.has_key(name):
			continue

		schema.inject_setting(section_id, {
			"key": name,
			"type": "keybind",
			"default": InputBinding.snapshot_action(action),
			"section": section_id,
		})

static func _excluded_by_prefix(action_name: String, prefixes: Array) -> bool:
	for prefix in prefixes:
		if action_name.begins_with(str(prefix)):
			return true
	return false

static func _fill_keybind_defaults(schema: SettingsSchema) -> void:
	for key in schema.keys():
		var setting := schema.get_setting(key)
		if str(setting.get("type", "")) != "keybind":
			continue

		if InputMap.has_action(key):
			setting["default"] = InputBinding.snapshot_action(StringName(key))

		SettingApplier.register(key, SettingApplier._apply_keybind)

static func _apply_setting(setting: Dictionary) -> void:
	if setting.has(OPTIONS_SOURCE):
		var options := _options_for(str(setting[OPTIONS_SOURCE]))
		if not options.is_empty():
			setting["options"] = options

	if setting.has(DEFAULT_SOURCE):
		var value: Variant = _default_for(str(setting[DEFAULT_SOURCE]), setting)
		if value != null:
			setting["default"] = value

	if not setting.has("options") or not setting.has("default"):
		return
	if _has_option(setting, setting["default"]):
		return

	var options: Array = setting["options"]
	if not options.is_empty():
		setting["default"] = options[0]["value"]

static func _options_for(source: String) -> Array[Dictionary]:
	match source:
		"display_resolutions":
			return _display_resolutions()
		"project_locales":
			return _project_locales()
		_:
			push_warning("Sweetpea's Settings: unknown options_source '%s'." % source)
			return []

static func _default_for(source: String, setting: Dictionary) -> Variant:
	match source:
		"primary_resolution":
			return current_resolution_value()
		"system_locale":
			return _system_locale(setting)
		_:
			push_warning("Sweetpea's Settings: unknown default_source '%s'." % source)
			return null
#================================================================================#

# RESOLUTION
#================================================================================#
static func max_screen_size() -> Vector2i:
	var largest := Vector2i.ZERO
	for i in DisplayServer.get_screen_count():
		var size := DisplayServer.screen_get_size(i)
		if size.x * size.y > largest.x * largest.y:
			largest = size
	return largest if largest != Vector2i.ZERO else _FALLBACK_SIZE

static func current_resolution_value() -> String:
	var size := _screen_size(DisplayServer.window_get_current_screen())
	if size == Vector2i.ZERO:
		size = _screen_size(DisplayServer.get_primary_screen())
	if size == Vector2i.ZERO:
		size = _FALLBACK_SIZE
	return _to_value(size)

static func parse_resolution(value: String) -> Vector2i:
	var parts := value.to_lower().split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(parts[0].to_int(), parts[1].to_int())

static func resolution_fits_screens(value: String) -> bool:
	var size := parse_resolution(value)
	if size == Vector2i.ZERO:
		return false
	var max_size := max_screen_size()
	return size.x <= max_size.x and size.y <= max_size.y

static func _display_resolutions() -> Array[Dictionary]:
	var sizes: Dictionary = {}

	# connected displays
	for i in DisplayServer.get_screen_count():
		_add_size(sizes, DisplayServer.screen_get_size(i))

	# commons resolutions that fit the largest display
	var max_size := max_screen_size()
	for curated in _CURATED:
		if curated.x <= max_size.x and curated.y <= max_size.y:
			_add_size(sizes, curated)

	# default fallback
	if sizes.is_empty():
		_add_size(sizes, _FALLBACK_SIZE)

	var values: Array = sizes.keys()
	values.sort_custom(func(a: String, b: String) -> bool:
		var sa: Vector2i = sizes[a]
		var sb: Vector2i = sizes[b]
		var pa := sa.x * sa.y
		var pb := sb.x * sb.y
		return pa > pb if pa != pb else sa.x > sb.x
	)

	var options: Array[Dictionary] = []
	for value in values:
		options.append({"value": value, "label": value})
	return options

static func _screen_size(screen: int) -> Vector2i:
	if screen < 0 or screen >= DisplayServer.get_screen_count():
		return Vector2i.ZERO
	var size := DisplayServer.screen_get_size(screen)
	return size if size.x > 0 and size.y > 0 else Vector2i.ZERO

static func _add_size(sizes: Dictionary, size: Vector2i) -> void:
	if size.x > 0 and size.y > 0:
		sizes[_to_value(size)] = size

static func _to_value(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]
#================================================================================#

# LOCALES
#================================================================================#
static func _project_locales() -> Array[Dictionary]:
	var locales := TranslationServer.get_loaded_locales()
	if locales.is_empty():
		locales = PackedStringArray(["en"])

	var seen: Dictionary = {}
	var options: Array[Dictionary] = []
	for locale in locales:
		var code := str(locale)
		if code.is_empty() or seen.has(code):
			continue
		seen[code] = true
		options.append({
			"value": code,
			"label": TranslationServer.get_locale_name(code),
		})

	if options.is_empty():
		options.append({"value": "en", "label": "English"})
	return options

static func _system_locale(setting: Dictionary) -> Variant:
	var available: Array = []
	for option in setting.get("options", []):
		if option is Dictionary:
			available.append(option.get("value"))

	if available.is_empty():
		return "en"

	var system := OS.get_locale()
	if available.has(system):
		return system

	var language := OS.get_locale_language()
	if available.has(language):
		return language

	for value in available:
		if str(value).begins_with(language):
			return value

	return "en" if available.has("en") else available[0]
#================================================================================#

# INTERNAL
#================================================================================#
static func _has_option(setting: Dictionary, value: Variant) -> bool:
	for option in setting.get("options", []):
		if option is Dictionary and option.get("value") == value:
			return true
	return false
#================================================================================#
