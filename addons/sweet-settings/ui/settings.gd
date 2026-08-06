extends VBoxContainer

const SETTINGS_PANEL = preload("uid://14pcikrgghwh")
const SETTING_ROW = preload("uid://c2cbsjwqa83i")

@onready var header = $Header
@onready var body = $Body
@onready var tab_bar = $Header/TabBar

var _active_tab := 0
var _panels: Array[Control] = []
var _rows: Dictionary = {}
var _sections: Array[Dictionary] = []
# section_id -> header/footer controls from the schema
var _section_components: Dictionary = {}

# INIT
#================================================================================#
func _ready() -> void:
	for section in SweetSettings.schema.sections:
		_build_section(section)

	if _panels.is_empty():
		return

	tab_bar.tab_changed.connect(_on_tab_changed)
	SweetSettings.setting_changed.connect(_on_setting_changed)
	_refresh_disabled_states()
	_refresh_keybind_conflicts()
	body.show()
	_on_tab_changed(0)
#================================================================================#

# BUILD
#================================================================================#
func _build_section(section: Dictionary) -> void:
	_sections.append(section)
	tab_bar.add_tab(_section_title(section))

	var panel := SETTINGS_PANEL.instantiate()
	panel.name = str(section["id"]) + "SettingsPanel"
	var container: VBoxContainer = panel.get_node("ScrollContainer/VBoxContainer")
	var section_id: String = section["id"]
	var slot_controls: Array[Control] = []

	var header_controls := _create_section_components(section.get("header", []))
	_append_section_components(container, header_controls)
	if not header_controls.is_empty():
		container.add_child(HSeparator.new())
	slot_controls.append_array(header_controls)

	var settings: Array = section["settings"]
	for i in settings.size():
		var setting: Dictionary = settings[i]
		var key: String = setting["key"]
		var row := SETTING_ROW.instantiate()
		container.add_child(row)

		if i < settings.size() - 1:
			container.add_child(HSeparator.new())

		row.setup(setting, SweetSettings.get_setting(key))
		row.value_changed.connect(_on_row_value_changed.bind(key))
		_rows[key] = row

	var footer_controls := _create_section_components(section.get("footer", []))
	if not footer_controls.is_empty():
		container.add_child(HSeparator.new())
		_append_section_components(container, footer_controls)
	slot_controls.append_array(footer_controls)

	_section_components[section_id] = slot_controls
	_wire_section_reset_footers(section_id, footer_controls)

	body.add_child(panel)
	_panels.append(panel)
	panel.hide()

func _create_section_components(components: Array) -> Array[Control]:
	var controls: Array[Control] = []
	for component in components:
		if not component is Dictionary:
			continue
		var control := SweetSectionComponentRegistry.create(str(component.get("type", "")))
		if control == null:
			continue
		controls.append(control)
	return controls

func _append_section_components(container: VBoxContainer, controls: Array[Control]) -> void:
	for i in controls.size():
		container.add_child(controls[i])
		if i < controls.size() - 1:
			container.add_child(HSeparator.new())

func _wire_section_reset_footers(section_id: String, footer_controls: Array[Control]) -> void:
	for control in footer_controls:
		if not control.has_signal("reset_requested"):
			continue
		control.connect("reset_requested", _on_section_reset_requested.bind(section_id))
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_row_value_changed(value: Variant, key: String) -> void:
	SweetSettings.set_setting(key, value)

func _on_section_reset_requested(section_id: String) -> void:
	SweetSettings.reset_section(section_id)

func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "language":
		_refresh_localized_text()
	if _rows.has(key):
		_rows[key].set_value(value)
	_refresh_disabled_states()
	if _is_keybind_setting(key):
		_refresh_keybind_conflicts()

func _on_tab_changed(idx: int) -> void:
	_panels[_active_tab].hide()
	_panels[idx].show()
	_active_tab = idx
#================================================================================#

# REFRESH
#================================================================================#
func _refresh_keybind_conflicts() -> void:
	var conflicts := SweetSettings.get_keybind_conflicts()
	for key in _rows:
		var row = _rows[key]
		if row.has_method("refresh_keybind_conflicts"):
			row.refresh_keybind_conflicts(conflicts)

func _is_keybind_setting(key: String) -> bool:
	if not SweetSettings.schema.has_key(key):
		return false
	return str(SweetSettings.schema.get_setting(key).get("type", "")) == "keybind"

func _refresh_localized_text() -> void:
	for index in _sections.size():
		tab_bar.set_tab_title(index, _section_title(_sections[index]))
	for key in _rows:
		_rows[key].refresh_locale()
	for section_id in _section_components:
		for control in _section_components[section_id]:
			if control.has_method("refresh_locale"):
				control.refresh_locale()
	_refresh_keybind_conflicts()

func _refresh_disabled_states() -> void:
	for key in _rows:
		_rows[key].set_disabled(_is_setting_disabled(key))
#================================================================================#

# HELPERS
#================================================================================#
func _is_setting_disabled(key: String) -> bool:
	var setting: Dictionary = SweetSettings.schema.get_setting(key)
	var conditions: Variant = setting.get("disabled_when", {})
	if not conditions is Dictionary or (conditions as Dictionary).is_empty():
		return false

	for dep_key in conditions:
		var current: Variant = SweetSettings.get_setting(str(dep_key))
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
#================================================================================#
