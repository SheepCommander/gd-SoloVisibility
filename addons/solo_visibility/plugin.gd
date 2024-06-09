@tool
extends EditorPlugin
## Solo Visibility
## [kbd]Shift + H[/kbd] to hide all nodes except selection & children
## [kbd]Alt + H[/kbd] to reveal all nodes except selection & children

@onready var HideShortcut: InputEventKey = load("res://addons/solo_visibility/hide_nodes_shortcut.tres")
@onready var ShowShortcut: InputEventKey = load("res://addons/solo_visibility/show_nodes_shortcut.tres")

const PLUGIN_CONFIG_PATH = "res://addons/solo_visibility/plugin.cfg"
const PLUGIN_NAME = "Solo Visibility"
var Config := ConfigFile.new()

var AllowedScreens : Array[String] = ["3D","2D"]
var AllowedFocuses : Array[String] = ["SceneTreeEditor", "Node3DEditorViewport", "CanvasItemEditorViewport"]
var ConfigDictionary : Dictionary = {
	"AllowedScreens": AllowedScreens,
	"AllowedFocuses": AllowedFocuses,
}

var current_main_screen: String = "" # Default val prevents null errors


func _ready(): # _enter_tree is too early and will cause errors.
	Config.load(PLUGIN_CONFIG_PATH)
	for key in ConfigDictionary:
		if not Config.has_section_key(PLUGIN_NAME, key):
			Config.set_value(PLUGIN_NAME, key, ConfigDictionary[key])
		else:
			if ConfigDictionary[key] is Array:
				ConfigDictionary[key].assign(Config.get_value(PLUGIN_NAME, key))
			else:
				ConfigDictionary[key] = Config.get_value(PLUGIN_NAME, key)
	Config.save(PLUGIN_CONFIG_PATH)
	
	main_screen_changed.connect(_on_main_screen_changed)


func _on_main_screen_changed(screen_name: String) -> void:
	current_main_screen = screen_name


func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not (event.is_pressed() and !event.is_echo()): return
	if current_main_screen not in AllowedScreens: return
	# Proceed if is_pressed and not is_echo, & is in AllowedScreens
	
	var focus := EditorInterface.get_base_control().get_window().gui_get_focus_owner()
	if focus == null:
		return # Editor isnt focused, do nothing
	if focus.get_class() not in AllowedFocuses:
		if focus.get_parent().get_class() not in AllowedFocuses:
			return # UNSTABLE: internal name/hierarchy changes will break logic
	
	match event.keycode:
		HideShortcut.keycode:
			get_viewport().set_input_as_handled()
			commit_hide_nodes()
		ShowShortcut.keycode:
			get_viewport().set_input_as_handled()
			commit_show_nodes()


# ==== Implementation Section ==== #
const HIDE_ACTION_NAME = "Hide Non-Selected Nodes"
const SHOW_ACTION_NAME = "Show Non-Selected Nodes"
const STAY_HIDDEN : StringName = "SoloVisibility_StaysHidden"
var NextCacheID : int = 1

## Handles the Hide Non-Selected Nodes action.
## Does nothing if no nodes are selected.
func commit_hide_nodes() -> void:
	var selected : Array[Node] = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if selected.is_empty():
		return # There are no nodes selected
	
	var root : Node = get_editor_interface().get_edited_scene_root()
	var cacheID := NextCacheID
	NextCacheID += 1
	
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action(HIDE_ACTION_NAME, UndoRedo.MERGE_DISABLE, root) # root for local context
	undo_redo.add_do_method(self, "_do_hide", root, selected, cacheID)
	undo_redo.add_undo_method(self, "_undo_hide", root, selected, cacheID)
	undo_redo.commit_action()
## Handles the Show Non-Selected Nodes action.
## Does nothing if no nodes are selected.
func commit_show_nodes() -> void:
	var selected : Array[Node] = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if selected.is_empty():
		return # There are no nodes selected
	print("show")
	var root : Node = get_editor_interface().get_edited_scene_root()
	var cacheID := NextCacheID
	NextCacheID += 1
	
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action(SHOW_ACTION_NAME, UndoRedo.MERGE_DISABLE, root) # root for local context
	undo_redo.add_do_method(self, "_undo_hide", root, selected, cacheID)
	undo_redo.add_undo_method(self, "_do_hide", root, selected, cacheID)
	undo_redo.commit_action()


# Private method. Called by [method commit_hide_nodes]
func _do_hide(root: Node, selection: Array[Node], cacheID: int) -> void:
	var queue : Array[Node] = root.get_children()
	while queue.size() > 0:
		var node : Node = queue.pop_back()
		if node in selection:
			continue # Node is selected, dont hide
		
		var is_parent := false
		for selected_node : Node in selection:
			var selected_path := str(root.get_path_to(selected_node))
			if selected_path.begins_with(str(root.get_path_to(node)))\
						and not node.get_parent() == selected_node.get_parent():
				is_parent = true # [node] has [selected_node] as a child.
				break
		
		if not is_parent and node.has_method("hide"):
			if node.visible == false:
				node.set_meta(STAY_HIDDEN+str(cacheID), true)
				#print("%s is prev hidden" % node)
			node.visible = false
		
		queue.append_array(node.get_children())


# Private method. Called by [method commit_hide_nodes]
func _undo_hide(root: Node, selection: Array[Node], cacheID: int) -> void:
	var queue : Array[Node] = root.get_children()
	while queue.size() > 0:
		var node : Node = queue.pop_back()
		if node in selection:
			continue # Node is selected, dont hide
		
		var is_parent := false
		for selected_node : Node in selection:
			var selected_path := str(root.get_path_to(selected_node))
			if selected_path.begins_with(str(root.get_path_to(node)))\
						and not node.get_parent() == selected_node.get_parent():
				is_parent = true # [node] has [selected_node] as a child.
				break
		
		if not is_parent and node.has_method("hide"):
			if not node.has_meta(STAY_HIDDEN+str(cacheID)):
				node.visible = true
			node.remove_meta(STAY_HIDDEN+str(cacheID))
		
		queue.append_array(node.get_children())
