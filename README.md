# Solo Visibility
A godot 4.x plugin that implements https://github.com/godotengine/godot-proposals/issues/9782.

Use Shift + H to hide all nodes in the current scene except the selected ones.

Use Ctrl + Z (or editor equivalent) to undo. This will restore the previous visibility of nodes before pressing Shift + H.

Once installed Hotkey can be customized via the Godot inspector tab in `res://addons/solo_visibility/hide_nodes_shortcut.tres`

Addon is currently [pending on the Godot Asset Library.](https://godotengine.org/asset-library/asset)

## Downloading
1. Extract and open Godot Engine: https://godotengine.org/download/
2. Download the `addons` folder and drag it into your godot project
3. Enable the plugin in the `Project Settings / Plugin` tab

Download from the Asset Library is still pending

## Known issues
Disabling the plugin causes `Undo Hide Non-selected Nodes` to break, even if the plugin is re-enabled before attempting to undo. I suspect this is Godot-level and cannot be fixed on the plugin's end.

Please remember to undo the Hide Non-Selected Nodes operation before disabling the plugin.
