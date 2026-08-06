extends RefCounted

class OptionValueEditor extends SweetValueEditor:
	var _option_button: OptionButton

	func _init() -> void:
		_option_button = OptionButton.new()
		_option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_option_button.item_selected.connect(_on_item_selected)

	func get_control() -> Control:
		return _option_button

	func setup(setting: Dictionary) -> void:
		_option_button.clear()
		for opt in setting.get("options", []):
			if opt is Dictionary:
				_option_button.add_item(tr(String(opt.get("label", ""))), -1)
				_option_button.set_item_metadata(_option_button.item_count - 1, opt.get("value"))

	func get_value() -> Variant:
		if _option_button.selected < 0:
			return null
		return _option_button.get_item_metadata(_option_button.selected)

	func set_value(value: Variant) -> void:
		for i in _option_button.item_count:
			if _values_match(_option_button.get_item_metadata(i), value):
				_option_button.select(i)
				break

	func set_disabled(disabled: bool) -> void:
		_option_button.disabled = disabled

	func _on_item_selected(_index: int) -> void:
		value_changed.emit(get_value())

	func _values_match(a: Variant, b: Variant) -> bool:
		if a == b:
			return true
		if (a is int or a is float) and (b is int or b is float):
			return float(a) == float(b)
		return false

class SpinboxValueEditor extends SweetValueEditor:
	var _spinbox: SpinBox

	func _init() -> void:
		_spinbox = SpinBox.new()
		_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_spinbox.value_changed.connect(_on_value_changed)

	func get_control() -> Control:
		return _spinbox

	func setup(setting: Dictionary) -> void:
		_spinbox.min_value = setting.get("min", 0)
		_spinbox.max_value = setting.get("max", 100)
		_spinbox.step = setting.get("step", 1)
		_spinbox.rounded = setting.get("step", 1) >= 1.0

	func get_value() -> Variant:
		return _spinbox.value

	func set_value(value: Variant) -> void:
		_spinbox.value = float(value)

	func set_disabled(disabled: bool) -> void:
		_spinbox.editable = not disabled

	func _on_value_changed(value: float) -> void:
		value_changed.emit(value)

class ToggleValueEditor extends SweetValueEditor:
	var _checkbox: CheckBox

	func _init() -> void:
		_checkbox = CheckBox.new()
		_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_checkbox.toggled.connect(_on_toggled)

	func get_control() -> Control:
		return _checkbox

	func setup(_setting: Dictionary) -> void:
		pass

	func get_value() -> Variant:
		return _checkbox.button_pressed

	func set_value(value: Variant) -> void:
		_checkbox.button_pressed = bool(value)

	func set_disabled(disabled: bool) -> void:
		_checkbox.disabled = disabled

	func _on_toggled(toggled: bool) -> void:
		value_changed.emit(toggled)
