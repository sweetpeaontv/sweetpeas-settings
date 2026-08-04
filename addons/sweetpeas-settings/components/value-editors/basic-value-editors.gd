class_name BasicValueEditors
extends RefCounted

class SliderValueEditor extends ValueEditor:
	var _root: HBoxContainer
	var _min_label: Label
	var _slider: HSlider
	var _max_label: Label

	func _init() -> void:
		_root = HBoxContainer.new()
		_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_root.alignment = BoxContainer.ALIGNMENT_CENTER
		_root.add_theme_constant_override("separation", 8)

		_min_label = Label.new()
		_min_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_max_label = Label.new()
		_max_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		_slider = HSlider.new()
		_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_slider.ticks_on_borders = true
		_slider.tick_count = 0
		_slider.ticks_position = Slider.TICK_POSITION_CENTER
		_slider.value_changed.connect(_on_value_changed)

		_root.add_child(_min_label)
		_root.add_child(_slider)
		_root.add_child(_max_label)

	func get_control() -> Control:
		return _root

	func setup(setting: Dictionary) -> void:
		var min_value: float = setting.get("min", 0.0)
		var max_value: float = setting.get("max", 1.0)
		var step: float = setting.get("step", 0.01)

		_slider.min_value = min_value
		_slider.max_value = max_value
		_slider.step = step

		_min_label.text = _format_bound(min_value, step)
		_max_label.text = _format_bound(max_value, step)

	func get_value() -> Variant:
		return _slider.value

	func set_value(value: Variant) -> void:
		_slider.value = float(value)

	func _format_bound(value: float, step: float) -> String:
		var snapped_value := snapped(value, step)
		if step >= 1.0:
			return str(int(snapped_value))
		return str(snapped_value)

	func _on_value_changed(value: float) -> void:
		value_changed.emit(value)

class OptionValueEditor extends ValueEditor:
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
				_option_button.add_item(String(opt.get("label", "")), -1)
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

	func _on_item_selected(_index: int) -> void:
		value_changed.emit(get_value())

	func _values_match(a: Variant, b: Variant) -> bool:
		if a == b:
			return true
		if (a is int or a is float) and (b is int or b is float):
			return float(a) == float(b)
		return false

class SpinboxValueEditor extends ValueEditor:
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

	func _on_value_changed(value: float) -> void:
		value_changed.emit(value)

class ToggleValueEditor extends ValueEditor:
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

	func _on_toggled(toggled: bool) -> void:
		value_changed.emit(toggled)
