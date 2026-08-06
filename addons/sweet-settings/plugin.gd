@tool
extends EditorPlugin

const AddonPaths = preload("uid://jls0ogr3p8a3")

const AUTOLOAD_NAME: String = "SweetSettings"

func _enable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AddonPaths.AUTOLOAD_SCRIPT)
		return

	var entry: String = ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME)
	if _normalize_autoload_path(entry) == AddonPaths.AUTOLOAD_SCRIPT:
		return

	push_error(
		"Sweetpea's Settings: an autoload named '%s' already exists and points at '%s'. Rename or remove it, then re-enable the plugin."
		% [AUTOLOAD_NAME, entry]
	)

func _disable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		return

	var entry: String = ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME)
	if _normalize_autoload_path(entry) == AddonPaths.AUTOLOAD_SCRIPT:
		remove_autoload_singleton(AUTOLOAD_NAME)

func _normalize_autoload_path(entry: String) -> String:
	var path: String = entry.trim_prefix("*").strip_edges()
	if not path.begins_with("uid://"):
		return path

	var uid: int = ResourceUID.text_to_id(path)
	if uid == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid):
		return path
	return ResourceUID.get_id_path(uid)
