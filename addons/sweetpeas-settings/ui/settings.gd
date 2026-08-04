extends VBoxContainer

@onready var header = $Header
@onready var body = $Body
@onready var tab_bar = $Header/TabBar

var _active_tab := 0
var _panels: Array[Control] = []
var _rows: Dictionary = {}

const SETTING_ROW := preload("res://addons/sweetpeas-settings/components/setting-row.tscn")
const SETTINGS_PANEL := preload("res://addons/sweetpeas-settings/components/settings-panel.tscn")

func _ready() -> void:
	for section in SettingsManager.schema.sections:
		_build_section(section)

	if _panels.is_empty():
		return

	tab_bar.tab_changed.connect(_on_tab_changed)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	body.show()
	_on_tab_changed(0)

func _build_section(section: Dictionary) -> void:
	tab_bar.add_tab(section["label"])

	var panel := SETTINGS_PANEL.instantiate()
	panel.name = section["label"] + "SettingsPanel"
	var container: VBoxContainer = panel.get_node("ScrollContainer/VBoxContainer")

	for setting in section["settings"]:
		var key: String = setting["key"]
		var row := SETTING_ROW.instantiate()
		container.add_child(row)
		container.add_child(HSeparator.new())
		row.setup(setting, SettingsManager.get_setting(key))
		row.value_changed.connect(_on_row_value_changed.bind(key))
		_rows[key] = row

	body.add_child(panel)
	_panels.append(panel)
	panel.hide()

# Bound arguments arrive after the signal's own, so the value comes first.
func _on_row_value_changed(value: Variant, key: String) -> void:
	SettingsManager.set_setting(key, value)

# Keeps rows in step with changes made elsewhere, such as a reset.
func _on_setting_changed(key: String, value: Variant) -> void:
	if _rows.has(key):
		_rows[key].set_value(value)

func _on_tab_changed(idx: int) -> void:
	_panels[_active_tab].hide()
	_panels[idx].show()
	_active_tab = idx
