# controller_icon_map.gd
# Maps JoyButton / JoyAxis to an icon path for a given controller family.

extends RefCounted

const IconPaths = preload("uid://cxwurn6qv7ral")
const InputDeviceTracker = preload("uid://dpnmg6swmq30l")

const _AXIS_DEADZONE := 0.5

# PROFILES
#================================================================================#
# dir      folder under icons/ holding this family's art
# device   whole-controller image, used by the controls header
# buttons  JoyButton -> filename
# axes     JoyAxis -> { neutral, negative, positive }; triggers use neutral only
const _PROFILES := {
	InputDeviceTracker.FAMILY_XBOX: {
		"dir": "xbox-series",
		"device": "controller_xboxseries.svg",
		"buttons": {
			JOY_BUTTON_A: "xbox_button_a.svg",
			JOY_BUTTON_B: "xbox_button_b.svg",
			JOY_BUTTON_X: "xbox_button_x.svg",
			JOY_BUTTON_Y: "xbox_button_y.svg",
			JOY_BUTTON_DPAD_UP: "xbox_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "xbox_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "xbox_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "xbox_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "xbox_lb.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb.svg",
			JOY_BUTTON_LEFT_STICK: "xbox_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "xbox_stick_r_press.svg",
			JOY_BUTTON_BACK: "xbox_button_view.svg",
			JOY_BUTTON_START: "xbox_button_menu.svg",
			JOY_BUTTON_GUIDE: "xbox_guide.svg",
			JOY_BUTTON_MISC1: "xbox_button_share.svg",
			JOY_BUTTON_PADDLE1: "xbox_elite_paddle_top_left.svg",
			JOY_BUTTON_PADDLE2: "xbox_elite_paddle_top_right.svg",
			JOY_BUTTON_PADDLE3: "xbox_elite_paddle_bottom_left.svg",
			JOY_BUTTON_PADDLE4: "xbox_elite_paddle_bottom_right.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "xbox_stick_l.svg",
				"negative": "xbox_stick_l_left.svg",
				"positive": "xbox_stick_l_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "xbox_stick_l.svg",
				"negative": "xbox_stick_l_up.svg",
				"positive": "xbox_stick_l_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "xbox_stick_r.svg",
				"negative": "xbox_stick_r_left.svg",
				"positive": "xbox_stick_r_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "xbox_stick_r.svg",
				"negative": "xbox_stick_r_up.svg",
				"positive": "xbox_stick_r_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "xbox_lt.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "xbox_rt.svg"},
		},
	},

	InputDeviceTracker.FAMILY_PLAYSTATION: {
		"dir": "playstation-series",
		"device": "controller_playstation5.svg",
		# No guide/PS-button art ships with the pack; that button falls back to Xbox.
		"buttons": {
			JOY_BUTTON_A: "playstation_button_cross.svg",
			JOY_BUTTON_B: "playstation_button_circle.svg",
			JOY_BUTTON_X: "playstation_button_square.svg",
			JOY_BUTTON_Y: "playstation_button_triangle.svg",
			JOY_BUTTON_DPAD_UP: "playstation_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "playstation_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "playstation_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "playstation_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "playstation_trigger_l1.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "playstation_trigger_r1.svg",
			JOY_BUTTON_LEFT_STICK: "playstation_button_l3.svg",
			JOY_BUTTON_RIGHT_STICK: "playstation_button_r3.svg",
			JOY_BUTTON_BACK: "playstation5_button_create.svg",
			JOY_BUTTON_START: "playstation5_button_options.svg",
			JOY_BUTTON_MISC1: "playstation5_button_mute.svg",
			JOY_BUTTON_TOUCHPAD: "playstation5_touchpad_press.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "playstation_stick_l.svg",
				"negative": "playstation_stick_l_left.svg",
				"positive": "playstation_stick_l_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "playstation_stick_l.svg",
				"negative": "playstation_stick_l_up.svg",
				"positive": "playstation_stick_l_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "playstation_stick_r.svg",
				"negative": "playstation_stick_r_left.svg",
				"positive": "playstation_stick_r_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "playstation_stick_r.svg",
				"negative": "playstation_stick_r_up.svg",
				"positive": "playstation_stick_r_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "playstation_trigger_l2.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "playstation_trigger_r2.svg"},
		},
	},

	InputDeviceTracker.FAMILY_SWITCH: {
		"dir": "nintendo-switch",
		"device": "controller_switch_pro.svg",
		"buttons": {
			JOY_BUTTON_A: "switch_button_b.svg",
			JOY_BUTTON_B: "switch_button_a.svg",
			JOY_BUTTON_X: "switch_button_y.svg",
			JOY_BUTTON_Y: "switch_button_x.svg",
			JOY_BUTTON_DPAD_UP: "switch_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "switch_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "switch_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "switch_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "switch_button_l.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "switch_button_r.svg",
			JOY_BUTTON_LEFT_STICK: "switch_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "switch_stick_r_press.svg",
			JOY_BUTTON_BACK: "switch_button_minus.svg",
			JOY_BUTTON_START: "switch_button_plus.svg",
			JOY_BUTTON_GUIDE: "switch_button_home.svg",
			JOY_BUTTON_MISC1: "switch_button_sync.svg",
			JOY_BUTTON_PADDLE1: "switch_button_sl.svg",
			JOY_BUTTON_PADDLE2: "switch_button_sr.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "switch_stick_l.svg",
				"negative": "switch_stick_l_left.svg",
				"positive": "switch_stick_l_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "switch_stick_l.svg",
				"negative": "switch_stick_l_up.svg",
				"positive": "switch_stick_l_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "switch_stick_r.svg",
				"negative": "switch_stick_r_left.svg",
				"positive": "switch_stick_r_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "switch_stick_r.svg",
				"negative": "switch_stick_r_up.svg",
				"positive": "switch_stick_r_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "switch_button_zl.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "switch_button_zr.svg"},
		},
	},

	InputDeviceTracker.FAMILY_SWITCH_2: {
		"dir": "nintendo-switch-2",
		"device": "controller_switch_pro.svg",
		"buttons": {
			JOY_BUTTON_A: "switch_button_b.svg",
			JOY_BUTTON_B: "switch_button_a.svg",
			JOY_BUTTON_X: "switch_button_y.svg",
			JOY_BUTTON_Y: "switch_button_x.svg",
			JOY_BUTTON_DPAD_UP: "switch_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "switch_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "switch_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "switch_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "switch_button_l.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "switch_button_r.svg",
			JOY_BUTTON_LEFT_STICK: "switch_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "switch_stick_r_press.svg",
			JOY_BUTTON_BACK: "switch_button_minus.svg",
			JOY_BUTTON_START: "switch_button_plus.svg",
			JOY_BUTTON_GUIDE: "switch_button_home.svg",
			JOY_BUTTON_MISC1: "switch_button_c.svg",
			JOY_BUTTON_PADDLE1: "switch_button_gl.svg",
			JOY_BUTTON_PADDLE2: "switch_button_gr.svg",
			JOY_BUTTON_PADDLE3: "switch_button_sl.svg",
			JOY_BUTTON_PADDLE4: "switch_button_sr.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "switch_stick_l.svg",
				"negative": "switch_stick_l_left.svg",
				"positive": "switch_stick_l_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "switch_stick_l.svg",
				"negative": "switch_stick_l_up.svg",
				"positive": "switch_stick_l_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "switch_stick_r.svg",
				"negative": "switch_stick_r_left.svg",
				"positive": "switch_stick_r_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "switch_stick_r.svg",
				"negative": "switch_stick_r_up.svg",
				"positive": "switch_stick_r_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "switch_button_zl.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "switch_button_zr.svg"},
		},
	},

	InputDeviceTracker.FAMILY_STEAM_DECK: {
		"dir": "steam-deck",
		"device": "controller_steamdeck.svg",
		"buttons": {
			JOY_BUTTON_A: "steamdeck_button_a.svg",
			JOY_BUTTON_B: "steamdeck_button_b.svg",
			JOY_BUTTON_X: "steamdeck_button_x.svg",
			JOY_BUTTON_Y: "steamdeck_button_y.svg",
			JOY_BUTTON_DPAD_UP: "steamdeck_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "steamdeck_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "steamdeck_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "steamdeck_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "steamdeck_button_l1.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "steamdeck_button_r1.svg",
			JOY_BUTTON_LEFT_STICK: "steamdeck_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "steamdeck_stick_r_press.svg",
			JOY_BUTTON_BACK: "steamdeck_button_view.svg",
			JOY_BUTTON_START: "steamdeck_button_options.svg",
			JOY_BUTTON_GUIDE: "steamdeck_button_guide.svg",
			JOY_BUTTON_MISC1: "steamdeck_button_quickaccess.svg",
			JOY_BUTTON_PADDLE1: "steamdeck_button_l4.svg",
			JOY_BUTTON_PADDLE2: "steamdeck_button_r4.svg",
			JOY_BUTTON_PADDLE3: "steamdeck_button_l5.svg",
			JOY_BUTTON_PADDLE4: "steamdeck_button_r5.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "steamdeck_stick_l.svg",
				"negative": "steamdeck_stick_l_left.svg",
				"positive": "steamdeck_stick_l_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "steamdeck_stick_l.svg",
				"negative": "steamdeck_stick_l_up.svg",
				"positive": "steamdeck_stick_l_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "steamdeck_stick_r.svg",
				"negative": "steamdeck_stick_r_left.svg",
				"positive": "steamdeck_stick_r_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "steamdeck_stick_r.svg",
				"negative": "steamdeck_stick_r_up.svg",
				"positive": "steamdeck_stick_r_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "steamdeck_button_l2.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "steamdeck_button_r2.svg"},
		},
	},

	InputDeviceTracker.FAMILY_STEAM_CONTROLLER: {
		"dir": "steam-controller",
		"device": "controller_steam.svg",
		"buttons": {
			JOY_BUTTON_A: "steam_button_a.svg",
			JOY_BUTTON_B: "steam_button_b.svg",
			JOY_BUTTON_X: "steam_button_x.svg",
			JOY_BUTTON_Y: "steam_button_y.svg",
			JOY_BUTTON_DPAD_UP: "steam_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "steam_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "steam_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "steam_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "steam_lb.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "steam_rb.svg",
			JOY_BUTTON_LEFT_STICK: "steam_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "steam_button_rp.svg",
			JOY_BUTTON_BACK: "steam_button_back_icon.svg",
			JOY_BUTTON_START: "steam_button_start_icon.svg",
			JOY_BUTTON_GUIDE: "controller_steam.svg",
			JOY_BUTTON_TOUCHPAD: "steam_button_lp.svg",
			JOY_BUTTON_PADDLE1: "steam_lg.svg",
			JOY_BUTTON_PADDLE2: "steam_rg.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_left.svg",
				"positive": "steam_stick_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_up.svg",
				"positive": "steam_stick_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "steam_pad.svg",
				"negative": "steam_pad_left.svg",
				"positive": "steam_pad_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "steam_pad.svg",
				"negative": "steam_pad_up.svg",
				"positive": "steam_pad_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "steam_lt.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "steam_rt.svg"},
		},
	},

	InputDeviceTracker.FAMILY_STEAM_CONTROLLER_2: {
		"dir": "steam-controller",
		"device": "controller_steam_new.svg",
		"buttons": {
			JOY_BUTTON_A: "steam_button_a.svg",
			JOY_BUTTON_B: "steam_button_b.svg",
			JOY_BUTTON_X: "steam_button_x.svg",
			JOY_BUTTON_Y: "steam_button_y.svg",
			JOY_BUTTON_DPAD_UP: "steam_dpad_up.svg",
			JOY_BUTTON_DPAD_DOWN: "steam_dpad_down.svg",
			JOY_BUTTON_DPAD_LEFT: "steam_dpad_left.svg",
			JOY_BUTTON_DPAD_RIGHT: "steam_dpad_right.svg",
			JOY_BUTTON_LEFT_SHOULDER: "controller_button_l1.svg",
			JOY_BUTTON_RIGHT_SHOULDER: "controller_button_r1.svg",
			JOY_BUTTON_LEFT_STICK: "steam_stick_l_press.svg",
			JOY_BUTTON_RIGHT_STICK: "steam_button_rp.svg",
			JOY_BUTTON_BACK: "controller_button_view.svg",
			JOY_BUTTON_START: "controller_button_options.svg",
			JOY_BUTTON_GUIDE: "controller_icon.svg",
			JOY_BUTTON_MISC1: "controller_button_quickaccess.svg",
			JOY_BUTTON_TOUCHPAD: "steam_button_lp.svg",
			JOY_BUTTON_PADDLE1: "controller_button_l4.svg",
			JOY_BUTTON_PADDLE2: "controller_button_r4.svg",
			JOY_BUTTON_PADDLE3: "controller_button_l5.svg",
			JOY_BUTTON_PADDLE4: "controller_button_r5.svg",
		},
		"axes": {
			JOY_AXIS_LEFT_X: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_left.svg",
				"positive": "steam_stick_right.svg",
			},
			JOY_AXIS_LEFT_Y: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_up.svg",
				"positive": "steam_stick_down.svg",
			},
			JOY_AXIS_RIGHT_X: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_left.svg",
				"positive": "steam_stick_right.svg",
			},
			JOY_AXIS_RIGHT_Y: {
				"neutral": "steam_stick.svg",
				"negative": "steam_stick_up.svg",
				"positive": "steam_stick_down.svg",
			},
			JOY_AXIS_TRIGGER_LEFT: {"neutral": "controller_button_l2.svg"},
			JOY_AXIS_TRIGGER_RIGHT: {"neutral": "controller_button_r2.svg"},
		},
	},
}
#================================================================================#

# LOOKUP
#================================================================================#
# Narrows a detected family to one that has art. Unknown families render as Xbox.
static func resolve_family(family: String) -> String:
	if family.is_empty():
		family = InputDeviceTracker.current_family()
	return family if _PROFILES.has(family) else InputDeviceTracker.FAMILY_XBOX

static func path_for_button(button: JoyButton, family: String = "") -> String:
	family = resolve_family(family)
	var file := str(_buttons(family).get(button, ""))
	if file.is_empty() and family != InputDeviceTracker.FAMILY_XBOX:
		return path_for_button(button, InputDeviceTracker.FAMILY_XBOX)
	return _join(family, file)

static func path_for_axis(axis: JoyAxis, axis_value: float = 1.0, family: String = "") -> String:
	family = resolve_family(family)
	var file := _axis_file(axis, axis_value, family)
	if file.is_empty() and family != InputDeviceTracker.FAMILY_XBOX:
		return path_for_axis(axis, axis_value, InputDeviceTracker.FAMILY_XBOX)
	return _join(family, file)

static func path_for_device(family: String = "") -> String:
	family = resolve_family(family)
	return _join(family, str(_PROFILES[family].get("device", "")))

static func texture_for_button(button: JoyButton, family: String = "") -> Texture2D:
	return IconPaths.load_texture(path_for_button(button, family))

static func texture_for_axis(
	axis: JoyAxis,
	axis_value: float = 1.0,
	family: String = "",
) -> Texture2D:
	return IconPaths.load_texture(path_for_axis(axis, axis_value, family))

static func texture_for_device(family: String = "") -> Texture2D:
	return IconPaths.load_texture(path_for_device(family))
#================================================================================#

# INTERNAL
#================================================================================#
static func _buttons(family: String) -> Dictionary:
	return _PROFILES[family].get("buttons", {})

static func _axis_file(axis: JoyAxis, axis_value: float, family: String) -> String:
	var entry: Variant = _PROFILES[family].get("axes", {}).get(axis)
	if not entry is Dictionary:
		return ""

	if absf(axis_value) < _AXIS_DEADZONE:
		return str((entry as Dictionary).get("neutral", ""))

	var slot := "negative" if axis_value < 0.0 else "positive"
	var file := str((entry as Dictionary).get(slot, ""))
	return file if not file.is_empty() else str((entry as Dictionary).get("neutral", ""))

static func _join(family: String, file: String) -> String:
	if file.is_empty():
		return ""
	return IconPaths.join(str(_PROFILES[family].get("dir", "")), file)
#================================================================================#
