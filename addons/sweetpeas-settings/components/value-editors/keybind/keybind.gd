class_name KeybindEditor
extends HBoxContainer

signal value_changed(value: Dictionary)

const _AXIS_DEADZONE := 0.5
const _UNBOUND_TEXT := "—"

var _keyboard_button: Button
var _keyboard_icon: TextureRect
var _keyboard_label: Label
var _controller_button: Button
var _controller_icon: TextureRect
var _controller_label: Label

var _binding: Dictionary = InputBinding.empty_binding()
var _listening_column: String = ""
var _updating := false
var _signals_connected := false

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	_ensure_nodes()
	_connect_signals()
	set_process_unhandled_input(false)

func configure(_setting: Dictionary) -> void:
	_ensure_nodes()
	_connect_signals()

func get_value() -> Dictionary:
	return InputBinding.coerce(_binding)

func set_value(value: Variant) -> void:
	_ensure_nodes()
	_updating = true
	_binding = InputBinding.coerce(value)
	_listening_column = ""
	set_process_unhandled_input(false)
	_refresh_slots()
	_updating = false

func _unhandled_input(event: InputEvent) -> void:
	if _listening_column.is_empty():
		return

	Icons.note_input_event(event)

	if _is_cancel_event(event):
		_stop_listening(false)
		get_viewport().set_input_as_handled()
		return

	if not _is_pressed_bind_event(event):
		return

	var column := _column_for_event(event)
	if column != _listening_column:
		return

	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if absf(motion.axis_value) < _AXIS_DEADZONE:
			return
		
		var normalized := motion.duplicate() as InputEventJoypadMotion
		normalized.axis_value = signf(motion.axis_value)
		event = normalized

	var encoded: Variant = InputBinding.encode_event(event)
	if encoded == null:
		return

	_binding[_listening_column] = [encoded]
	_stop_listening(true)
	get_viewport().set_input_as_handled()

func _ensure_nodes() -> void:
	if _keyboard_button != null:
		return

	_keyboard_button = $KeyboardSlot
	_keyboard_icon = $KeyboardSlot/Margin/Content/Icon
	_keyboard_label = $KeyboardSlot/Margin/Content/Label
	_controller_button = $ControllerSlot
	_controller_icon = $ControllerSlot/Margin/Content/Icon
	_controller_label = $ControllerSlot/Margin/Content/Label

func _connect_signals() -> void:
	if _signals_connected:
		return

	_keyboard_button.pressed.connect(_on_slot_pressed.bind(InputBinding.KEYBOARD))
	_controller_button.pressed.connect(_on_slot_pressed.bind(InputBinding.CONTROLLER))
	_signals_connected = true

func _on_slot_pressed(column: String) -> void:
	if _updating:
		return

	if _listening_column == column:
		_stop_listening(false)
		return

	if not _listening_column.is_empty():
		_stop_listening(false)

	_start_listening(column)

func _start_listening(column: String) -> void:
	_listening_column = column
	set_process_unhandled_input(true)
	_refresh_slots()

func _stop_listening(emit_change: bool) -> void:
	_listening_column = ""
	set_process_unhandled_input(false)
	_refresh_slots()
	if emit_change and not _updating:
		value_changed.emit(get_value())

func _refresh_slots() -> void:
	_refresh_slot(
		InputBinding.KEYBOARD,
		_keyboard_icon,
		_keyboard_label,
	)
	_refresh_slot(
		InputBinding.CONTROLLER,
		_controller_icon,
		_controller_label,
	)

func _refresh_slot(column: String, icon: TextureRect, label: Label) -> void:
	if _listening_column == column:
		icon.texture = _waiting_texture()
		icon.visible = icon.texture != null
		label.visible = not icon.visible
		label.text = "..."
		return

	var column_events: Array = _binding.get(column, [])
	if column_events.is_empty():
		icon.texture = null
		icon.visible = false
		label.visible = true
		label.text = _UNBOUND_TEXT
		return

	var event := InputBinding.decode_event(column_events[0])
	var texture := Icons.texture_for_event(event) if event else null
	if texture != null:
		icon.texture = texture
		icon.visible = true
		label.visible = false
		label.text = ""
		return

	icon.texture = null
	icon.visible = false
	label.visible = true
	label.text = _fallback_label(event)

func _waiting_texture() -> Texture2D:
	return Icons.load_texture(Icons.join("keyboard-mouse", "keyboard_any.svg"))

func _is_cancel_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		return (event as InputEventKey).keycode == KEY_ESCAPE
	return false

func _is_pressed_bind_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.is_pressed() and not key.is_echo()
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).is_pressed()
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).is_pressed()
	if event is InputEventJoypadMotion:
		return true
	return false

func _column_for_event(event: InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton:
		return InputBinding.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return InputBinding.CONTROLLER
	return ""

func _fallback_label(event: InputEvent) -> String:
	if event == null:
		return _UNBOUND_TEXT
	if event is InputEventKey:
		var key := event as InputEventKey
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		var text := OS.get_keycode_string(code)
		return text if not text.is_empty() else _UNBOUND_TEXT
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MOUSE_BUTTON_WHEEL_UP:
				return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel Down"
			MOUSE_BUTTON_XBUTTON1:
				return "Mouse 4"
			MOUSE_BUTTON_XBUTTON2:
				return "Mouse 5"
			_:
				return "Mouse"
	if event is InputEventJoypadButton:
		return "Btn %d" % (event as InputEventJoypadButton).button_index
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return "Axis %d" % motion.axis
	return _UNBOUND_TEXT
