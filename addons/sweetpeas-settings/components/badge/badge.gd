class_name SweetBadge
extends Button

const _SIZE: Vector2 = Vector2(22, 22)
const _ICON_SIZE: Vector2 = Vector2(14, 14)
const _LABEL_Y_NUDGE: float = -2.0
const _STYLE_NAMES: Array[StringName] = [
	&"normal",
	&"hover",
	&"pressed",
	&"disabled",
	&"focus",
]

var _content: Control
var _icon: TextureRect
var _label: Label

var _text: String = ""
var _texture: Texture2D = null
var _panel_style: StyleBoxFlat = null
var _font_color: Color = Color.BLACK

# INIT
#================================================================================#
func _ready() -> void:
	_ensure_nodes()
	_apply_disabled()
	_refresh_content()

func _get_minimum_size() -> Vector2:
	return _SIZE

func _ensure_nodes() -> void:
	if _icon != null:
		return

	custom_minimum_size = _SIZE
	size = _SIZE
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	text = ""
	flat = false

	_content = $Content
	_icon = $Content/Icon
	_label = $Content/Label

	var base_style := get_theme_stylebox("normal")
	if base_style is StyleBoxFlat:
		_panel_style = (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
	else:
		_panel_style = StyleBoxFlat.new()
		_panel_style.bg_color = Color.WHITE
		_panel_style.set_corner_radius_all(100)
		_panel_style.set_border_width_all(1)
		_panel_style.border_color = Color.BLACK
	for style_name in _STYLE_NAMES:
		add_theme_stylebox_override(style_name, _panel_style)

	var bold := SystemFont.new()
	bold.font_weight = 800
	_label.add_theme_font_override("font", bold)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_constant_override("line_spacing", 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font_color()
#================================================================================#

# API
#================================================================================#
func set_content_text(text: String) -> void:
	_ensure_nodes()
	_text = text
	_refresh_content()

func get_content_text() -> String:
	return _text

func set_content_icon(texture: Texture2D) -> void:
	_ensure_nodes()
	_texture = texture
	_refresh_content()

func get_content_icon() -> Texture2D:
	return _texture

func set_badge_visible(is_visible: bool) -> void:
	visible = is_visible

func set_tooltip(text: String) -> void:
	tooltip_text = text

func set_background_color(color: Color) -> void:
	_ensure_nodes()
	if _panel_style == null:
		return
	_panel_style.bg_color = color

func get_background_color() -> Color:
	_ensure_nodes()
	if _panel_style == null:
		return Color.WHITE
	return _panel_style.bg_color

func set_font_color(color: Color) -> void:
	_ensure_nodes()
	_font_color = color
	_apply_font_color()

func get_font_color() -> Color:
	return _font_color

func set_disabled(is_disabled: bool) -> void:
	_ensure_nodes()
	disabled = is_disabled
	_apply_disabled()

func is_disabled() -> bool:
	return disabled
#================================================================================#

# INTERNAL
#================================================================================#
func _refresh_content() -> void:
	_ensure_nodes()

	custom_minimum_size = _SIZE
	size = _SIZE

	var has_icon := _texture != null
	_icon.texture = _texture
	_icon.visible = has_icon
	_icon.custom_minimum_size = _ICON_SIZE

	_label.text = _text
	_label.visible = not has_icon and not _text.is_empty()
	call_deferred("_apply_label_nudge")

func _apply_font_color() -> void:
	if _label == null:
		return
	_label.add_theme_color_override("font_color", _font_color)

func _apply_label_nudge() -> void:
	if _label == null or not is_instance_valid(_label) or not _label.visible:
		return
	# CenterContainer lays out first; shift the glyph optically upward.
	_label.position = Vector2(_label.position.x, _label.position.y + _LABEL_Y_NUDGE)

func _apply_disabled() -> void:
	modulate.a = 0.45 if disabled else 1.0
#================================================================================#
