class_name KeybindValueEditor
extends ValueEditor

const KEYBIND_SCENE := preload(
	"res://addons/sweetpeas-settings/components/value-editors/keybind/keybind.tscn"
)

var _keybind: KeybindEditor

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

func _on_value_changed(value: Dictionary) -> void:
	value_changed.emit(value)
