# input_device_tracker.gd
# tracks last used input kind and family.
class_name InputDeviceTracker
extends RefCounted

const KIND_KEYBOARD := "keyboard"
const KIND_CONTROLLER := "controller"

const FAMILY_GENERIC = "generic"
const FAMILY_XBOX = "xbox-series"
const FAMILY_PLAYSTATION = "playstation-series"
const FAMILY_SWITCH = "nintendo-switch"
const FAMILY_SWITCH_2 = "nintendo-switch-2"
const FAMILY_STEAM_DECK = "steam-deck"
const FAMILY_STEAM_CONTROLLER = "steam-controller"

const _NAME_HINTS = [
	[["steam deck", "steamdeck"], FAMILY_STEAM_DECK],
	[["steam controller"], FAMILY_STEAM_CONTROLLER],
	[["dualsense", "dualshock", "playstation", "ps5", "ps4", "ps3"], FAMILY_PLAYSTATION],
	[["switch 2"], FAMILY_SWITCH_2],
	[["switch", "joy-con", "joycon", "pro controller"], FAMILY_SWITCH],
	[["xbox", "xinput", "microsoft"], FAMILY_XBOX],
	[["generic"], FAMILY_GENERIC],
]

static var _kind: String = KIND_KEYBOARD
static var _last_device_id: int = -1

#================================================================================#
static func note_event(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_kind = KIND_KEYBOARD
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_kind = KIND_CONTROLLER
		_last_device_id = event.device

static func device_kind() -> String:
	return _kind

static func using_keyboard() -> bool:
	return _kind == KIND_KEYBOARD

static func using_controller() -> bool:
	return _kind == KIND_CONTROLLER

static func last_device_id() -> int:
	if _last_device_id >= 0 and Input.get_connected_joypads().has(_last_device_id):
		return _last_device_id
	var pads = Input.get_connected_joypads()
	return pads[0] if not pads.is_empty() else -1

static func current_family() -> String:
	return resolve_family(family_for_device(last_device_id()))

static func family_for_device(device_id: int) -> String:
	if device_id < 0 or not Input.get_connected_joypads().has(device_id):
		return FAMILY_XBOX
	return family_for_name(Input.get_joy_name(device_id))

static func family_for_name(device_name: String) -> String:
	var name = device_name.to_lower()
	if name.is_empty():
		return FAMILY_XBOX
	for hint in _NAME_HINTS:
		for token in hint[0]:
			if token in name:
				return hint[1]
	return FAMILY_XBOX

static func resolve_family(family: String) -> String:
	if family.is_empty():
		return current_family()
	match family:
		FAMILY_SWITCH_2:
			return FAMILY_SWITCH
		FAMILY_STEAM_CONTROLLER, FAMILY_GENERIC:
			return FAMILY_XBOX
		_:
			return family
#================================================================================#
