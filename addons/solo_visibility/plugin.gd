@tool
extends EditorPlugin
## Solo Visibility
## 
## Shift + H to hide all nodes except selection & children

var HideShortcut: InputEventKey


# Virtual functions #
func _enter_tree() -> void:
	HideShortcut = preload("res://addons/solo_visibility/hide_nodes_shortcut.tres")
	print("Solo Visibility - Loaded shortcuts")


func _handles(object: Object) -> bool:
	return true # Tells Godot to pass inputs to the below methods.


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if (HideShortcut.is_match(event) and event.is_pressed() and !event.is_echo()):
		commit_hide_nodes()
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if (HideShortcut.is_match(event) and event.is_pressed() and !event.is_echo()):
		commit_hide_nodes()
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _exit_tree() -> void:
	NextCacheID = 0
	cache.clear()


# Hiding functions #
func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	var root = get_editor_interface().get_edited_scene_root()
	var root_nodes = root.get_children()
	var currCashID = NextCacheID
	
	# MERGE_ENDS seems to make it so if Shift+H is spammed, Undo only has to be pressed once.
	# root is passed to make sure the UndoRedo context is Scene, rather than Global.
	undo_redo.create_action("Hide Non-Selected Nodes", UndoRedo.MERGE_ENDS, root)
	# Do
	undo_redo.add_do_method(self, "hide", root_nodes, selected, false, currCashID)
	# Undo
	undo_redo.add_undo_method(self, "hide", root_nodes, selected, true, currCashID)
	# Commit. Executions the do actions.
	undo_redo.commit_action()
	# Move to next cache slot
	NextCacheID += 1


var cache : Dictionary = { ## Keeps track of nodes that remain hidden after Undo is called
	#0 : [node, node2] ## Example of what the dictionary should look like
}
var NextCacheID : int = 0 ## Used to determine the key for `cache`


func hide(nodes: Array[Node], excluding, undo, cacheID) -> void:
	var queue := nodes.duplicate()
	if not undo:
		cache[cacheID] = []

	while queue.size() > 0:
		var node : Node = queue.pop_front()
		if node in excluding:
			continue # Skip iterating over any of the excluded nodes, or their children
		
		if node.has_method("hide"): # Only hide nodes w/ the is_hide property
			if not undo and node.visible == false: # If the node was already hidden before hide() called
				cache[cacheID].append(node)
			node.visible = undo if not node in cache[cacheID] else false
		
		var children = node.get_children()
		queue.append_array(children)
	
	if undo:
		cache[cacheID].clear()
