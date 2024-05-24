@tool
extends EditorPlugin
## Solo Visibility
## [kbd]Shift + H[/kbd] to hide all nodes except selection & children
## [kbd]Alt + H[/kbd] to reveal all nodes except selection & children

var HideShortcut: InputEventKey
var ShowShortcut: InputEventKey

var CurrentMainScreen: String

#
var PluginConfig : ConfigFile

var AllowedScreens: Array[String] = ["3D","2D"]
## Set to true in [code]plugin.cfg[/code] if the hotkey activates when you dont want it to
var Hotkey_Activates_When_I_Dont_Want_It_To: bool = false


func _enter_tree() -> void:
	HideShortcut = preload("res://addons/solo_visibility/hide_nodes_shortcut.tres")
	ShowShortcut = preload("res://addons/solo_visibility/show_nodes_shortcut.tres")
	
	PluginConfig.load("res://addons/solo_visibility/plugin.cfg")
	AllowedScreens = PluginConfig.get_value("Solo Visibility", "AllowedScreens")
	Hotkey_Activates_When_I_Dont_Want_It_To = PluginConfig.get_value("Solo Visibility", "Hotkey_Activates_When_I_Dont_Want_It_To")
	
	set_process_input(true)
	if Hotkey_Activates_When_I_Dont_Want_It_To:
		set_process_input(false)
	
	main_screen_changed.connect(_on_main_screen_changed)


func _exit_tree() -> void:
	pass


func _on_main_screen_changed(screen_name: String) -> void:
	CurrentMainScreen = screen_name


func _input(event: InputEvent) -> void:
	if not Hotkey_Activates_When_I_Dont_Want_It_To: # Use _input if false
		_solo_visibility_hotkeys(event)


func _shortcut_input(event: InputEvent) -> void: # Fallback to _shortcut_input if true
	if Hotkey_Activates_When_I_Dont_Want_It_To:
		_solo_visibility_hotkeys(event)


func _solo_visibility_hotkeys(event: InputEvent) -> void:
	if not (event.is_pressed() and !event.is_echo()):
		return # Only proceed if the event is_pressed() and not is_echo()	
	
	if HideShortcut.is_match(event):
		if CurrentMainScreen not in AllowedScreens:
			print("Solo Visibility - Hotkey does not activate when %s screen is open" % CurrentMainScreen)
			return


# ==== Implementation Section ==== #
var NextCacheID : int = 0

func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var root : Node = get_editor_interface().get_edited_scene_root()
	var sceneID : int = undo_redo.get_object_history_id(root)
	var cacheID : int = NextCacheID
	NextCacheID += 1
	
	var selected : Array[Node] = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if not selected:
		return # There are no nodes selected
	
	undo_redo.create_action("Hide Non-Selected Nodes", UndoRedo.MERGE_ENDS, root)
	undo_redo.add_do_method(self, "_do_hide", root, selected, cacheID, sceneID)
	undo_redo.add_undo_method(self, "_undo_hide", root, selected, cacheID, sceneID)
	undo_redo.commit_action()



