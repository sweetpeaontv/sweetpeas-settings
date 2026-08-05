# settings_i18n.gd
# Loads the addon's CSV translations at runtime so host projects do not need a
# separate import step for Sweetpea's Settings strings.
class_name SettingsI18n
extends RefCounted

const CSV_PATH := "res://addons/sweetpeas-settings/i18n/sweetpeas-settings.csv"

static func load_translations() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		push_warning("Sweetpea's Settings: translation CSV missing at '%s'." % CSV_PATH)
		return

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("Sweetpea's Settings: failed to open '%s'." % CSV_PATH)
		return

	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2:
		push_error("Sweetpea's Settings: '%s' needs a keys column and at least one locale." % CSV_PATH)
		return

	var translations: Dictionary = {}
	for column in range(1, header.size()):
		var locale := str(header[column]).strip_edges()
		if locale.is_empty():
			continue
		var translation := Translation.new()
		translation.locale = locale
		translations[locale] = translation

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue

		var key := str(row[0]).strip_edges()
		if key.is_empty():
			continue

		for column in range(1, header.size()):
			var locale := str(header[column]).strip_edges()
			if locale.is_empty() or not translations.has(locale):
				continue
			var message := str(row[column]) if column < row.size() else ""
			translations[locale].add_message(StringName(key), StringName(message))

	for locale in translations:
		TranslationServer.add_translation(translations[locale])
