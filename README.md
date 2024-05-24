# Solo Visibility
A [godot 4.x plugin](https://godotengine.org/asset-library/asset/3000) that implements https://github.com/godotengine/godot-proposals/issues/9782.

Use Shift + H to hide all nodes in the current scene except the selected ones.

Use Ctrl + Z (or editor equivalent) to undo. This will restore the previous visibility of nodes before pressing Shift + H.

Hotkey can be customized via the Godot inspector tab in `res://addons/solo_visibility/hide_nodes_shortcut.tres`

## Download options
(Get the Godot Game Engine here: https://godotengine.org/download/)

**From the Asset Library:**
1. Download "Solo Visbility" from the [Asset Store](https://godotengine.org/asset-library/asset/3000)

Manually:
1. Download the `addons` folder and drag it into your godot project
2. Enable the plugin in the `Project Settings / Plugin` tab

## Details
Customization:
- The `Hide Non-Selected Nodes` hotkey is Shift+H by default. It can be changed in `res://addons/solo_visibility/hide_nodes_shortcut.tres`

Where the hotkey can activate:
- Only when the 2D or 3D 'main screens' (the tabs in the top middle) are open
- Only when the 2D Viewport, 3D Viewport, or Scene dock are focused.
	- If you have any of those focused and the hotkey isn't working, please immediately open an Issue! 

## Known issues
1. Disabling the plugin causes `Undo Hide Non-selected Nodes` to break, even if the plugin is re-enabled before attempting to undo. I suspect this is Godot-level and cannot be fixed on the plugin's end.
	- Please remember to `Undo Hide Non-Selected Nodes` before disabling the plugin.
