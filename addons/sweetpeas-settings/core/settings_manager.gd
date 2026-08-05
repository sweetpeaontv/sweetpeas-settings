# settings_manager.gd
# Autoloaded entry point. This is the only API game code needs to read or write a setting.
# Owns the schema and the player's persisted settings data.
extends Node

signal setting_changed(key: String, value: Variant)

const SAVE_DELAY_SECONDS := 0.5

var schema: SettingsSchema
var data: SettingsData

var _applier: SettingApplier
# pending appliers are used to register appliers that are not ready yet, such as keybinds
var _pending_appliers: Dictionary = {} # String key -> Callable
var _save_timer: Timer
var _dirty := false

# INIT
#================================================================================#
func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY_SECONDS
	_save_timer.timeout.connect(flush)
	add_child(_save_timer)

	SettingsI18n.load_translations()

	schema = SettingsSchema.load_schema()
	data = SettingsData.load_or_create(schema)

	if data.sanitize_resolution():
		_queue_save()

	_applier = SettingApplier.new()
	_applier.setup(data)
	_flush_pending_appliers()
	_register_keybind_appliers()
	_applier.apply_all()
#================================================================================#

# DESTRUCT
#================================================================================#
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		flush(true)
#================================================================================#

# API
#================================================================================#
func get_setting(key: String) -> Variant:
	if not schema.has_key(key):
		push_error(_unknown_key_message(key))
		return null
	return data.get_value(key)

func set_setting(key: String, value: Variant, persist: bool = true) -> void:
	if not schema.has_key(key):
		push_error(_unknown_key_message(key))
		return

	var victims_changed := false
	if str(schema.get_setting(key).get("type", "")) == "keybind":
		victims_changed = _resolve_keybind_conflicts(key, value)

	if not data.set_value(key, value):
		if victims_changed and persist:
			_queue_save()
		return

	var applied: Variant = data.get_value(key)
	_applier.apply(key, applied)
	setting_changed.emit(key, applied)
	if persist:
		_queue_save()

func reset_section(section_id: String) -> void:
	_announce(data.reset_section(section_id))

func reset_all() -> void:
	_announce(data.reset_all())

func register_applier(key: String, callable: Callable) -> void:
	if _applier == null:
		_pending_appliers[key] = callable
		return
	_applier.register(key, callable)

func unregister_applier(key: String) -> void:
	_pending_appliers.erase(key)
	if _applier != null:
		_applier.unregister(key)

func flush(wait: bool = false) -> void:
	_save_timer.stop()
	if _dirty:
		_dirty = false
		data.save()
	if wait:
		data.wait_for_saves()
#================================================================================#

# INTERNAL
#================================================================================#
func _announce(changed_keys: PackedStringArray) -> void:
	for key in changed_keys:
		var value: Variant = data.get_value(key)
		_applier.apply(key, value)
		setting_changed.emit(key, value)

	if not changed_keys.is_empty():
		_queue_save()

func _flush_pending_appliers() -> void:
	for key in _pending_appliers:
		_applier.register(key, _pending_appliers[key])
	_pending_appliers.clear()

func _register_keybind_appliers() -> void:
	for key in schema.keys():
		var setting := schema.get_setting(key)
		if str(setting.get("type", "")) != "keybind":
			continue
		_applier.register(key, _applier._apply_keybind)

# Steal matching events from other keybind settings before binding owner_key.
# Returns true if any victim binding changed.
func _resolve_keybind_conflicts(owner_key: String, value: Variant) -> bool:
	var incoming := InputBinding.coerce(value)
	var events: Array = []
	for column in [InputBinding.KEYBOARD, InputBinding.CONTROLLER]:
		for encoded in incoming[column]:
			events.append(encoded)

	if events.is_empty():
		return false

	var any_changed := false
	for key in schema.keys():
		if key == owner_key:
			continue
		if str(schema.get_setting(key).get("type", "")) != "keybind":
			continue

		var current: Variant = data.get_value(key)
		var cleaned: Variant = current
		var touched := false
		for encoded in events:
			if InputBinding.binding_contains_event(cleaned, encoded):
				cleaned = InputBinding.remove_event(cleaned, encoded)
				touched = true

		if not touched:
			continue
		if not data.set_value(key, cleaned):
			continue

		var applied: Variant = data.get_value(key)
		_applier.apply(key, applied)
		setting_changed.emit(key, applied)
		any_changed = true

	return any_changed

func _queue_save() -> void:
	_dirty = true
	_save_timer.start()

func _unknown_key_message(key: String) -> String:
	var suggestion := schema.suggest_key(key)
	if suggestion.is_empty():
		return "Sweetpea's Settings: no setting named '%s' in '%s'." % [key, schema.source_path]

	return (
		"Sweetpea's Settings: no setting named '%s' in '%s'. Did you mean '%s'?"
		% [key, schema.source_path, suggestion]
	)
#================================================================================#
