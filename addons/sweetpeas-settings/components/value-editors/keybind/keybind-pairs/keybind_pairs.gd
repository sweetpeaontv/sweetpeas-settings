class_name KeybindPairs
extends VBoxContainer
"""
All keyboard/controller binding rows for one keybind setting (one action).
Builds the slot grid, stores the binding data, and keeps each cell's display up to date.
"""

signal slot_pressed(column: String, index: int)
signal clear_pressed(column: String, index: int)

const _UNBOUND_TEXT: String = "—"
const _SLOT_SCENE = preload("uid://c0uhrmy4gxqqv")

var _binding: Dictionary = InputBinding.empty_binding()
var _conflicts: Dictionary = {}
var _setting_key: String = ""
var _min_pair_rows: int = 1
var _disabled: bool = false
var _listening_column: String = ""
var _listening_index: int = -1

# Each entry: { "slot": KeybindSlot, "column": String, "index": int }
var _slot_entries: Array[Dictionary] = []

# INIT
#================================================================================#
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 4)
	sync()
#================================================================================#

# API
#================================================================================#
func set_binding(binding: Dictionary) -> void:
	_binding = InputBinding.coerce(binding)
	_min_pair_rows = maxi(_natural_pair_count(), 1)
	sync()

func get_binding() -> Dictionary:
	return InputBinding.coerce(_binding)

func set_setting_key(key: String) -> void:
	_setting_key = key

func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	for entry in _slot_entries:
		var slot: KeybindSlot = entry["slot"]
		slot.set_disabled(disabled)

func set_listening(column: String, index: int) -> void:
	_listening_column = column
	_listening_index = index
	_refresh_slots()

func set_conflicts(conflicts: Dictionary, setting_key: String) -> void:
	_conflicts = conflicts if conflicts != null else {}
	_setting_key = setting_key
	_refresh_slots()

func add_row() -> void:
	_min_pair_rows = _pair_row_count() + 1
	_rebuild_pairs()

func set_slot_event(column: String, index: int, encoded: Variant) -> void:
	var column_events: Array = (_binding.get(column, []) as Array).duplicate()
	if index < column_events.size():
		column_events[index] = encoded
	else:
		column_events.append(encoded)
	_binding[column] = column_events
	_min_pair_rows = maxi(_natural_pair_count(), _min_pair_rows)

func clear_slot(column: String, index: int) -> bool:
	var column_events: Array = (_binding.get(column, []) as Array).duplicate()
	if index < 0 or index >= column_events.size():
		return false
	column_events.remove_at(index)
	_binding[column] = column_events
	_min_pair_rows = maxi(_natural_pair_count(), 1)
	return true

func is_clear_badge_at(column: String, index: int, global_pos: Vector2) -> bool:
	for entry in _slot_entries:
		if entry["column"] != column or entry["index"] != index:
			continue
		var slot: KeybindSlot = entry["slot"]
		return slot.is_clear_badge_at(global_pos)
	return false

func sync() -> void:
	if get_child_count() != _pair_row_count():
		_rebuild_pairs()
	else:
		_refresh_slots()
#================================================================================#

# PAIRS
#================================================================================#
func _natural_pair_count() -> int:
	return maxi(
		(_binding.get(InputBinding.KEYBOARD, []) as Array).size(),
		(_binding.get(InputBinding.CONTROLLER, []) as Array).size()
	)

func _pair_row_count() -> int:
	return maxi(_natural_pair_count(), maxi(_min_pair_rows, 1))

func _slot_encoded(column: String, index: int) -> Variant:
	var column_events: Array = _binding.get(column, [])
	if index < 0 or index >= column_events.size():
		return null
	return column_events[index]

func _rebuild_pairs() -> void:
	while get_child_count() > 0:
		var child: Node = get_child(0)
		remove_child(child)
		child.free()
	_slot_entries.clear()

	var row_count: int = _pair_row_count()
	for index in row_count:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(row)

		_create_slot(row, InputBinding.KEYBOARD, index)
		_create_slot(row, InputBinding.CONTROLLER, index)

	_refresh_slots()

func _create_slot(row: HBoxContainer, column: String, index: int) -> void:
	var slot: KeybindSlot = _SLOT_SCENE.instantiate()
	slot.set_disabled(_disabled)
	slot.pressed.connect(_on_slot_pressed.bind(column, index))
	slot.clear_pressed.connect(_on_clear_pressed.bind(column, index))
	row.add_child(slot)
	_slot_entries.append({
		"slot": slot,
		"column": column,
		"index": index,
	})
#================================================================================#

# DISPLAY
#================================================================================#
func _refresh_slots() -> void:
	for entry in _slot_entries:
		_refresh_slot(entry)

func _refresh_slot(entry: Dictionary) -> void:
	var slot: KeybindSlot = entry["slot"]
	var column: String = entry["column"]
	var index: int = entry["index"]
	var listening: bool = _listening_column == column and _listening_index == index
	var encoded: Variant = _slot_encoded(column, index)

	if listening:
		slot.set_listening(true)
		slot.set_conflicted(false)
		return

	if encoded == null:
		slot.set_display(null, _UNBOUND_TEXT)
		slot.set_listening(false)
		slot.set_conflicted(false)
		return

	var event: InputEvent = InputBinding.decode_event(encoded)
	var texture: Texture2D = Icons.texture_for_event(event) if event else null
	if texture != null:
		slot.set_display(texture, "")
	else:
		slot.set_display(null, _fallback_label(event))

	slot.set_listening(false)

	var conflict_keys: Array = _conflict_keys_for(encoded)
	var has_conflict: bool = not conflict_keys.is_empty()
	slot.set_conflicted(has_conflict, _conflict_tooltip(conflict_keys) if has_conflict else "")

func _conflict_keys_for(encoded: Variant) -> Array:
	if encoded == null:
		return []
	var fingerprint: String = InputBinding.event_fingerprint(encoded)
	if fingerprint.is_empty() or not _conflicts.has(fingerprint):
		return []
	var keys: Array = []
	for key in _conflicts[fingerprint]:
		if str(key) != _setting_key:
			keys.append(str(key))
	return keys

func _conflict_tooltip(other_keys: Array) -> String:
	if other_keys.is_empty():
		return "Binding conflict"
	return "Also bound on: %s" % ", ".join(PackedStringArray(other_keys))
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_slot_pressed(column: String, index: int) -> void:
	slot_pressed.emit(column, index)

func _on_clear_pressed(column: String, index: int) -> void:
	clear_pressed.emit(column, index)
#================================================================================#

# HELPERS
#================================================================================#
func _fallback_label(event: InputEvent) -> String:
	if event == null:
		return _UNBOUND_TEXT
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		var text: String = OS.get_keycode_string(code)
		return text if not text.is_empty() else _UNBOUND_TEXT
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MOUSE_BUTTON_WHEEL_UP:
				return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel Down"
			MOUSE_BUTTON_XBUTTON1:
				return "Mouse 4"
			MOUSE_BUTTON_XBUTTON2:
				return "Mouse 5"
			_:
				return "Mouse"
	if event is InputEventJoypadButton:
		return "Btn %d" % (event as InputEventJoypadButton).button_index
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		return "Axis %d" % motion.axis
	return _UNBOUND_TEXT
#================================================================================#
