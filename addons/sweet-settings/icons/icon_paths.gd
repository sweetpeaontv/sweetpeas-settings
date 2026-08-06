# icon_paths.gd
# Builds res:// paths into the icon set and loads them.
#
# Sits below icons.gd and the icon maps so both can use it without a cycle:
# icons.gd dispatches an InputEvent to a map, and the maps come back here to
# turn a folder plus filename into a texture.
extends RefCounted

const AddonPaths = preload("uid://jls0ogr3p8a3")

static func join(subdir: String, file: String) -> String:
	if subdir.is_empty() or file.is_empty():
		return ""
	return AddonPaths.ICONS_ROOT.path_join(subdir).path_join(file)

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
