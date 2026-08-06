extends MarginContainer

signal reset_requested

var _button: Button

func _ready() -> void:
	_ensure_nodes()
	_button.pressed.connect(_on_pressed)
	refresh_locale()

func _ensure_nodes() -> void:
	if _button != null:
		return
	_button = $Button

func refresh_locale() -> void:
	_ensure_nodes()
	_button.text = tr("reset_section")

func _on_pressed() -> void:
	reset_requested.emit()
