# Solo Visibility
A [godot 4.x plugin](https://godotengine.org/asset-library/asset/3000) that implements https://github.com/godotengine/godot-proposals/issues/9782.

Use Shift + H to hide all nodes in the current scene except the selected ones.

Use Ctrl + Z (or editor equivalent) to undo. This will restore the previous visibility of nodes before pressing Shift + H.

Once installed Hotkey can be customized via the Godot inspector tab in `res://addons/solo_visibility/hide_nodes_shortcut.tres`

## Download options
(Get the Godot Game Engine here: https://godotengine.org/download/)

1) **From the Asset Library:**
- Look up "Solo Visbility" or click [here](https://godotengine.org/asset-library/asset/3000)

2) Manually:
i. Download the `addons` folder and drag it into your godot project
ii. Enable the plugin in the `Project Settings / Plugin` tab

## Known issues
Disabling the plugin causes `Undo Hide Non-selected Nodes` to break, even if the plugin is re-enabled before attempting to undo. I suspect this is Godot-level and cannot be fixed on the plugin's end.

Please remember to `Undo Hide Non-Selected Nodes` before disabling the plugin.
