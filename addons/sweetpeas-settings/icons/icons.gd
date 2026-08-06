# icons.gd
# Device-agnostic input icon facade — dispatches by InputEvent type.
class_name Icons
extends RefCounted

const ICONS_ROOT = "res://addons/sweetpeas-settings/icons"

# PUBLIC
#================================================================================#
static func note_input_event(event: InputEvent) -> void:
	InputDeviceTracker.note_event(event)

static func path_for_event(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		var e := event as InputEventJoypadButton
		return ControllerIconMap.path_for_button(
			e.button_index, InputDeviceTracker.family_for_device(e.device)
		)
	if event is InputEventJoypadMotion:
		var e := event as InputEventJoypadMotion
		return ControllerIconMap.path_for_axis(
			e.axis, e.axis_value, InputDeviceTracker.family_for_device(e.device)
		)
	if event is InputEventKey or event is InputEventMouseButton:
		return KeyboardIconMap.path_for_event(event)
	return ""

static func texture_for_event(event: InputEvent) -> Texture2D:
	return load_texture(path_for_event(event))

static func texture_for_keyboard_device() -> Texture2D:
	return load_texture(join("keyboard-mouse", "keyboard.svg"))

static func texture_for_controller_device(family: String = "") -> Texture2D:
	var texture := ControllerIconMap.texture_for_device(family)
	if texture != null:
		return texture
	return load_texture(join("flairs", "controller_generic.svg"))

static func join(subdir: String, file: String) -> String:
	if subdir.is_empty() or file.is_empty():
		return ""
	return "%s/%s/%s" % [ICONS_ROOT, subdir, file]

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
#================================================================================#
