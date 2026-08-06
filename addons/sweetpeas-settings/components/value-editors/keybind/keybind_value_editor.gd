class_name SweetKeybindValueEditor
extends SweetValueEditor

const KEYBIND_SCENE = preload("uid://74rotn6prfqv")

var _keybind: SweetKeybindEditor

func _init() -> void:
	_keybind = KEYBIND_SCENE.instantiate()
	_keybind.value_changed.connect(_on_value_changed)

func get_control() -> Control:
	return _keybind

func setup(setting: Dictionary) -> void:
	_keybind.configure(setting)

func get_value() -> Variant:
	return _keybind.get_value()

func set_value(value: Variant) -> void:
	_keybind.set_value(value)

func set_conflicts(conflicts: Dictionary) -> void:
	_keybind.set_conflicts(conflicts)

func set_disabled(disabled: bool) -> void:
	_keybind.set_disabled(disabled)

func _on_value_changed(value: Dictionary) -> void:
	value_changed.emit(value)
