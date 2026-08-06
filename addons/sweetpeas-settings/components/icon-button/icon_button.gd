class_name SweetIconButton
extends Control

signal pressed
signal badge_pressed

const _ICON_SIZE := Vector2(28, 28)

var _button: Button
var _content: MarginContainer
var _icon: TextureRect
var _label: Label
var _badge: SweetBadge

var _text := "—"
var _texture: Texture2D = null
var _icon_modulate := Color.WHITE
var _icon_size := _ICON_SIZE
var _signals_connected := false

# INIT
#================================================================================#
func _enter_tree() -> void:
	_ensure_nodes()
	_connect_signals()

func _ready() -> void:
	_ensure_nodes()
	_connect_signals()
	_refresh_content()

func _ensure_nodes() -> void:
	if _button != null:
		return

	custom_minimum_size = Vector2(40, 40)
	clip_contents = false

	_button = $Button
	_content = $Button/Content as MarginContainer
	_icon = $Button/Content/Center/Icon
	_label = $Button/Content/Center/Label
	_badge = $Badge as SweetBadge

	if _badge != null:
		_badge.set_badge_visible(false)

func _connect_signals() -> void:
	if _signals_connected:
		return
	if _button == null:
		_ensure_nodes()
	if _button == null:
		return
	if not _button.pressed.is_connected(_on_button_pressed):
		_button.pressed.connect(_on_button_pressed)
	if _badge != null and not _badge.pressed.is_connected(_on_badge_pressed):
		_badge.pressed.connect(_on_badge_pressed)
	_signals_connected = true
#================================================================================#

# API
#================================================================================#
func set_icon(texture: Texture2D) -> void:
	_ensure_nodes()
	_texture = texture
	_refresh_content()

func get_icon() -> Texture2D:
	return _texture

func set_text(text: String) -> void:
	_ensure_nodes()
	_text = text
	_refresh_content()

func get_text() -> String:
	return _text

func set_disabled(disabled: bool) -> void:
	_ensure_nodes()
	_button.disabled = disabled

func is_disabled() -> bool:
	_ensure_nodes()
	return _button.disabled

func set_icon_modulate(color: Color) -> void:
	_ensure_nodes()
	_icon_modulate = color
	_apply_icon_modulate()

func get_icon_modulate() -> Color:
	return _icon_modulate

func set_icon_size(size: Vector2) -> void:
	_ensure_nodes()
	_icon_size = size
	_refresh_content()

func get_icon_size() -> Vector2:
	return _icon_size

func set_content_margins(margin: int) -> void:
	_ensure_nodes()
	_content.add_theme_constant_override("margin_left", margin)
	_content.add_theme_constant_override("margin_top", margin)
	_content.add_theme_constant_override("margin_right", margin)
	_content.add_theme_constant_override("margin_bottom", margin)
#================================================================================#

# BADGE
#================================================================================#
func set_badge_text(text: String) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_content_text(text)

func set_badge_icon(texture: Texture2D) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_content_icon(texture)

func set_badge_visible(is_visible: bool) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_badge_visible(is_visible)

func set_badge_tooltip(text: String) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_tooltip(text)

func set_badge_background_color(color: Color) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_background_color(color)

func set_badge_font_color(color: Color) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_font_color(color)

func set_badge_disabled(disabled: bool) -> void:
	_ensure_nodes()
	if _badge == null:
		return
	_badge.set_disabled(disabled)

func get_badge() -> SweetBadge:
	_ensure_nodes()
	return _badge
#================================================================================#

# INTERNAL
#================================================================================#
func _refresh_content() -> void:
	_ensure_nodes()

	var has_icon := _texture != null
	_icon.texture = _texture
	_icon.visible = has_icon
	_icon.custom_minimum_size = _icon_size

	_label.text = _text
	_label.visible = not has_icon
	_apply_icon_modulate()

func _apply_icon_modulate() -> void:
	_icon.modulate = _icon_modulate
	_label.modulate = _icon_modulate
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_button_pressed() -> void:
	pressed.emit()

func _on_badge_pressed() -> void:
	badge_pressed.emit()
#================================================================================#
