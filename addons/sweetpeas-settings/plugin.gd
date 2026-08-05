@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "SettingsManager"
const AUTOLOAD_PATH: String = "res://addons/sweetpeas-settings/core/settings_manager.gd"

func _enable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _disable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		return

	var entry: String = ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME)
	if _normalize_autoload_path(entry) == AUTOLOAD_PATH:
		remove_autoload_singleton(AUTOLOAD_NAME)

func _normalize_autoload_path(entry: String) -> String:
	var path: String = entry.trim_prefix("*").strip_edges()
	if not path.begins_with("uid://"):
		return path

	var uid: int = ResourceUID.text_to_id(path)
	if uid == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid):
		return path
	return ResourceUID.get_id_path(uid)
