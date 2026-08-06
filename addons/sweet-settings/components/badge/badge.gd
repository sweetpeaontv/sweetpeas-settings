extends Button

const _SIZE: Vector2 = Vector2(22, 22)
const _ICON_SIZE: Vector2 = Vector2(36, 36)

var _content: Control
var _icon: TextureRect

var _texture: Texture2D = null

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
#================================================================================#

# API
#================================================================================#
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

func _apply_disabled() -> void:
	modulate.a = 0.45 if disabled else 1.0
#================================================================================#
