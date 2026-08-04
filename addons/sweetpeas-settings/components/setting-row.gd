extends MarginContainer

signal value_changed(value: Variant)

var _label: Label
var _editor_container: HBoxContainer

var _setting: Dictionary = {}
var _editor: ValueEditor

# INIT
#================================================================================#
func setup(setting: Dictionary, initial_value: Variant = null) -> void:
	_setting = setting
	_resolve_nodes()
	_label.text = setting.get("label", setting.get("key", ""))
	_mount_editor(initial_value)

func _resolve_nodes() -> void:
	if _label != null:
		return
	_label = $SettingRowContainer/NameContainer/Label
	_editor_container = $SettingRowContainer/ValueEditorContainer

func _mount_editor(initial_value: Variant) -> void:
	for child in _editor_container.get_children():
		child.queue_free()
	
	_editor = ValueEditorRegistry.create(_setting.get("type", ""))
	if _editor == null:
		return

	var control := _editor.get_control()
	if control == null:
		push_error("SweetPeas Settings: editor '%s' returned no control" % _setting.get("type", ""))
		return

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_container.add_child(control)
	_editor.setup(_setting)

	if initial_value != null:
		_editor.set_value(initial_value)
	
	_editor.value_changed.connect(_on_editor_value_changed)
#================================================================================#

# API
#================================================================================#
func get_value() -> Variant:
	if _editor:
		return _editor.get_value()
	return null

func set_value(value: Variant) -> void:
	if _editor:
		_editor.set_value(value)
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_editor_value_changed(value: Variant) -> void:
	value_changed.emit(value)
#================================================================================#