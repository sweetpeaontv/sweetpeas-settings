extends HBoxContainer

const IconButton = preload("uid://f3a6m7hpwk6d")
const IconPaths = preload("uid://cxwurn6qv7ral")
const Icons = preload("uid://dhdqwmdcw4n26")
const InputBinding = preload("uid://qv8fn38jaxf6")
const KeybindPairs = preload("uid://0d205b373m3o")

signal value_changed(value: Dictionary)

const _AXIS_DEADZONE: float = 0.5
const _HOLD_CLEAR_SECONDS: float = 0.8

var _pairs: KeybindPairs
var _add_button: IconButton

var _setting_key: String = ""
var _listening_column: String = ""
var _listening_index: int = -1
var _updating: bool = false
var _signals_connected: bool = false
var _disabled: bool = false
var _focus_restore: Control = null
var _hold_button_index: int = -1
var _hold_elapsed: float = 0.0

# INIT
#================================================================================#
func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	_ensure_nodes()
	_connect_signals()
	set_process(false)
	set_process_input(false)
	_pairs.sync()
#================================================================================#

# API
#================================================================================#
func configure(setting: Dictionary) -> void:
	_ensure_nodes()
	_connect_signals()
	_setting_key = str(setting.get("key", ""))
	_pairs.set_setting_key(_setting_key)

func get_value() -> Dictionary:
	_ensure_nodes()
	return _pairs.get_binding()

func set_value(value: Variant) -> void:
	_ensure_nodes()
	_updating = true
	_stop_listening(false, false)
	_pairs.set_binding(value)
	_updating = false

func set_conflicts(conflicts: Dictionary) -> void:
	_ensure_nodes()
	_pairs.set_conflicts(conflicts if conflicts != null else {}, _setting_key)

func set_disabled(disabled: bool) -> void:
	_ensure_nodes()
	_disabled = disabled
	if _add_button != null:
		_add_button.set_disabled(disabled)
	_pairs.set_disabled(disabled)
	modulate.a = 0.45 if disabled else 1.0
#================================================================================#

# INPUT
#================================================================================#
func _input(event: InputEvent) -> void:
	if _listening_column.is_empty() or _listening_index < 0:
		return

	Icons.note_input_event(event)

	if event is InputEventJoypadButton:
		_joypad_button_listener(event as InputEventJoypadButton)
	else:
		_press_bind_listener(event)

func _joypad_button_listener(button: InputEventJoypadButton) -> void:
	if InputBinding.column_for_event(button) != _listening_column:
		return

	if button.is_pressed():
		_start_hold_clear(int(button.button_index))
		get_viewport().set_input_as_handled()
		return

	if int(button.button_index) != _hold_button_index:
		return

	var encoded: Variant = InputBinding.encode_event(button)
	_reset_hold_clear()
	if encoded == null:
		return

	_pairs.set_slot_event(_listening_column, _listening_index, encoded)
	_stop_listening(true)
	get_viewport().set_input_as_handled()

func _press_bind_listener(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if _pairs.is_clear_badge_at(_listening_column, _listening_index, mouse.global_position):
			return

	if not _is_pressed_bind_event(event):
		return

	var column: String = InputBinding.column_for_event(event)
	if column != _listening_column:
		return

	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if absf(motion.axis_value) < _AXIS_DEADZONE:
			return

		var normalized: InputEventJoypadMotion = motion.duplicate() as InputEventJoypadMotion
		normalized.axis_value = signf(motion.axis_value)
		event = normalized

	var encoded: Variant = InputBinding.encode_event(event)
	if encoded == null:
		return

	_pairs.set_slot_event(_listening_column, _listening_index, encoded)
	_stop_listening(true)
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _hold_button_index < 0:
		return

	_hold_elapsed += delta
	if _hold_elapsed < _HOLD_CLEAR_SECONDS:
		return

	var column: String = _listening_column
	var index: int = _listening_index
	_reset_hold_clear()
	_on_clear_pressed(column, index)
#================================================================================#

# SETUP
#================================================================================#
func _ensure_nodes() -> void:
	if _pairs != null:
		return

	_pairs = $Pairs as KeybindPairs
	_add_button = $AddButton as IconButton
	_add_button.custom_minimum_size = Vector2(40, 40)
	_add_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_add_button.set_content_margins(0)
	_add_button.set_icon_size(Vector2(40, 40))
	var plus: Texture2D = IconPaths.load_texture(IconPaths.join("keyboard-mouse", "keyboard_plus.svg"))
	if plus != null:
		_add_button.set_icon(plus)
		_add_button.set_text("")
	else:
		_add_button.set_text("+")
	_add_button.set_tooltip(tr("add_binding"))

func _connect_signals() -> void:
	if _signals_connected:
		return

	_ensure_nodes()
	_add_button.pressed.connect(_on_add_pressed)
	_pairs.slot_pressed.connect(_on_slot_pressed)
	_pairs.clear_pressed.connect(_on_clear_pressed)
	_signals_connected = true
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_add_pressed() -> void:
	if _updating or _disabled:
		return
	if not _listening_column.is_empty():
		_stop_listening(false)
	_pairs.add_row()

func _on_slot_pressed(column: String, index: int) -> void:
	if _updating or _disabled:
		return

	if _listening_column == column and _listening_index == index:
		_stop_listening(false)
		return

	if not _listening_column.is_empty():
		_stop_listening(false)

	_start_listening(column, index)

func _on_clear_pressed(column: String, index: int) -> void:
	if _updating or _disabled:
		return

	if not _pairs.clear_slot(column, index):
		# Nothing to clear — just leave listen mode.
		if _listening_column == column and _listening_index == index:
			_stop_listening(false)
		return

	_stop_listening(false, false)
	# Defer sync so we don't free the badge/slot still inside gui_input.
	call_deferred("_finish_clear")

func _finish_clear() -> void:
	_pairs.sync()
	_emit_value_changed()
#================================================================================#

# LISTENING
#================================================================================#
func _start_listening(column: String, index: int) -> void:
	_listening_column = column
	_listening_index = index
	# Capture in _input before focused Controls consume ui_accept (e.g. controller A).
	_focus_restore = get_viewport().gui_get_focus_owner()
	if _focus_restore != null:
		_focus_restore.release_focus()
	set_process_input(true)
	_pairs.set_listening(column, index)

func _stop_listening(emit_change: bool, restore_focus: bool = true) -> void:
	_reset_hold_clear()
	_listening_column = ""
	_listening_index = -1
	set_process_input(false)
	if restore_focus and _focus_restore != null and is_instance_valid(_focus_restore):
		_focus_restore.grab_focus()
	_focus_restore = null
	_pairs.set_listening("", -1)
	if emit_change:
		_emit_value_changed()

func _emit_value_changed() -> void:
	if not _updating:
		value_changed.emit(get_value())
#================================================================================#

# HELPERS
#================================================================================#
func _start_hold_clear(button_index: int) -> void:
	_hold_button_index = button_index
	_hold_elapsed = 0.0
	set_process(true)

func _reset_hold_clear() -> void:
	_hold_button_index = -1
	_hold_elapsed = 0.0
	set_process(false)

func _is_pressed_bind_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		return key.is_pressed() and not key.is_echo()
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).is_pressed()
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).is_pressed()
	if event is InputEventJoypadMotion:
		return true
	return false
#================================================================================#
