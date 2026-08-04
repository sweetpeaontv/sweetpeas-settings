class_name SectionComponentRegistry
extends RefCounted

const _CONTROL_HEADER := preload(
	"res://addons/sweetpeas-settings/components/control-header.tscn"
)

static var _components: Dictionary = {}

static func create(type: String) -> Control:
	_ensure_components()

	var scene: Variant = _components.get(type)
	if scene == null:
		push_error("SweetPeas Settings: unknown section component '%s'" % type)
		return null

	return scene.instantiate() as Control

static func register(type: String, scene: PackedScene) -> void:
	_ensure_components()
	_components[type] = scene

static func _ensure_components() -> void:
	if not _components.is_empty():
		return

	_components = {
		"control_header": _CONTROL_HEADER,
	}
