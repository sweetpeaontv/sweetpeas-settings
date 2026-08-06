# settings_manager.gd
# Autoloaded entry point. This is the only API game code needs to read or write a setting.
# Owns the schema and the player's persisted settings data.
extends Node

signal setting_changed(key: String, value: Variant)

const SAVE_DELAY_SECONDS := 0.5

var schema: SweetSettingsSchema
var data: SweetSettingsData

var _applier: SweetSettingApplier
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

	SweetSettingsI18n.load_translations()

	schema = SweetSettingsSchema.load_schema()
	data = SweetSettingsData.load_or_create(schema)

	if data.sanitize_resolution():
		_queue_save()

	_applier = SweetSettingApplier.new()
	_applier.setup(data, schema)
	_flush_pending_appliers()
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

	if not data.set_value(key, value):
		return

	var applied: Variant = data.get_value(key)
	_applier.apply(key, applied)
	setting_changed.emit(key, applied)
	if persist:
		_queue_save()

func get_keybind_conflicts() -> Dictionary:
	var owners: Dictionary = {}
	for key in schema.keys():
		if str(schema.get_setting(key).get("type", "")) != "keybind":
			continue
		var binding := SweetInputBinding.coerce(data.get_value(key))
		for column in [SweetInputBinding.KEYBOARD, SweetInputBinding.CONTROLLER]:
			for encoded in binding[column]:
				var fingerprint := SweetInputBinding.event_fingerprint(encoded)
				if fingerprint.is_empty():
					continue
				if not owners.has(fingerprint):
					owners[fingerprint] = []
				var keys: Array = owners[fingerprint]
				if key not in keys:
					keys.append(key)

	var conflicts: Dictionary = {}
	for fingerprint in owners:
		var keys: Array = owners[fingerprint]
		if keys.size() >= 2:
			conflicts[fingerprint] = keys.duplicate()
	return conflicts

func reset_section(section_id: String) -> void:
	_announce(data.reset_section(section_id))

func reset_all() -> void:
	_announce(data.reset_all())

func register_applier(key: String, callable: Callable) -> void:
	if _applier == null:
		_pending_appliers[key] = callable
		return
	_applier.register(key, callable)
	if data.has_key(key):
		_applier.apply(key, data.get_value(key))

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
