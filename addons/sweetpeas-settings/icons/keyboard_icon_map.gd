# keyboard_icon_map.gd
# Maps Key / MouseButton to SVG paths.
class_name KeyboardIconMap
extends RefCounted

const _SUBDIR = "keyboard-mouse"

const _SPECIAL_KEYS := {
	KEY_ESCAPE: "keyboard_escape.svg",
	KEY_TAB: "keyboard_tab.svg",
	KEY_BACKSPACE: "keyboard_backspace.svg",
	KEY_ENTER: "keyboard_enter.svg",
	KEY_KP_ENTER: "keyboard_numpad_enter.svg",
	KEY_INSERT: "keyboard_insert.svg",
	KEY_DELETE: "keyboard_delete.svg",
	KEY_HOME: "keyboard_home.svg",
	KEY_END: "keyboard_end.svg",
	KEY_PAGEUP: "keyboard_page_up.svg",
	KEY_PAGEDOWN: "keyboard_page_down.svg",
	KEY_LEFT: "keyboard_arrow_left.svg",
	KEY_UP: "keyboard_arrow_up.svg",
	KEY_RIGHT: "keyboard_arrow_right.svg",
	KEY_DOWN: "keyboard_arrow_down.svg",
	KEY_SHIFT: "keyboard_shift.svg",
	KEY_CTRL: "keyboard_ctrl.svg",
	KEY_ALT: "keyboard_alt.svg",
	KEY_CAPSLOCK: "keyboard_capslock.svg",
	KEY_NUMLOCK: "keyboard_numlock.svg",
	KEY_SCROLLLOCK: "keyboard_scroll_lock.svg",
	KEY_PRINT: "keyboard_printscreen.svg",
	KEY_PAUSE: "keyboard_pause.svg",
	KEY_SPACE: "keyboard_space.svg",
	KEY_APOSTROPHE: "keyboard_apostrophe.svg",
	KEY_COMMA: "keyboard_comma.svg",
	KEY_MINUS: "keyboard_minus.svg",
	KEY_PERIOD: "keyboard_period.svg",
	KEY_SLASH: "keyboard_slash_forward.svg",
	KEY_SEMICOLON: "keyboard_semicolon.svg",
	KEY_EQUAL: "keyboard_equals.svg",
	KEY_BRACKETLEFT: "keyboard_bracket_open.svg",
	KEY_BACKSLASH: "keyboard_slash_back.svg",
	KEY_BRACKETRIGHT: "keyboard_bracket_close.svg",
	KEY_QUOTELEFT: "keyboard_tilde.svg",
	KEY_ASCIITILDE: "keyboard_tilde.svg",
	KEY_QUOTEDBL: "keyboard_quote.svg",
	KEY_ASTERISK: "keyboard_asterisk.svg",
	KEY_PLUS: "keyboard_plus.svg",
	KEY_KP_ADD: "keyboard_numpad_plus.svg",
	KEY_KP_SUBTRACT: "keyboard_minus.svg",
	KEY_KP_MULTIPLY: "keyboard_asterisk.svg",
	KEY_KP_DIVIDE: "keyboard_slash_forward.svg",
	KEY_KP_PERIOD: "keyboard_period.svg",
	KEY_KP_0: "keyboard_0.svg",
	KEY_KP_1: "keyboard_1.svg",
	KEY_KP_2: "keyboard_2.svg",
	KEY_KP_3: "keyboard_3.svg",
	KEY_KP_4: "keyboard_4.svg",
	KEY_KP_5: "keyboard_5.svg",
	KEY_KP_6: "keyboard_6.svg",
	KEY_KP_7: "keyboard_7.svg",
	KEY_KP_8: "keyboard_8.svg",
	KEY_KP_9: "keyboard_9.svg",
	KEY_F1: "keyboard_f1.svg",
	KEY_F2: "keyboard_f2.svg",
	KEY_F3: "keyboard_f3.svg",
	KEY_F4: "keyboard_f4.svg",
	KEY_F5: "keyboard_f5.svg",
	KEY_F6: "keyboard_f6.svg",
	KEY_F7: "keyboard_f7.svg",
	KEY_F8: "keyboard_f8.svg",
	KEY_F9: "keyboard_f9.svg",
	KEY_F10: "keyboard_f10.svg",
	KEY_F11: "keyboard_f11.svg",
	KEY_F12: "keyboard_f12.svg",
	KEY_MENU: "keyboard_function.svg",
}

const _MOUSE_BUTTONS := {
	MOUSE_BUTTON_LEFT: "mouse_left.svg",
	MOUSE_BUTTON_RIGHT: "mouse_right.svg",
	MOUSE_BUTTON_MIDDLE: "mouse_scroll.svg",
	MOUSE_BUTTON_WHEEL_UP: "mouse_scroll_up.svg",
	MOUSE_BUTTON_WHEEL_DOWN: "mouse_scroll_down.svg",
	MOUSE_BUTTON_XBUTTON1: "mouse_side_back.svg",
	MOUSE_BUTTON_XBUTTON2: "mouse_side_forward.svg",
}

# LOOKUP
#================================================================================#
static func path_for_key(key: Key) -> String:
	var file = _key_file(key)
	return SweetIcons.join(_SUBDIR, file) if not file.is_empty() else ""

static func path_for_mouse_button(button: MouseButton) -> String:
	var file = str(_MOUSE_BUTTONS.get(button, ""))
	return SweetIcons.join(_SUBDIR, file) if not file.is_empty() else ""

static func path_for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var e := event as InputEventKey
		var key: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		return path_for_key(key)
	if event is InputEventMouseButton:
		return path_for_mouse_button((event as InputEventMouseButton).button_index)
	return ""

static func texture_for_key(key: Key) -> Texture2D:
	return SweetIcons.load_texture(path_for_key(key))

static func texture_for_mouse_button(button: MouseButton) -> Texture2D:
	return SweetIcons.load_texture(path_for_mouse_button(button))

static func texture_for_event(event: InputEvent) -> Texture2D:
	return SweetIcons.load_texture(path_for_event(event))
#================================================================================#

# INTERNAL
#================================================================================#
static func _key_file(key: Key) -> String:
	if key == KEY_NONE:
		return ""
	if key == KEY_META:
		return "keyboard_command.svg" if OS.has_feature("macos") or OS.has_feature("web_macos") else "keyboard_win.svg"
	if _SPECIAL_KEYS.has(key):
		return str(_SPECIAL_KEYS[key])
	# Letters A–Z and digits 0–9 share Kenney's lowercase filenames.
	if key >= KEY_A and key <= KEY_Z:
		return "keyboard_%s.svg" % String.chr(int(key)).to_lower()
	if key >= KEY_0 and key <= KEY_9:
		return "keyboard_%s.svg" % String.chr(int(key))
	return ""
#================================================================================#
