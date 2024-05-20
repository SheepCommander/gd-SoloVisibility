# gd-SoloVisibility
A godot 4.x plugin that implements https://github.com/godotengine/godot-proposals/issues/9782.

Use Shift + H to hide all nodes in the current scene except the selected ones.

Use Ctrl + Z to undo. This operation is non-destructive!

Addon is currently [pending on the Godot Asset Library.](https://godotengine.org/asset-library/asset/edit/12163)

## Known issues
Disabling the plugin causes `Undo Hide Non-selected Nodes` to not work, even if you re-enable it before attempting it.

## Change log
### Version 0.2
- Shift + H is no longer a destructive operation! Previous states of nodes are restored.
- Alt + H is removed
