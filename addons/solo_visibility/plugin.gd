@tool
extends EditorPlugin
## Solo Visibility
## 
## Shift + H to hide all nodes except selection & children
## Alt + H to show all nodes except selection & children


func _enter_tree() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_H:
					if event.alt_pressed:
						commit_show_nodes()
					if event.shift_pressed:
						commit_hide_nodes()


func commit_hide_nodes():
	var undo_redo = get_undo_redo()
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	var root_node = get_editor_interface().get_edited_scene_root().get_children()

	undo_redo.create_action("Hide Non-Selected Nodes")
	undo_redo.add_do_method(self, "hide", root_node, selected, true)
	undo_redo.add_undo_method(self, "hide", root_node, selected, false)
	undo_redo.commit_action()


func commit_show_nodes():
	var undo_redo = get_undo_redo()
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	var root_node = get_editor_interface().get_edited_scene_root().get_children()

	undo_redo.create_action("Show Non-Selected Nodes")
	undo_redo.add_do_method(self, "hide", root_node, selected, false)
	undo_redo.add_undo_method(self, "hide", root_node, selected, true)
	undo_redo.commit_action()


static func hide(nodes: Array[Node], excluding, is_hide=true):
	var queue := nodes.duplicate()
	while queue.size() > 0:
		var node : Node = queue.pop_front()
		if node in excluding:
			continue # Skip iterating over any of the excluded nodes, or their children
		
		if node.has_method("hide"): # Only hide nodes w/ the is_hide property
			node.visible = !is_hide
		
		var children = node.get_children()
		queue.append_array(children)


func _exit_tree() -> void:
	pass
