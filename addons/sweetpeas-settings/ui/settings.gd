extends VBoxContainer

@onready var header = $Header
@onready var body = $Body
@onready var tab_bar = $Header/TabBar

var _active_tab := 0
var _panels: Array[Control] = []
var _rows: Dictionary = {}
var _sections: Array[Dictionary] = []

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
	_sections.append(section)
	tab_bar.add_tab(_section_title(section))

	var panel := SETTINGS_PANEL.instantiate()
	panel.name = str(section["id"]) + "SettingsPanel"
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

func _on_row_value_changed(value: Variant, key: String) -> void:
	SettingsManager.set_setting(key, value)

func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "language":
		_refresh_localized_text()
	if _rows.has(key):
		_rows[key].set_value(value)

func _refresh_localized_text() -> void:
	for index in _sections.size():
		tab_bar.set_tab_title(index, _section_title(_sections[index]))
	for key in _rows:
		_rows[key].refresh_locale()

func _section_title(section: Dictionary) -> String:
	var id := str(section.get("id", ""))
	var translated := tr(id)
	if translated != id:
		return translated
	return str(section.get("label", id))

func _on_tab_changed(idx: int) -> void:
	_panels[_active_tab].hide()
	_panels[idx].show()
	_active_tab = idx
