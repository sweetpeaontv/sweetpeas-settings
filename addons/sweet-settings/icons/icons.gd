# icons.gd
# Device-agnostic input icon facade — dispatches by InputEvent type.
extends RefCounted

const ControllerIconMap = preload("uid://g1joegdpp4uw")
const IconPaths = preload("uid://cxwurn6qv7ral")
const InputDeviceTracker = preload("uid://dpnmg6swmq30l")
const KeyboardIconMap = preload("uid://cm47n0nsd8qm5")

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
	return IconPaths.load_texture(path_for_event(event))

static func texture_for_keyboard_device() -> Texture2D:
	return IconPaths.load_texture(IconPaths.join("keyboard-mouse", "keyboard.svg"))

static func texture_for_controller_device(family: String = "") -> Texture2D:
	var texture := ControllerIconMap.texture_for_device(family)
	if texture != null:
		return texture
	return IconPaths.load_texture(IconPaths.join("flairs", "controller_generic.svg"))
#================================================================================#
