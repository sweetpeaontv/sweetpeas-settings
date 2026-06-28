extends VBoxContainer

@onready var header = $Header
@onready var body = $Body
@onready var tab_bar = $Header/TabBar

var tabs = [
	{ "name": "Gameplay", "scene": preload("res://addons/sweetpeas-settings/components/gameplay/gameplay-settings-panel.tscn") },
	{ "name": "Graphics", "scene": preload("res://addons/sweetpeas-settings/components/graphics/graphics-settings-panel.tscn") },
	{ "name": "Audio",    "scene": preload("res://addons/sweetpeas-settings/components/audio/audio-settings-panel.tscn") },
	{ "name": "Controls", "scene": preload("res://addons/sweetpeas-settings/components/controls/controls-settings-panel.tscn") },
]

var active_tab = 0
var panels: Array[Control] = []

func _ready() -> void:
	for tab in tabs:
		tab_bar.add_tab(tab["name"])
		var panel := tab["scene"].instantiate() as Control
		body.add_child(panel)
		panels.append(panel)
		panel.hide()
	tab_bar.tab_changed.connect(_on_tab_changed)
	body.show()
	_on_tab_changed(active_tab)

func _on_tab_changed(idx: int) -> void:
	panels[active_tab].hide()
	panels[idx].show()
	active_tab = idx
