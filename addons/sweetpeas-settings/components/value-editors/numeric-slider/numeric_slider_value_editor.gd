class_name SweetNumericSliderValueEditor
extends SweetValueEditor

const NUMERIC_SLIDER = preload("uid://dg4olttlxhj0j")

var _numeric_slider: SweetNumericSlider

func _init() -> void:
	_numeric_slider = NUMERIC_SLIDER.instantiate()
	_numeric_slider.value_changed.connect(_on_value_changed)

func get_control() -> Control:
	return _numeric_slider

func setup(setting: Dictionary) -> void:
	_numeric_slider.configure(setting)

func get_value() -> Variant:
	return _numeric_slider.get_value()

func set_value(value: Variant) -> void:
	_numeric_slider.set_value(float(value))

func _on_value_changed(value: float) -> void:
	value_changed.emit(value)
