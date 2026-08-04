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
	_refresh_disabled_states()
	body.show()
	_on_tab_changed(0)

func _build_section(section: Dictionary) -> void:
	_sections.append(section)
	tab_bar.add_tab(_section_title(section))

	var panel := SETTINGS_PANEL.instantiate()
	panel.name = str(section["id"]) + "SettingsPanel"
	var container: VBoxContainer = panel.get_node("ScrollContainer/VBoxContainer")

	var header_controls := _create_section_components(section.get("header", []))
	_append_section_components(container, header_controls)
	if not header_controls.is_empty():
		container.add_child(HSeparator.new())

	var settings: Array = section["settings"]
	for i in settings.size():
		var setting: Dictionary = settings[i]
		var key: String = setting["key"]
		var row := SETTING_ROW.instantiate()
		container.add_child(row)

		if i < settings.size() - 1:
			container.add_child(HSeparator.new())

		row.setup(setting, SettingsManager.get_setting(key))
		row.value_changed.connect(_on_row_value_changed.bind(key))
		_rows[key] = row

	var footer_controls := _create_section_components(section.get("footer", []))
	if not footer_controls.is_empty():
		container.add_child(HSeparator.new())
		_append_section_components(container, footer_controls)

	body.add_child(panel)
	_panels.append(panel)
	panel.hide()

func _create_section_components(components: Array) -> Array[Control]:
	var controls: Array[Control] = []
	for component in components:
		if not component is Dictionary:
			continue
		var control := SectionComponentRegistry.create(str(component.get("type", "")))
		if control == null:
			continue
		controls.append(control)
	return controls

func _append_section_components(container: VBoxContainer, controls: Array[Control]) -> void:
	for i in controls.size():
		container.add_child(controls[i])
		if i < controls.size() - 1:
			container.add_child(HSeparator.new())

func _on_row_value_changed(value: Variant, key: String) -> void:
	SettingsManager.set_setting(key, value)

func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "language":
		_refresh_localized_text()
	if _rows.has(key):
		_rows[key].set_value(value)
	_refresh_disabled_states()

func _refresh_localized_text() -> void:
	for index in _sections.size():
		tab_bar.set_tab_title(index, _section_title(_sections[index]))
	for key in _rows:
		_rows[key].refresh_locale()

func _refresh_disabled_states() -> void:
	for key in _rows:
		_rows[key].set_disabled(_is_setting_disabled(key))

func _is_setting_disabled(key: String) -> bool:
	var setting: Dictionary = SettingsManager.schema.get_setting(key)
	var conditions: Variant = setting.get("disabled_when", {})
	if not conditions is Dictionary or (conditions as Dictionary).is_empty():
		return false

	for dep_key in conditions:
		var current: Variant = SettingsManager.get_setting(str(dep_key))
		var expected: Variant = conditions[dep_key]
		if expected is Array:
			if not _value_matches_any(current, expected):
				return false
		elif not _values_match(current, expected):
			return false
	return true

func _value_matches_any(value: Variant, expected_values: Array) -> bool:
	for expected in expected_values:
		if _values_match(value, expected):
			return true
	return false

func _values_match(a: Variant, b: Variant) -> bool:
	if a == b:
		return true
	if (a is int or a is float) and (b is int or b is float):
		return float(a) == float(b)
	return false

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
