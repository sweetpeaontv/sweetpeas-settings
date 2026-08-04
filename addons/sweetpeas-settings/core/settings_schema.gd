# settings_schema.gd
# SettingsSchema is a parsed and normalized instance of the config schema file
class_name SettingsSchema
extends RefCounted

const CONFIG_DIR := "res://addons/sweetpeas-settings/config"
const DEFAULT_SCHEMA_FILE := "default_schema.json"

const KEYS_FIELD := "keys"

var sections: Array[Dictionary] = []
var source_path: String = ""

var _by_key: Dictionary = {}

# LOADING
#================================================================================#
static func load_schema() -> SettingsSchema:
	var schema := SettingsSchema.new()
	schema.source_path = resolve_path()

	if not FileAccess.file_exists(schema.source_path):
		push_error("Sweetpeas Settings: no schema found at '%s'." % schema.source_path)
		return schema

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(schema.source_path))
	if not parsed is Dictionary:
		push_error("Sweetpeas Settings: invalid schema at '%s'." % schema.source_path)
		return schema

	schema._build(parsed)
	SettingSources.apply(schema)
	return schema

static func resolve_path() -> String:
	var default_path := CONFIG_DIR.path_join(DEFAULT_SCHEMA_FILE)
	var custom_paths: PackedStringArray = []

	for file_name in DirAccess.get_files_at(CONFIG_DIR):
		# Exported builds list non-resource files with a .remap suffix.
		var clean_name := file_name.trim_suffix(".remap")
		if clean_name == DEFAULT_SCHEMA_FILE or clean_name.get_extension().to_lower() != "json":
			continue
		custom_paths.append(CONFIG_DIR.path_join(clean_name))

	if custom_paths.is_empty():
		return default_path

	custom_paths.sort()
	if custom_paths.size() > 1:
		push_warning(
			"SweetPeas Settings: found %d custom schemas in '%s'; using '%s'."
			% [custom_paths.size(), CONFIG_DIR, custom_paths[0]]
		)

	return custom_paths[0]
#================================================================================#

# QUERIES
#================================================================================#
func has_key(key: String) -> bool:
	return _by_key.has(key)

func keys() -> Array:
	return _by_key.keys()

func get_setting(key: String) -> Dictionary:
	return _by_key.get(key, {})

func default_for(key: String) -> Variant:
	return _by_key.get(key, {}).get("default")

func settings_in(section_id: String) -> Array[Dictionary]:
	for section in sections:
		if section["id"] == section_id:
			return section["settings"]
	return []

# Values arrive from JSON and from UI controls that only speak float, so they are
# pulled back to the type the schema's default declares.
func coerce(key: String, value: Variant) -> Variant:
	var setting := get_setting(key)
	if setting.is_empty():
		return value

	var default_value: Variant = setting["default"]
	var coerced: Variant = _to_type(value, typeof(default_value))

	# verify the option is valid
	if setting.has("options"):
		return coerced if _is_valid_option(setting, coerced) else default_value

	if coerced is int or coerced is float:
		var number := clampf(
			float(coerced),
			float(setting.get("min", -INF)),
			float(setting.get("max", INF))
		)
		if setting.has("step"):
			number = snappedf(number, float(setting["step"]))
		return _to_type(number, typeof(default_value))

	return coerced

func _to_type(value: Variant, target_type: int) -> Variant:
	if typeof(value) == target_type:
		return value

	match target_type:
		TYPE_BOOL:
			return bool(value)
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return float(value)
		TYPE_STRING:
			return str(value)

	return value

func _is_valid_option(setting: Dictionary, value: Variant) -> bool:
	for option in setting["options"]:
		if option["value"] == value:
			return true
	return false

# Used to turn a mistyped key into an actionable error instead of a silent null.
func suggest_key(key: String) -> String:
	var best_key := ""
	var best_score := 0.0

	for candidate in _by_key:
		var score := key.similarity(candidate)
		if score > best_score:
			best_score = score
			best_key = candidate

	return best_key if best_score >= 0.5 else ""
#================================================================================#

# NORMALIZATION
#================================================================================#
# Everything below validates what an author wrote and fills in the parts that can
# be spelled out for them, so the rest of the addon can assume a complete setting:
# a key, a type, a default, and options that are always {value, label}.
# Setting display text is tr(key) unless an optional label override is set.
# Section labels are humanized from id (my_section -> My Section) unless overridden.
func _build(raw_schema: Dictionary) -> void:
	for raw_section in raw_schema.get("sections", []):
		if not raw_section is Dictionary:
			continue

		var section := _normalize_section(raw_section)
		if not section.is_empty():
			sections.append(section)

func _normalize_section(raw_section: Dictionary) -> Dictionary:
	var id := str(raw_section.get("id", "")).strip_edges()
	if id.is_empty():
		push_error("SweetPeas Settings: a section is missing its 'id'; skipping it.")
		return {}

	var settings: Array[Dictionary] = []
	for raw_entry in raw_section.get("settings", []):
		if not raw_entry is Dictionary:
			continue
		settings.append_array(_normalize_entry(raw_entry, id))

	return {
		"id": id,
		"label": str(raw_section["label"]) if raw_section.has("label") else _humanize_id(id),
		"settings": settings,
	}

# "gameplay" -> "Gameplay", "my_section-name" -> "My Section Name"
func _humanize_id(id: String) -> String:
	var words := id.replace("-", " ").replace("_", " ").split(" ", false)
	for i in words.size():
		words[i] = str(words[i]).capitalize()
	return " ".join(words)

# A settings entry is either one setting ("key") or a batch ("keys"). 
# Batches expand into one resolved setting per item, then disappear from the tree.
func _normalize_entry(raw_entry: Dictionary, section_id: String) -> Array[Dictionary]:
	if raw_entry.has(KEYS_FIELD):
		var shared := raw_entry.duplicate(true)
		shared.erase(KEYS_FIELD)

		var settings: Array[Dictionary] = []
		for item in raw_entry.get(KEYS_FIELD, []):
			var raw_setting: Dictionary = (
				{"key": item} if item is String or item is StringName
				else item if item is Dictionary
				else {}
			)
			if raw_setting.is_empty():
				push_error(
					"SweetPeas Settings: a '%s' item in section '%s' must be a string or object."
					% [KEYS_FIELD, section_id]
				)
				continue
			settings.append_array(_register_setting(raw_setting, shared, section_id))

		return settings

	return _register_setting(raw_entry, {}, section_id)

func _register_setting(
	raw_setting: Dictionary,
	shared: Dictionary,
	section_id: String
) -> Array[Dictionary]:
	var setting := _normalize_setting(raw_setting, shared, section_id)
	if setting.is_empty():
		return []

	if _by_key.has(setting["key"]):
		push_error(
			"SweetPeas Settings: duplicate setting key '%s'; keeping the first one."
			% setting["key"]
		)
		return []

	_by_key[setting["key"]] = setting
	return [setting]

func _normalize_setting(raw_setting: Dictionary, shared: Dictionary, section_id: String) -> Dictionary:
	var setting := shared.duplicate(true)
	setting.merge(raw_setting, true)

	var key := str(setting.get("key", "")).strip_edges()
	if key.is_empty():
		push_error("SweetPeas Settings: a setting in section '%s' has no 'key'." % section_id)
		return {}

	setting["key"] = key
	setting["section"] = section_id

	# Optional override
	if setting.has("label"):
		setting["label"] = str(setting["label"])

	if setting.has("options"):
		setting["options"] = _normalize_options(setting["options"])

	if not setting.has("default"):
		var options: Array = setting.get("options", [])
		if options.is_empty():
			push_error("SweetPeas Settings: setting '%s' has no 'default'; skipping it." % key)
			return {}
		setting["default"] = options[0]["value"]

	setting["type"] = str(setting.get("type", "")).strip_edges()
	if setting["type"].is_empty():
		push_error("SweetPeas Settings: setting '%s' has no 'type'; skipping it." % key)
		return {}

	return setting

# Accepts three spellings and normalizes them to the {value, label} pairs the
# option editor consumes:
#   {"Windowed": 0, "Borderless": 1}      labels mapped to values, in file order
#   ["1920x1080", "1280x720"]             each value doubles as its own label
#   [{"value": 0, "label": "Windowed"}]   the long form, when neither fits
func _normalize_options(raw_options: Variant) -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	if raw_options is Dictionary:
		for label in raw_options:
			options.append({"value": raw_options[label], "label": str(label)})
		return options

	if raw_options is Array:
		for entry in raw_options:
			if entry is Dictionary:
				options.append({
					"value": entry.get("value"),
					"label": str(entry.get("label", str(entry.get("value")))),
				})
			else:
				options.append({"value": entry, "label": str(entry)})

	return options

#================================================================================#
