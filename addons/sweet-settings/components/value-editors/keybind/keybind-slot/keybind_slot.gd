extends Control
"""
One keybind cell in the row - shows the icon or label, waiting state, clear badge, and conflict tint.
"""

const Badge = preload("uid://com2f7n6m5csr")
const IconButton = preload("uid://f3a6m7hpwk6d")
const IconPaths = preload("uid://cxwurn6qv7ral")

signal pressed
signal clear_pressed

# Theme type for the addon's own properties. Users style Sweetpea's Settings by
# adding entries under this type in their Theme.
const THEME_TYPE := &"SweetSettings"

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
		_icon_button.set_badge_tooltip(tr("clear_binding"))
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
	return IconPaths.load_texture(IconPaths.join("keyboard-mouse", "keyboard_any.svg"))

func _apply_conflict_visuals() -> void:
	_ensure_nodes()
	if _conflicted and not _listening:
		_icon_button.set_icon_modulate(
			get_theme_color("conflict_icon_modulate", THEME_TYPE)
		)
		_icon_button.set_tooltip(_conflict_tooltip)
	else:
		_icon_button.set_icon_modulate(Color.WHITE)
		_icon_button.set_tooltip("")
#================================================================================#

# SIGNAL HANDLERS
#================================================================================#
func _on_icon_pressed() -> void:
	pressed.emit()

func _on_badge_pressed() -> void:
	clear_pressed.emit()
#================================================================================#
