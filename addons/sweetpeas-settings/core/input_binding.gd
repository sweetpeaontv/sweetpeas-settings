# input_binding.gd
# InputMap events <-> { "keyboard": [...], "controller": [...] } for settings JSON.
class_name SweetInputBinding
extends RefCounted

const KEYBOARD := "keyboard"
const CONTROLLER := "controller"

# API
#================================================================================#
static func empty_binding() -> Dictionary:
	return {KEYBOARD: [], CONTROLLER: []}

static func snapshot_action(action: StringName) -> Dictionary:
	var binding := empty_binding()
	if not InputMap.has_action(action):
		return binding

	for event in InputMap.action_get_events(action):
		var encoded: Variant = encode_event(event)
		if encoded == null:
			continue
		var column := column_for_event(event)
		if not column.is_empty():
			binding[column].append(encoded)
	return binding

static func apply_to_action(action: String, binding: Variant) -> void:
	if not InputMap.has_action(action):
		push_warning(
			"Sweetpea's Settings: InputMap has no action '%s'; skipped keybind apply." % action
		)
		return

	InputMap.action_erase_events(action)
	var normalized := coerce(binding)
	for column in [KEYBOARD, CONTROLLER]:
		for encoded in normalized[column]:
			var event := decode_event(encoded)
			if event:
				InputMap.action_add_event(action, event)

static func coerce(value: Variant, fallback: Variant = null) -> Dictionary:
	var base := empty_binding()
	if fallback is Dictionary:
		base = {
			KEYBOARD: _normalize_column(fallback.get(KEYBOARD, [])),
			CONTROLLER: _normalize_column(fallback.get(CONTROLLER, [])),
		}
	if not value is Dictionary:
		return base
	return {
		KEYBOARD: _normalize_column(value.get(KEYBOARD, base[KEYBOARD])),
		CONTROLLER: _normalize_column(value.get(CONTROLLER, base[CONTROLLER])),
	}

static func same_binding(a: Variant, b: Variant) -> bool:
	return coerce(a) == coerce(b)

static func same_event(a: Variant, b: Variant) -> bool:
	var left := _normalize_event(a)
	var right := _normalize_event(b)
	if left == null or right == null:
		return false
	return left == right

static func event_fingerprint(encoded: Variant) -> String:
	var normalized := _normalize_event(encoded)
	if normalized == null:
		return ""
	return JSON.stringify(normalized)

static func binding_contains_event(binding: Variant, encoded: Variant) -> bool:
	var needle := _normalize_event(encoded)
	if needle == null:
		return false

	var normalized := coerce(binding)
	for column in [KEYBOARD, CONTROLLER]:
		for entry in normalized[column]:
			if same_event(entry, needle):
				return true
	return false

static func remove_event(binding: Variant, encoded: Variant) -> Dictionary:
	var needle := _normalize_event(encoded)
	var normalized := coerce(binding)
	if needle == null:
		return normalized

	var result := empty_binding()
	for column in [KEYBOARD, CONTROLLER]:
		for entry in normalized[column]:
			if same_event(entry, needle):
				continue
			result[column].append(entry)
	return result

static func column_for_event(event: InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton:
		return KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return CONTROLLER
	return ""
#================================================================================#

# ENCODE / DECODE
#================================================================================#
static func encode_event(event: InputEvent) -> Variant:
	if event is InputEventKey:
		var e := event as InputEventKey
		return _with_mods({
			"type": "key",
			"keycode": int(e.keycode),
			"physical_keycode": int(e.physical_keycode),
		}, e)
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		return _with_mods({"type": "mouse_button", "button_index": int(e.button_index)}, e)
	if event is InputEventJoypadButton:
		var e := event as InputEventJoypadButton
		return {"type": "joypad_button", "button_index": int(e.button_index)}
	if event is InputEventJoypadMotion:
		var e := event as InputEventJoypadMotion
		return {
			"type": "joypad_motion",
			"axis": int(e.axis),
			"axis_value": float(e.axis_value),
		}
	return null

static func decode_event(encoded: Variant) -> InputEvent:
	if not encoded is Dictionary:
		return null

	var data: Dictionary = encoded
	match str(data.get("type", "")):
		"key":
			var e := InputEventKey.new()
			e.keycode = int(data.get("keycode", 0)) as Key
			e.physical_keycode = int(data.get("physical_keycode", 0)) as Key
			_read_mods(e, data)
			return e
		"mouse_button":
			var e := InputEventMouseButton.new()
			e.button_index = int(data.get("button_index", 0)) as MouseButton
			_read_mods(e, data)
			return e
		"joypad_button":
			var e := InputEventJoypadButton.new()
			e.button_index = int(data.get("button_index", 0)) as JoyButton
			return e
		"joypad_motion":
			var e := InputEventJoypadMotion.new()
			e.axis = int(data.get("axis", 0)) as JoyAxis
			e.axis_value = float(data.get("axis_value", 0.0))
			return e
	return null
#================================================================================#

# INTERNAL
#================================================================================#
static func _normalize_column(raw: Variant) -> Array:
	var out: Array = []
	if not raw is Array:
		return out
	for entry in raw:
		var encoded := _normalize_event(entry)
		if encoded != null:
			out.append(encoded)
	return out

# Rebuild via decode/encode so partial or oddly-typed dicts match the
# canonical shape from encode_event (same keys/types for dict equality).
# Keyboard events also canonicalize keycode/physical_keycode to one code so
# schema defaults and live presses fingerprint the same.
static func _normalize_event(encoded: Variant) -> Variant:
	var event := decode_event(encoded)
	if event == null:
		return null
	var normalized: Variant = encode_event(event)
	if not normalized is Dictionary:
		return normalized
	var data: Dictionary = normalized
	if str(data.get("type", "")) != "key":
		return data
	var code: int = int(data.get("physical_keycode", 0))
	if code == int(KEY_NONE):
		code = int(data.get("keycode", 0))
	data["keycode"] = code
	data["physical_keycode"] = code
	return data

static func _with_mods(data: Dictionary, event: InputEventWithModifiers) -> Dictionary:
	data["shift"] = event.shift_pressed
	data["ctrl"] = event.ctrl_pressed
	data["alt"] = event.alt_pressed
	data["meta"] = event.meta_pressed
	return data

static func _read_mods(event: InputEventWithModifiers, data: Dictionary) -> void:
	event.shift_pressed = bool(data.get("shift", false))
	event.ctrl_pressed = bool(data.get("ctrl", false))
	event.alt_pressed = bool(data.get("alt", false))
	event.meta_pressed = bool(data.get("meta", false))
#================================================================================#
