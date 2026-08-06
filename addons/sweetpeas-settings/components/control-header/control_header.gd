class_name SweetControlHeader
extends MarginContainer

var _keyboard_icon: TextureRect
var _controller_icon: TextureRect
var _last_family: String = ""

func _ready() -> void:
	_ensure_nodes()
	_refresh_icons()
	set_process_input(true)
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _input(event: InputEvent) -> void:
	SweetIcons.note_input_event(event)
	var family := InputDeviceTracker.current_family()
	if family != _last_family:
		_refresh_icons()

func _ensure_nodes() -> void:
	if _keyboard_icon != null:
		return

	_keyboard_icon = $Row/ValueEditorContainer/Columns/KeyboardIcon
	_controller_icon = $Row/ValueEditorContainer/Columns/ControllerIcon

func _refresh_icons() -> void:
	_ensure_nodes()
	_last_family = InputDeviceTracker.current_family()
	_keyboard_icon.texture = SweetIcons.texture_for_keyboard_device()
	_controller_icon.texture = SweetIcons.texture_for_controller_device(_last_family)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	InputDeviceTracker.refresh_connections()
	_refresh_icons()
