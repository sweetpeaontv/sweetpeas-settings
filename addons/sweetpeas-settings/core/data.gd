# data.gd
class_name SettingsData
extends RefCounted

const SAVE_PATH: String = "user://settings.json"

# schema and player selected values are stored separately in order to preserve default values as defaults and not player decisions.
# if instead we stored the data in 1 dict, then any value that a player does not change is treated as their decision
# meaning if the setting changes later, it will not reflect the new default value, but instead a value the player never touched.
var _schema: SettingsSchema
var _overrides: Dictionary = {}

# save i/o runs on WorkerThreadPool
# generation + mutex keep overlapping writes from finishing out of order and trumping a newer snapshot.
var _write_mutex := Mutex.new()
var _save_generation: int = 0
var _pending_task_ids: Array[int] = []

func _init(schema: SettingsSchema) -> void:
	_schema = schema

# VALUES
#================================================================================#
func has_key(key: String) -> bool:
	return _schema.has_key(key)

func get_value(key: String) -> Variant:
	if _overrides.has(key):
		return _overrides[key]
	return _schema.default_for(key)

# returns if value actually changed so UI can reflect that accordingly
func set_value(key: String, value: Variant) -> bool:
	var coerced: Variant = _schema.coerce(key, value)
	var current: Variant = get_value(key)
	if _values_equal(key, coerced, current):
		return false

	if _values_equal(key, coerced, _schema.default_for(key)):
		_overrides.erase(key)
	else:
		_overrides[key] = coerced

	return true

func _values_equal(key: String, a: Variant, b: Variant) -> bool:
	if str(_schema.get_setting(key).get("type", "")) == "keybind":
		return InputBinding.same_binding(a, b)
	return a == b
#================================================================================#

# RESET
#================================================================================#
func reset_section(section_id: String) -> PackedStringArray:
	var changed_keys: PackedStringArray = []
	for setting in _schema.settings_in(section_id):
		if _overrides.erase(setting["key"]):
			changed_keys.append(setting["key"])
	return changed_keys

func reset_all() -> PackedStringArray:
	var changed_keys := PackedStringArray(_overrides.keys())
	_overrides.clear()
	return changed_keys

# Drops a saved resolution that is no longer offered or no longer fits any
# connected display, so the player falls back to the primary-screen default.
func sanitize_resolution() -> bool:
	const RESOLUTION_KEY := "resolution"
	if not _overrides.has(RESOLUTION_KEY) or not _schema.has_key(RESOLUTION_KEY):
		return false

	var value := str(_overrides[RESOLUTION_KEY])
	var setting := _schema.get_setting(RESOLUTION_KEY)
	var in_options := false
	for option in setting.get("options", []):
		if option is Dictionary and str(option.get("value")) == value:
			in_options = true
			break

	if in_options and SettingSources.resolution_fits_screens(value):
		return false

	_overrides.erase(RESOLUTION_KEY)
	return true
#================================================================================#

# SAVE/LOAD
#================================================================================#
static func load_or_create(schema: SettingsSchema) -> SettingsData:
	var data := SettingsData.new(schema)
	if FileAccess.file_exists(SAVE_PATH):
		data._read()
	return data

func save() -> void:
	_drain_completed_saves()

	var snapshot: Dictionary = _overrides.duplicate(true)
	_write_mutex.lock()
	_save_generation += 1
	var generation := _save_generation
	_write_mutex.unlock()

	var task_id := WorkerThreadPool.add_task(
		_write_snapshot.bind(snapshot, generation),
		false,
		"Sweetpea's Settings: save"
	)
	_pending_task_ids.append(task_id)

# Blocks until every queued save has finished. Required on quit so the last
# write is not cut off, and so WorkerThreadPool can reclaim task resources.
func wait_for_saves() -> void:
	for task_id in _pending_task_ids:
		WorkerThreadPool.wait_for_task_completion(task_id)
	_pending_task_ids.clear()

func _drain_completed_saves() -> void:
	var still_pending: Array[int] = []
	for task_id in _pending_task_ids:
		if WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
		else:
			still_pending.append(task_id)
	_pending_task_ids = still_pending

func _write_snapshot(snapshot: Dictionary, generation: int) -> void:
	_write_mutex.lock()
	if generation != _save_generation:
		_write_mutex.unlock()
		return

	# rewrites entire file
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Sweetpea's Settings: failed to open '%s' for writing." % SAVE_PATH)
		_write_mutex.unlock()
		return

	file.store_string(JSON.stringify(snapshot, "\t"))
	_write_mutex.unlock()

# runs once on startup, no need for worker pool
func _read() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		push_error("Sweetpea's Settings: '%s' is unreadable; using defaults." % SAVE_PATH)
		return

	for key in parsed:
		if _schema.has_key(key):
			set_value(key, parsed[key])
#================================================================================#
