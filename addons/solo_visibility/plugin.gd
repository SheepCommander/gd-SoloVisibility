@tool
extends EditorPlugin
## Solo Visibility
## 
## Shift + H to hide all nodes except selection & children

var HideShortcut: InputEventKey
var ShowShortcut: InputEventKey ## SHOW SHORTCUT IS NOT IMPLEMENTED YET

# Virtual functions #
func _enter_tree() -> void:
	HideShortcut = preload("res://addons/solo_visibility/hide_nodes_shortcut.tres")
	ShowShortcut = preload("res://addons/solo_visibility/show_nodes_shortcut.tres")
	print("Solo Visibility - Loaded shortcuts")


func _shortcut_input(event: InputEvent) -> void:
	if (HideShortcut.is_match(event) and event.is_pressed() and !event.is_echo()):
		commit_hide_nodes()

	if (ShowShortcut.is_match(event) and event.is_pressed() and !event.is_echo()):
		pass


func _exit_tree() -> void:
	
	pass


# --- Code that handles hiding --- #
var NextCacheID : int = 0
var HiddenCache : Dictionary = {
	#0: [Node, Node2] ## How the cache should look.
}

var SceneCache : Dictionary = {
	## Use pop_last() to find the most recent cacheID of a given scene.
	## SceneID: [cacheID, cacheID, cacheID]
	#2: [0, 1, 3]
	#3: [2, 4]
}

func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var root = get_editor_interface().get_edited_scene_root()
	var sceneID : int = undo_redo.get_object_history_id(root)
	var cacheID : int = NextCacheID
	NextCacheID += 1
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	
	undo_redo.create_action("Hide Non-Selected Nodes", UndoRedo.MERGE_ENDS, root)
	undo_redo.add_do_method(self, "hide", root.get_children(), selected, false, cacheID, sceneID)
	undo_redo.add_undo_method(self, "hide", root.get_children(), selected, true, cacheID, sceneID)
	undo_redo.commit_action()


func hide(nodes: Array[Node], excluding: Array, undo: bool, cacheID: int, sceneID: int) -> void:
	var queue : Array[Node] = nodes.duplicate()
	if not undo:
		HiddenCache[cacheID] = [] # Add array here if first time
		if SceneCache.has(sceneID):
			SceneCache[sceneID].append(cacheID)
		else:
			SceneCache[sceneID] = [cacheID]
	
	while queue.size() > 0:
		var node : Node = queue.pop_front()
		
		if node in excluding: # Node is an excluded node, no need to check children
			continue
		
		var ignore_node = false # Ignore Node if its a parent of an excluded node
		for excluded_node : Node in excluding:
			if node.find_child(excluded_node.name, true):
				ignore_node = true
				break
		
		if node.has_method("hide") and not ignore_node:
			if not undo and node.visible == false: # If the node was already hidden before hide() called
				HiddenCache[cacheID].append(node)
			node.visible = undo if not node in HiddenCache[cacheID] else false
		
		var children = node.get_children()
		queue.append_array(children)
	
	if undo:
		HiddenCache[cacheID].clear()
