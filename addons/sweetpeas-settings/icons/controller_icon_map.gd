# controller_icon_map.gd
# Maps JoyButton / JoyAxis + family to SVG paths.
class_name ControllerIconMap
extends RefCounted

const FAMILY_XBOX = InputDeviceTracker.FAMILY_XBOX
const FAMILY_PLAYSTATION = InputDeviceTracker.FAMILY_PLAYSTATION
const FAMILY_SWITCH = InputDeviceTracker.FAMILY_SWITCH
const FAMILY_STEAM_DECK = InputDeviceTracker.FAMILY_STEAM_DECK

const _AXIS_DEADZONE = 0.5
const _PREFIX = {
	FAMILY_XBOX: "xbox",
	FAMILY_PLAYSTATION: "playstation",
	FAMILY_SWITCH: "switch",
	FAMILY_STEAM_DECK: "steamdeck",
}

const _FACE = {
	FAMILY_XBOX: ["a", "b", "x", "y"],
	FAMILY_STEAM_DECK: ["a", "b", "x", "y"],
	FAMILY_SWITCH: ["b", "a", "y", "x"],
	FAMILY_PLAYSTATION: ["cross", "circle", "square", "triangle"],
}

# back / start / guide / misc
const _SYSTEM = {
	FAMILY_XBOX: {
		"back": "xbox_button_view.svg",
		"start": "xbox_button_menu.svg",
		"guide": "xbox_guide.svg",
		"misc": "xbox_button_share.svg",
	},
	FAMILY_PLAYSTATION: {
		"back": "playstation4_button_share.svg",
		"start": "playstation4_button_options.svg",
		"misc": "playstation5_button_mute.svg",
	},
	FAMILY_SWITCH: {
		"back": "switch_button_minus.svg",
		"start": "switch_button_plus.svg",
		"guide": "switch_button_home.svg",
	},
	FAMILY_STEAM_DECK: {
		"back": "steamdeck_button_view.svg",
		"start": "steamdeck_button_options.svg",
		"guide": "steamdeck_button_guide.svg",
		"misc": "steamdeck_button_quickaccess.svg",
	},
}

const _PADDLES = {
	JOY_BUTTON_PADDLE1: "xbox_elite_paddle_top_left.svg",
	JOY_BUTTON_PADDLE2: "xbox_elite_paddle_top_right.svg",
	JOY_BUTTON_PADDLE3: "xbox_elite_paddle_bottom_left.svg",
	JOY_BUTTON_PADDLE4: "xbox_elite_paddle_bottom_right.svg",
}

const _DPAD = {
	JOY_BUTTON_DPAD_UP: "up",
	JOY_BUTTON_DPAD_DOWN: "down",
	JOY_BUTTON_DPAD_LEFT: "left",
	JOY_BUTTON_DPAD_RIGHT: "right",
}

# LOOKUP
#================================================================================#
static func path_for_button(button: JoyButton, family: String = "") -> String:
	family = _resolved_family(family)
	var file = _button_file(button, family)
	if file.is_empty() and family != FAMILY_XBOX:
		file = _button_file(button, FAMILY_XBOX)
		family = FAMILY_XBOX
	return Icons.join(family, file) if not file.is_empty() else ""

static func path_for_axis(axis: JoyAxis, axis_value: float = 1.0, family: String = "") -> String:
	family = _resolved_family(family)
	var file = _axis_file(axis, axis_value, family)
	if file.is_empty() and family != FAMILY_XBOX:
		file = _axis_file(axis, axis_value, FAMILY_XBOX)
		family = FAMILY_XBOX
	return Icons.join(family, file) if not file.is_empty() else ""

static func texture_for_button(button: JoyButton, family: String = "") -> Texture2D:
	return Icons.load_texture(path_for_button(button, family))

static func texture_for_axis(
	axis: JoyAxis,
	axis_value: float = 1.0,
	family: String = "",
) -> Texture2D:
	return Icons.load_texture(path_for_axis(axis, axis_value, family))
#================================================================================#

# INTERNAL
#================================================================================#
static func _resolved_family(family: String) -> String:
	if family.is_empty():
		return InputDeviceTracker.current_family()
	return InputDeviceTracker.resolve_family(family)

static func _prefix(family: String) -> String:
	return str(_PREFIX.get(family, "xbox"))

static func _button_file(button: JoyButton, family: String) -> String:
	var p = _prefix(family)
	match button:
		JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y:
			var faces = _FACE.get(family, _FACE[FAMILY_XBOX])
			return "%s_button_%s.svg" % [p, faces[int(button)]]
		JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
			return "%s_dpad_%s.svg" % [p, _DPAD[button]]
		JOY_BUTTON_LEFT_STICK:
			return _stick_click(family, "l")
		JOY_BUTTON_RIGHT_STICK:
			return _stick_click(family, "r")
		JOY_BUTTON_LEFT_SHOULDER:
			return _shoulder(family, "l")
		JOY_BUTTON_RIGHT_SHOULDER:
			return _shoulder(family, "r")
		JOY_BUTTON_BACK:
			return str(_SYSTEM.get(family, {}).get("back", ""))
		JOY_BUTTON_START:
			return str(_SYSTEM.get(family, {}).get("start", ""))
		JOY_BUTTON_GUIDE:
			return str(_SYSTEM.get(family, {}).get("guide", ""))
		JOY_BUTTON_MISC1:
			return str(_SYSTEM.get(family, {}).get("misc", ""))
		JOY_BUTTON_TOUCHPAD:
			return "playstation4_touchpad_press.svg" if family == FAMILY_PLAYSTATION else ""
		JOY_BUTTON_PADDLE1, JOY_BUTTON_PADDLE2, JOY_BUTTON_PADDLE3, JOY_BUTTON_PADDLE4:
			return str(_PADDLES.get(button, "")) if family == FAMILY_XBOX else ""
		_:
			return ""

static func _axis_file(axis: JoyAxis, axis_value: float, family: String) -> String:
	var p = _prefix(family)
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			return _trigger(family, "l")
		JOY_AXIS_TRIGGER_RIGHT:
			return _trigger(family, "r")
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			var stick = "l" if axis <= JOY_AXIS_LEFT_Y else "r"
			var horizontal = axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_RIGHT_X
			if absf(axis_value) < _AXIS_DEADZONE:
				return "%s_stick_%s.svg" % [p, stick]
			var dir = ""
			if horizontal:
				dir = "left" if axis_value < 0.0 else "right"
			else:
				dir = "up" if axis_value < 0.0 else "down"
			return "%s_stick_%s_%s.svg" % [p, stick, dir]
		_:
			return ""

static func _stick_click(family: String, side: String) -> String:
	if family == FAMILY_PLAYSTATION:
		return "playstation_button_%s3.svg" % side
	return "%s_stick_%s_press.svg" % [_prefix(family), side]

static func _shoulder(family: String, side: String) -> String:
	match family:
		FAMILY_XBOX:
			return "xbox_%sb.svg" % side
		FAMILY_PLAYSTATION:
			return "playstation_trigger_%s1.svg" % side
		FAMILY_SWITCH:
			return "switch_button_%s.svg" % side
		FAMILY_STEAM_DECK:
			return "steamdeck_button_%s1.svg" % side
		_:
			return ""

static func _trigger(family: String, side: String) -> String:
	match family:
		FAMILY_XBOX:
			return "xbox_%st.svg" % side
		FAMILY_PLAYSTATION:
			return "playstation_trigger_%s2.svg" % side
		FAMILY_SWITCH:
			return "switch_button_z%s.svg" % side
		FAMILY_STEAM_DECK:
			return "steamdeck_button_%s2.svg" % side
		_:
			return ""
#================================================================================#
