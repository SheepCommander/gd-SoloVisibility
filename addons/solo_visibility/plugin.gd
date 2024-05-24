@tool
extends EditorPlugin
## Solo Visibility
## [kbd]Shift + H[/kbd] to hide all nodes except selection & children
## [kbd]Alt + H[/kbd] to reveal all nodes except selection & children

const HIDE_SHORTCUT_PATH = "res://addons/solo_visibility/hide_nodes_shortcut.tres"
const SHOW_SHORTCUT_PATH = "res://addons/solo_visibility/show_nodes_shortcut.tres"
var HideShortcut: InputEventKey
var ShowShortcut: InputEventKey

const PLUGIN_CONFIG_PATH = "res://addons/solo_visibility/plugin.cfg"
const PLUGIN_NAME = "Solo Visibility"
var PluginConfig := ConfigFile.new()

var AllowedScreens: Array[String] = ["3D","2D"]
var AllowedFocuses : Array[String] = ["SceneTreeEditor", "Node3DEditorViewport", "CanvasItemEditorViewport"]
var ConfigDictionary : Dictionary = {
	"AllowedScreens": AllowedScreens,
	"AllowedFocuses": AllowedFocuses,
}

var CurrentMainScreen: String


func _enter_tree() -> void:
	set_process_input(false) # Prevent startup "Cannot access <property> on null" errors
	
	HideShortcut = preload(HIDE_SHORTCUT_PATH)
	ShowShortcut = preload(SHOW_SHORTCUT_PATH)
	
	PluginConfig.load(PLUGIN_CONFIG_PATH)
	for key in ConfigDictionary:
		if not PluginConfig.has_section_key(PLUGIN_NAME, key):
			PluginConfig.set_value(PLUGIN_NAME, key, ConfigDictionary[key])
		else:
			if ConfigDictionary[key] is Array:
				ConfigDictionary[key].assign(PluginConfig.get_value(PLUGIN_NAME, key))
			else:
				ConfigDictionary[key] = PluginConfig.get_value(PLUGIN_NAME, key)
	PluginConfig.save(PLUGIN_CONFIG_PATH)
	
	main_screen_changed.connect(_on_main_screen_changed)


func _ready():
	set_process_input(true) # Resume input after Godot has presumably finished startup


func _exit_tree() -> void:
	pass


func _on_main_screen_changed(screen_name: String) -> void:
	CurrentMainScreen = screen_name


func _input(event: InputEvent) -> void:
	_solo_visibility_input(event)


func _solo_visibility_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not (event.is_pressed() and !event.is_echo()):
		return # Only proceed if the event is_pressed() and not is_echo()
	
	var focus = EditorInterface.get_base_control().get_window().gui_get_focus_owner()
	if focus.get_class() not in AllowedFocuses and focus.get_parent().get_class() not in AllowedFocuses:
		return # WARNING: Unstable if internal classes are renamed or focus is not (/a direct child of) the internal class
	
	match event.keycode:
		HideShortcut.keycode:
			if CurrentMainScreen not in AllowedScreens:
				print("%s - Hotkey does not activate when %s screen is open" % [PLUGIN_NAME, CurrentMainScreen])
				return
			commit_hide_nodes()
		ShowShortcut.keycode:
			pass


# ==== Implementation Section ==== #
const HIDE_ACTION_NAME = "Hide Non-Selected Nodes"

## Handles the Hide Non-Selecteds Nodes action.
## Does nothing if no nodes are selected.
func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var root : Node = get_editor_interface().get_edited_scene_root()
	var sceneID : int = undo_redo.get_object_history_id(root)
	var cacheID : int = NextCacheID
	NextCacheID += 1
	
	var selected : Array[Node] = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if selected.is_empty():
		return # There are no nodes selected
	
	undo_redo.create_action(HIDE_ACTION_NAME, UndoRedo.MERGE_ENDS, root) # Pass root for local context
	undo_redo.add_do_method(self, "_do_hide", root, selected, cacheID, sceneID)
	undo_redo.add_undo_method(self, "_undo_hide", root, selected, cacheID, sceneID)
	undo_redo.commit_action()


## Used as key for [member StayHiddenCache]
var NextCacheID : int = 0
## Stack (LIFO) of last-used CacheID in a given Scene. Use [method Array.pop_last]
var SceneCacheIDs : Dictionary = {
	#SceneID-int: [CacheID-int, CacheID-int]
}
## Cache of already-hidden nodes that should stay hidden on Undo Hide Non-Selected Nodes
var StayHiddenCache : Dictionary = {
	#CacheID-int: [AlreadyHiddenNode, AlreadyHiddenNode2]
}
## Cache [method _do_hide]'s [param dont_hide] for future use.
var DontHideCache : Dictionary = {
	#CacheID-int: [SelectedNode, SelectedNode2]
}

# Private method. Called by [method commit_hide_nodes]
func _do_hide(root: Node, dont_hide: Array[Node], cacheID: int, sceneID: int) -> void:
	# Initiate/Add arrays to cache
	StayHiddenCache[cacheID] = []
	DontHideCache[cacheID] = dont_hide.duplicate()
	
	if not SceneCacheIDs.has(sceneID):
		SceneCacheIDs[sceneID] = [] # Initiate new cache under this scene if it doesnt exist
	SceneCacheIDs[sceneID].append(cacheID) # Append cacheID to scene's list of cacheIDs
	
	# Handle hiding
	var queue : Array[Node] = root.get_children()
	
	while queue.size() > 0:
		var node : Node = queue.pop_front()
		
		if node in dont_hide: # Node is an excluded node, no need to check children
			continue
		
		var ignore_node = false
		for excluded_node : Node in dont_hide:
			if node.find_child(excluded_node.name, true):
				ignore_node = true
				break
		
		if not ignore_node and node.has_method("hide"):
			if node.visible == false: # Node is already hidden
				StayHiddenCache[cacheID].append(node) # Append to cache
			node.visible = false
		
		queue.append_array(node.get_children()) # Add node's children to the queue

# Private method. Called by [method commit_hide_nodes]
func _undo_hide(root: Node, dont_hide: Array[Node], cacheID: int, sceneID: int) -> void:
	var queue : Array[Node] = root.get_children()
	while queue.size() > 0:
		var node : Node = queue.pop_front()
		
		if node in dont_hide: # Node was an excluded node, no need to check children
			continue
		
		var ignore_node = false # Ignore Node if its a parent of an excluded node
		for excluded_node : Node in dont_hide:
			if node.find_child(excluded_node.name, true):
				ignore_node = true
				break
		
		if not ignore_node and node.has_method("show"):
			if not node in StayHiddenCache[cacheID]:
				node.visible = true # Only show node if it was not Hidden pre-Do Hide Non-Selected Nodes
		
		var children = node.get_children()
		queue.append_array(children)
	
	# Clear cache
	DontHideCache[cacheID].clear()
	StayHiddenCache[cacheID].clear()
	# Remove this cacheID from the Scene's stack of cacheIDs.
	var lastCacheID = SceneCacheIDs[sceneID].pop_back()
	assert(cacheID == lastCacheID, "Somehow a previous '%s' was Undone instead of the most recent one!" % HIDE_ACTION_NAME)
