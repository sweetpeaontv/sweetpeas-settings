# settings_i18n.gd
# Loads the addon's imported .translation resources at runtime so host projects
# pick up Sweetpea's Settings strings without a separate locale setup step.
class_name SweetSettingsI18n
extends RefCounted

const I18N_DIR := "res://addons/sweetpeas-settings/i18n/"

static func load_translations() -> void:
	var dir := DirAccess.open(I18N_DIR)
	if dir == null:
		push_warning("Sweetpea's Settings: translation folder missing at '%s'." % I18N_DIR)
		return

	var loaded_any := false
	for file_name in dir.get_files():
		if not file_name.ends_with(".translation"):
			continue

		var path := I18N_DIR.path_join(file_name)
		var translation := load(path) as Translation
		if translation == null:
			push_warning("Sweetpea's Settings: failed to load translation '%s'." % path)
			continue

		TranslationServer.add_translation(translation)
		loaded_any = true

	if not loaded_any:
		push_warning("Sweetpea's Settings: no .translation files found in '%s'." % I18N_DIR)
