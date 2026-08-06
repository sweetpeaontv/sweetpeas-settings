class_name SweetValueEditorRegistry
extends RefCounted

const _BasicValueEditors = preload("uid://caeaywoy7mnum")
const _NumericSliderValueEditor = preload("uid://d1jnobpv1vgva")
const _KeybindValueEditor = preload("uid://btyx6v1ufw6c6")
static var _editors: Dictionary = {}

static func create(type: String) -> SweetValueEditor:
	_ensure_editors()

	var editor_class: Variant = _editors.get(type)
	if editor_class == null:
		push_error("Sweetpea's Settings: unknown value editor type '%s'" % type)
		return null

	return editor_class.new()

static func register(type: String, editor_class: Variant) -> void:
	_ensure_editors()
	_editors[type] = editor_class

static func _ensure_editors() -> void:
	if not _editors.is_empty():
		return

	_editors = {
		"slider": _BasicValueEditors.SliderValueEditor,
		"option": _BasicValueEditors.OptionValueEditor,
		"spinbox": _BasicValueEditors.SpinboxValueEditor,
		"toggle": _BasicValueEditors.ToggleValueEditor,
		"numeric_slider": _NumericSliderValueEditor,
		"keybind": _KeybindValueEditor,
	}
