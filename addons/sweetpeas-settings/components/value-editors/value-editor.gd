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
