class_name ValueEditorRegistry
extends RefCounted

const _BasicValueEditors := preload(
	"res://addons/sweetpeas-settings/components/value-editors/basic-value-editors.gd"
)
const _NumericSliderValueEditor := preload(
	"res://addons/sweetpeas-settings/components/value-editors/numeric-slider/numeric-slider-value-editor.gd"
)
const _KeybindValueEditor := preload(
	"res://addons/sweetpeas-settings/components/value-editors/keybind/keybind-value-editor.gd"
)

static var _editors: Dictionary = {}

static func create(type: String) -> ValueEditor:
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
