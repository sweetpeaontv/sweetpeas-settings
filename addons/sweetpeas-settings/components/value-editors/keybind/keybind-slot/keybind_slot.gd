class_name KeybindSlot
extends Control
"""
One keybind cell in the row - shows the icon or label, waiting state, clear badge, and conflict tint.
"""

## Theme color: KeybindSlot / conflict_icon_modulate (fallback yellow).

signal pressed
signal clear_pressed

const _DEFAULT_CONFLICT_MODULATE: Color = Color(1.0, 0.85, 0.2, 1.0)
const _SLOT_MIN_SIZE: Vector2 = Vector2(72, 40)
const _ICON_SIZE: Vector2 = Vector2(40, 40)
const _WAITING_TEXT: String = "..."

var _icon_button: IconButton

var _listening: bool = false
var _conflicted: bool = false
var _conflict_tooltip: String = ""
var _signals_connected: bool = false

# INIT
#================================================================================#
func _ready() -> void:
	_ensure_nodes()
	_connect_signals()

func _ensure_nodes() -> void:
	if _icon_button != null:
		return

	custom_minimum_size = _SLOT_MIN_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = false

	_icon_button = $IconButton as IconButton
	if _icon_button != null:
		_icon_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_icon_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_icon_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_icon_button.set_icon_size(_ICON_SIZE)

func _connect_signals() -> void:
	if _signals_connected:
		return
	_ensure_nodes()
	if _icon_button == null:
		return
	if not _icon_button.pressed.is_connected(_on_icon_pressed):
		_icon_button.pressed.connect(_on_icon_pressed)
	if not _icon_button.badge_pressed.is_connected(_on_badge_pressed):
		_icon_button.badge_pressed.connect(_on_badge_pressed)
	_signals_connected = true
#================================================================================#

# API
#================================================================================#
func set_display(texture: Texture2D, text: String) -> void:
	_ensure_nodes()
	_icon_button.set_icon(texture)
	_icon_button.set_text(text)

func set_listening(listening: bool) -> void:
	_ensure_nodes()
	_listening = listening
	if listening:
		_icon_button.set_icon(_waiting_texture())
		_icon_button.set_text(_WAITING_TEXT)
		_icon_button.set_badge_icon(null)
		_icon_button.set_badge_text("x")
		_icon_button.set_badge_background_color(Color(0.86, 0.2, 0.2))
		_icon_button.set_badge_font_color(Color.BLACK)
		_icon_button.set_badge_tooltip("Clear binding")
		_icon_button.set_badge_visible(true)
	else:
		_icon_button.set_badge_visible(false)
	_apply_conflict_visuals()

func set_conflicted(conflicted: bool, tooltip: String = "") -> void:
	_ensure_nodes()
	_conflicted = conflicted
	_conflict_tooltip = tooltip
	_apply_conflict_visuals()

func set_disabled(disabled: bool) -> void:
	_ensure_nodes()
	_icon_button.set_disabled(disabled)

func is_clear_badge_at(global_pos: Vector2) -> bool:
	_ensure_nodes()
	if _icon_button == null:
		return false
	var badge: Badge = _icon_button.get_badge()
	if badge == null or not badge.visible:
		return false
	return badge.get_global_rect().has_point(global_pos)
#================================================================================#

# INTERNAL
#================================================================================#
func _waiting_texture() -> Texture2D:
	return Icons.load_texture(Icons.join("keyboard-mouse", "keyboard_any.svg"))

func _conflict_modulate() -> Color:
	# Themes can override: theme type "KeybindSlot", color name "conflict_icon_modulate".
	if has_theme_color("conflict_icon_modulate", "KeybindSlot"):
		return get_theme_color("conflict_icon_modulate", "KeybindSlot")
	return _DEFAULT_CONFLICT_MODULATE

func _apply_conflict_visuals() -> void:
	_ensure_nodes()
	if _conflicted and not _listening:
		_icon_button.set_icon_modulate(_conflict_modulate())
		_icon_button.tooltip_text = _conflict_tooltip
	else:
		_icon_button.set_icon_modulate(Color.WHITE)
		_icon_button.tooltip_text = ""
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_icon_pressed() -> void:
	pressed.emit()

func _on_badge_pressed() -> void:
	clear_pressed.emit()
#================================================================================#
