# settings_manager.gd
# Autoloaded entry point. This is the only API game code needs to read or write a setting.
# Owns the schema and the player's persisted settings data.
extends Node

signal setting_changed(key: String, value: Variant)

const SAVE_DELAY_SECONDS := 0.5
const LANGUAGE_KEY := "language"

var schema: SettingsSchema
var data: SettingsData

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

	_apply_locale(get_setting(LANGUAGE_KEY))
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
	if key == LANGUAGE_KEY:
		_apply_locale(applied)

	setting_changed.emit(key, applied)
	if persist:
		_queue_save()

func reset_section(section_id: String) -> void:
	_announce(data.reset_section(section_id))

func reset_all() -> void:
	_announce(data.reset_all())

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
		if key == LANGUAGE_KEY:
			_apply_locale(value)
		setting_changed.emit(key, value)

	if not changed_keys.is_empty():
		_queue_save()

func _apply_locale(locale: Variant) -> void:
	if locale == null:
		return
	var code := str(locale).strip_edges()
	if code.is_empty():
		return
	TranslationServer.set_locale(code)

func _queue_save() -> void:
	_dirty = true
	_save_timer.start()

func _unknown_key_message(key: String) -> String:
	var suggestion := schema.suggest_key(key)
	if suggestion.is_empty():
		return "SweetPeas Settings: no setting named '%s' in '%s'." % [key, schema.source_path]

	return (
		"SweetPeas Settings: no setting named '%s' in '%s'. Did you mean '%s'?"
		% [key, schema.source_path, suggestion]
	)
#================================================================================#
