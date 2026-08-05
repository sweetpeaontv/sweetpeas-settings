class_name ValueEditor
extends RefCounted

signal value_changed(value: Variant)

func get_control() -> Control:
	return null

func setup(_setting: Dictionary) -> void:
	push_error("ValueEditor: setup not implemented")

func get_value() -> Variant:
	return null

func set_value(_value: Variant) -> void:
	pass

func set_disabled(disabled: bool) -> void:
	var control := get_control()
	if control == null:
		return
	if "disabled" in control:
		control.disabled = disabled
		return
	control.modulate.a = 0.45 if disabled else 1.0
	control.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	)
