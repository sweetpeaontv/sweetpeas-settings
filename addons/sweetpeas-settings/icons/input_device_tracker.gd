# input_device_tracker.gd
class_name InputDeviceTracker
extends RefCounted

const KIND_KEYBOARD: String = "keyboard"
const KIND_CONTROLLER: String = "controller"

const FAMILY_GENERIC: String = "generic"
const FAMILY_XBOX: String = "xbox-series"
const FAMILY_PLAYSTATION: String = "playstation-series"
const FAMILY_SWITCH: String = "nintendo-switch"
const FAMILY_SWITCH_2: String = "nintendo-switch-2"
const FAMILY_STEAM_DECK: String = "steam-deck"
const FAMILY_STEAM_CONTROLLER: String = "steam-controller"
const FAMILY_STEAM_CONTROLLER_2: String = "steam-controller-2"

const _NAME_HINTS: Array = [
	[["steam deck", "steamdeck"], FAMILY_STEAM_DECK],
	[["steam controller 2", "steam controller (2025)"], FAMILY_STEAM_CONTROLLER_2],
	[["steam controller"], FAMILY_STEAM_CONTROLLER],
	[["dualsense", "dualshock", "playstation", "ps5", "ps4", "ps3"], FAMILY_PLAYSTATION],
	[["switch 2", "switch2"], FAMILY_SWITCH_2],
	[["switch", "joy-con", "joycon", "pro controller"], FAMILY_SWITCH],
	[["xbox", "xinput", "microsoft"], FAMILY_XBOX],
	[["generic"], FAMILY_GENERIC],
]

static var _kind: String = KIND_KEYBOARD
static var _last_device_id: int = -1
static var _connected_pads: Array = []
static var _pads_loaded: bool = false
static var _cached_family: String = FAMILY_XBOX
static var _family_dirty: bool = true

#================================================================================#
static func refresh_connections() -> void:
	_connected_pads = Input.get_connected_joypads()
	_pads_loaded = true
	_family_dirty = true

static func note_event(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_kind = KIND_KEYBOARD
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_kind = KIND_CONTROLLER
		if event.device != _last_device_id:
			_last_device_id = event.device
			_family_dirty = true

static func device_kind() -> String:
	return _kind

static func using_keyboard() -> bool:
	return _kind == KIND_KEYBOARD

static func using_controller() -> bool:
	return _kind == KIND_CONTROLLER

static func last_device_id() -> int:
	_ensure_pads()
	if _last_device_id >= 0 and _connected_pads.has(_last_device_id):
		return _last_device_id
	return _connected_pads[0] if not _connected_pads.is_empty() else -1

static func current_family() -> String:
	if not _family_dirty:
		return _cached_family
	_cached_family = family_for_device(last_device_id())
	_family_dirty = false
	return _cached_family

static func family_for_device(device_id: int) -> String:
	_ensure_pads()
	if device_id < 0 or not _connected_pads.has(device_id):
		return FAMILY_XBOX
	return family_for_name(Input.get_joy_name(device_id))

static func family_for_name(device_name: String) -> String:
	var name: String = device_name.to_lower()
	if name.is_empty():
		return FAMILY_XBOX
	for hint in _NAME_HINTS:
		for token in hint[0]:
			if token in name:
				return hint[1]
	return FAMILY_XBOX

static func _ensure_pads() -> void:
	if not _pads_loaded:
		refresh_connections()
#================================================================================#
