class_name SectionComponentRegistry
extends RefCounted

const _CONTROL_HEADER = preload("uid://cdvy1chp7018j")
const _SECTION_RESET = preload("uid://ddxhm51xmo4un")

static var _components: Dictionary = {}

static func create(type: String) -> Control:
	_ensure_components()

	var scene: Variant = _components.get(type)
	if scene == null:
		push_error("Sweetpea's Settings: unknown section component '%s'" % type)
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
		"section_reset": _SECTION_RESET,
	}
