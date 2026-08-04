# Sweetpea's Settings

An open source, drop-in settings menu for Godot games.

It ships with the settings most games already need — language, sensitivity, resolution, display mode, VSync, FPS cap, volume sliders, and keybinds — and is built to be extended. Use it as-is to get a working menu quickly, or treat it as a jumping-off point and reshape it for your project.

---

## Features

- **Ready-made defaults** for gameplay, graphics, audio, and controls
- **Schema-driven UI** — settings are defined in JSON, not hardcoded
- **Automatic keybinds** — Input Map actions are parsed into editable bindings
- **Simple, themeable UI** — style it with Godot themes, or swap/edit the scenes yourself
- **Autoload on enable** — enabling the plugin registers `SettingsManager` for you

---

## Installation

### From GitHub

1. Download or clone this repo
2. Copy `addons/sweetpeas-settings` into your project's `addons/` folder
3. In **Project → Project Settings → Plugins**, enable **Sweetpea's Settings**

### From the Asset Library

1. Open **AssetLib** in the Godot editor
2. Search for **Sweetpea's Settings**
3. Download and install, then enable the plugin under **Project → Project Settings → Plugins**

Once enabled, the plugin adds the `SettingsManager` autoload. Instance `res://addons/sweetpeas-settings/ui/settings.tscn` wherever you want the menu (pause screen, options button, etc.).

---

## Schema shape

Settings are defined in JSON under `addons/sweetpeas-settings/config/`. The shipped defaults live in `default_schema.json` — peek there for a full working example. The shape itself looks like this:

```json
{
	"version": 1.0,
	"sections": [
		{
			"id": "...",
			"label": "...",
			"settings_source": "...",
			"exclude_prefixes": [],
			"header": [],
			"footer": [],
			"settings": [
				{
					"key": "...",
					"type": "...",
					"default": ...,
					"min": ...,
					"max": ...,
					"step": ...,
					"options": {},
					"disabled_when": {}
				},
				{
					"type": "...",
					"default": ...,
					"keys": ["...", "..."]
				}
			]
		}
	]
}
```

### Top level

| Field | Meaning |
|-------|---------|
| `version` | Schema version number. |
| `sections` | Array of tabs. Order here is tab order in the UI. |

### Section

Each section is one tab.

| Field | Meaning |
|-------|---------|
| `id` | Section id. Tab label is humanized from this unless `label` is set. Also used for i18n. |
| `label` | Optional display name override for the tab. |
| `settings` | Array of setting dictionaries for this tab. |
| `settings_source` | Optional injector. `"input_map"` pulls Project Settings Input Map actions in as keybinds. |
| `exclude_prefixes` | Optional. With `input_map`, skip actions whose names start with these prefixes. |
| `header` / `footer` | Optional extra UI components above/below the setting rows. |

### Setting

Each entry in `settings` becomes one or more rows.

| Field | Meaning |
|-------|---------|
| `key` | Id for a single setting. One row, one stored value. Display text is `tr(key)` unless overridden. |
| `keys` | Batch of ids that share this entry's other fields. Expands into separate settings at load (e.g. several volume sliders from one dict). Use instead of `key`. |
| `type` | Which editor to show (see below). |
| `default` | Starting value before the player changes anything. |
| `min` / `max` / `step` | Range/step for numeric types (`numeric_slider`, `spinbox`). |
| `options` | Choices for `option` types — a `{ "Label": value }` map or a list of values. |
| `disabled_when` | Optional. Disable this setting when another setting's value is in the given list. |

Use `key` for one-offs. Use `keys` when several settings share the same shape.

### Built-in types

| Type | Control |
|------|---------|
| `toggle` | On/off checkbox |
| `option` | Dropdown |
| `spinbox` | Numeric spin box |
| `numeric_slider` | Slider (supports display scaling / suffix) |
| `keybind` | Rebindable input (also injected from the Input Map) |

---

## Extending the settings

### Edit the default schema

The built-in list lives at:

```
addons/sweetpeas-settings/config/default_schema.json
```

Tweak sections, keys, defaults, ranges, and options to match your game.

### Override with your own schema

Drop another `.json` file into the same `config/` folder. At runtime, any custom schema takes priority over `default_schema.json` (if several custom files exist, the first alphabetically wins).

That lets you keep the addon updatable while defining your own settings shape without editing the shipped default.

### Auto keybinds from the Input Map

Add actions in **Project → Project Settings → Input Map**. The controls section uses `"settings_source": "input_map"`, so those actions are injected as editable keybinds automatically — no schema entries required per action.

Use `exclude_prefixes` on that section if you want to hide engine/internal actions.

---

## Styling & customization

The UI is intentionally simple: tabs, rows, and value editors. It is meant to get you running, not lock you into one look.

- Apply a **Theme** to the settings scene (or a parent) to restyle controls
- Edit or replace the scenes under `ui/` and `components/` to change layout and behavior
- Wire custom appliers via `SettingsManager` when a setting needs to affect your own systems

Use it as a drop-in if that is enough. Dig into the scenes and schema when you want something more game-specific.

---

## Default sections

| Section    | Examples                                      |
|------------|-----------------------------------------------|
| Gameplay   | Language, mouse sensitivity                   |
| Graphics   | Resolution, display mode, VSync, max FPS      |
| Audio      | Master / music / SFX / UI volume              |
| Controls   | Keybinds from your project's Input Map        |

---

## License

MIT — see [LICENSE](LICENSE).
