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
		var family := InputDeviceTracker.resolve_family(
			InputDeviceTracker.family_for_device(e.device)
		)
		return ControllerIconMap.path_for_button(e.button_index, family)
	if event is InputEventJoypadMotion:
		var e := event as InputEventJoypadMotion
		var family := InputDeviceTracker.resolve_family(
			InputDeviceTracker.family_for_device(e.device)
		)
		return ControllerIconMap.path_for_axis(e.axis, e.axis_value, family)
	if event is InputEventKey or event is InputEventMouseButton:
		return KeyboardIconMap.path_for_event(event)
	return ""

static func texture_for_event(event: InputEvent) -> Texture2D:
	return load_texture(path_for_event(event))

static func texture_for_keyboard_device() -> Texture2D:
	return load_texture(join("keyboard-mouse", "keyboard.svg"))

static func texture_for_controller_device(family: String = "") -> Texture2D:
	if family.is_empty():
		family = InputDeviceTracker.current_family()
	else:
		family = InputDeviceTracker.resolve_family(family)

	var file := ""
	match family:
		InputDeviceTracker.FAMILY_PLAYSTATION:
			file = "controller_playstation5.svg"
		InputDeviceTracker.FAMILY_SWITCH:
			file = "controller_switch_pro.svg"
		InputDeviceTracker.FAMILY_STEAM_DECK:
			file = "controller_steamdeck.svg"
		_:
			file = "controller_xboxseries.svg"
			family = InputDeviceTracker.FAMILY_XBOX

	var texture := load_texture(join(family, file))
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
