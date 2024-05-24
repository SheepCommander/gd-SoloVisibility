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
var PluginConfig : ConfigFile

var ConfigDictionary : Dictionary = {
	"AllowedScreens": AllowedScreens,
	"Hotkey_Activates_When_I_Dont_Want_It_To": Hotkey_Activates_When_I_Dont_Want_It_To,
}
var AllowedScreens: Array[String] = ["3D","2D"]
var Hotkey_Activates_When_I_Dont_Want_It_To: bool = false


var CurrentMainScreen: String


func _enter_tree() -> void:
	HideShortcut = preload(HIDE_SHORTCUT_PATH)
	ShowShortcut = preload(SHOW_SHORTCUT_PATH)
	
	PluginConfig.load(PLUGIN_CONFIG_PATH)
	for key in ConfigDictionary:
		if not PluginConfig.has_value(PLUGIN_NAME, key):
			PluginConfig.set_value(PLUGIN_NAME, key, ConfigDictionary[key])
		else:
			ConfigDictionary[key] = PluginConfig.get_value(PLUGIN_NAME, key)
	
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
		_solo_visibility_input(event)


func _shortcut_input(event: InputEvent) -> void: # Fallback to _shortcut_input if true
	if Hotkey_Activates_When_I_Dont_Want_It_To:
		_solo_visibility_input(event)


func _solo_visibility_input(event: InputEvent) -> void:
	if not (event.is_pressed() and !event.is_echo()):
		return # Only proceed if the event is_pressed() and not is_echo()
	
	print(get_viewport().gui_get_focus_owner())
	print(EditorInterface.get_base_control().get_window().gui_get_focus_owner())
	
	match HideShortcut.keycode:
		HideShortcut:
			if CurrentMainScreen not in AllowedScreens:
				print("Solo Visibility - Hotkey does not activate when %s screen is open" % CurrentMainScreen)
				return
			commit_hide_nodes()
		ShowShortcut:
			pass


# ==== Implementation Section ==== #
## Handles the Hide Non-Selecteds Nodes action.
## Does nothing if no nodes are selected.
const HIDE_ACTION_NAME = "Hide Non-Selected Nodes"

func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var root : Node = get_editor_interface().get_edited_scene_root()
	var sceneID : int = undo_redo.get_object_history_id(root)
	var cacheID : int = NextCacheID
	NextCacheID += 1
	
	var selected : Array[Node] = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if selected.is_empty():
		return # There are no nodes selected
	
	undo_redo.create_action(HIDE_ACTION_NAME, UndoRedo.MERGE_ENDS, root)
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
	
	# Clear cache? TODO: Consider if this is the right idea..
	# Possibly consider adding another cache instead?
	DontHideCache[cacheID].clear()
	StayHiddenCache[cacheID].clear()
	# Remove this cacheID from the Scene's stack of cacheIDs.
	var lastCacheID = SceneCacheIDs[sceneID].pop_back()
	assert(cacheID == lastCacheID, "Somehow a previous '%s' was Undone instead of the most recent one!" % HIDE_ACTION_NAME)
