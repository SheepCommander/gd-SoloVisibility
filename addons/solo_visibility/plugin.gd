@tool
extends EditorPlugin
## Solo Visibility
## 
## Shift + H to hide all nodes except selection & children

var HideShortcut: InputEventKey = InputEventKey.new()


func _enter_tree() -> void:
	HideShortcut = preload("res://addons/solo_visibility/hide_nodes_shortcut.tres")
	print("Solo Visibility - Loaded shortcuts")


func _input(event: InputEvent) -> void:
	if (HideShortcut.is_match(event) and event.is_pressed() and !event.is_echo()):
		commit_hide_nodes()


## Hide ##
func commit_hide_nodes():
	var undo_redo = get_undo_redo()
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	var root_node = get_editor_interface().get_edited_scene_root().get_children()
	var currCashID = NextCacheID

	undo_redo.create_action("Hide Non-Selected Nodes")
	undo_redo.add_do_method(self, "hide", root_node, selected, false, currCashID)
	undo_redo.add_undo_method(self, "hide", root_node, selected, true, currCashID)
	undo_redo.commit_action()
	
	NextCacheID += 1

static var cache : Dictionary = {
	#0 : [Node.new(), Node.new()] ## What the dictionary should look like
}
static var NextCacheID : int = 0 ## Used to determine the key for `session`

static func hide(nodes: Array[Node], excluding, undo, cacheID):
	var queue := nodes.duplicate()
	if not undo:
		cache[cacheID] = []

	while queue.size() > 0:
		var node : Node = queue.pop_front()
		if node in excluding:
			continue # Skip iterating over any of the excluded nodes, or their children
		
		if node.has_method("hide"): # Only hide nodes w/ the is_hide property
			if node.visible == false and not undo: # If the node was already hidden before hide() called
				cache[cacheID].append(node)
			node.visible = undo if not node in cache[cacheID] else false
		
		var children = node.get_children()
		queue.append_array(children)
	
	if undo:
		cache[cacheID].clear()


func _exit_tree() -> void:
	NextCacheID = 0
	cache.clear()
