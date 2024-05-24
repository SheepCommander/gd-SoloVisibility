@tool
extends EditorPlugin
## Solo Visibility
## 
## [kbd]Shift + H[/kbd] to hide all nodes except selection & children


## Set to true if the hotkey is activating inside the FileSystem and other unwanted docks.
## If true, the hotkey will stop activating in the Scene dock and will only activate when the 2D or 3D viewports are focused.
@export
var Hotkey_Activates_When_I_Dont_Want_It_To: bool = false
## Screens that the hotkey can be activated in.
@export
var AllowedScreens : Array[String] = [
	"3D",
	"2D",
]
var CurrentMainScreen: String
var HideShortcut: InputEventKey ## Configurable via [code]solo_visibility/hide_nodes_shortcut.tres[/code]
var ShowShortcut: InputEventKey ## @experimental SHOW SHORTCUT IS NOT IMPLEMENTED YET

# --- Virtual functions --- #
func _enter_tree() -> void:
	HideShortcut = preload("res://addons/solo_visibility/hide_nodes_shortcut.tres")
	ShowShortcut = preload("res://addons/solo_visibility/show_nodes_shortcut.tres")
	print("Solo Visibility - Loaded shortcuts")
	
	main_screen_changed.connect(_on_main_screen_changed)


func _input(event: InputEvent) -> void:
	if Hotkey_Activates_When_I_Dont_Want_It_To: # Fallback to _shortcut_input if _input isnt working
		set_process_input(false)
		return
	_solo_visibility_input(event)


func _shortcut_input(event: InputEvent) -> void:
	if Hotkey_Activates_When_I_Dont_Want_It_To: # Fallback to _shortcut_input if _input isnt working
		_solo_visibility_input(event)


func _solo_visibility_input(event: InputEvent):
	if not event is InputEventKey:
		return # Only proceed if the event is an InputEventKey (Does not proceed if InputEventMouseMotion, etc.)
	
	if not (event.is_pressed() and !event.is_echo()):
		return # Only proceed if the event is_pressed() and not is_echo()	
	
	
	if HideShortcut.is_match(event):
		if CurrentMainScreen not in AllowedScreens:
			print("Solo Visibility - Hotkey does not activate when %s screen is open" % CurrentMainScreen)
			return
		commit_hide_nodes()
	
	if ShowShortcut.is_match(event):
		if CurrentMainScreen not in AllowedScreens:
			print("Solo Visibility - Hotkey does not activate when %s screen is open" % CurrentMainScreen)
			return
		


func _exit_tree() -> void:
	pass


func _on_main_screen_changed(screen_name: String):
	CurrentMainScreen = screen_name


# --- Code that handles hiding --- #
## Used as the key for [member HiddenCache]
var NextCacheID : int = 0
## Each key registered corresponds to an [Array] of [Node]s that should stay hidden when [method _undo_hide] is called.
var HiddenCache : Dictionary = {
	#0: [Node, Node2] ## How the cache should look.
}
## Used by [method _] to get the [param dont_hide] used by the last [method commit_hide_nodes] call
var DontHideCache : Dictionary = {
	#0: [Node, Node2] ## How the cache should look.
}
## Use method [EditorUndoRedoManager.get_object_history_id(root_node)] to find a scene's unique ID / key.
## The value corresponding to a key is an [Array] of [int] cacheIDs
## 
## Use [method Array.pop_last()] to find the most recent cacheID of a given scene.
var SceneCache : Dictionary = {
	## SceneID: [cacheID, cacheID, cacheID]
	#2: [0, 1, 3]
	#3: [2, 4]
}


## Handles the execution of the Hide action, as well as registering it in the Editor's UndoRedo system.
## Does nothing if no node is selected.
func commit_hide_nodes() -> void:
	var undo_redo := get_undo_redo()
	
	var root = get_editor_interface().get_edited_scene_root()
	var sceneID : int = undo_redo.get_object_history_id(root)
	var cacheID : int = NextCacheID
	NextCacheID += 1
	
	var selected = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if not selected:
		return
	
	undo_redo.create_action("Hide Non-Selected Nodes", UndoRedo.MERGE_ENDS, root)
	undo_redo.add_do_method(self, "_do_hide", root, selected, cacheID, sceneID)
	undo_redo.add_undo_method(self, "_undo_hide", root, selected, cacheID, sceneID)
	undo_redo.commit_action()


# Private method. Called by [method commit_hide_nodes]
# 
func _do_hide(hide: Node, dont_hide: Array[Node], cacheID: int, sceneID: int) -> void:
	var queue : Array[Node] = hide.get_children()

	HiddenCache[cacheID] = [] # Create array in the cache for first itme
	DontHideCache[cacheID] = dont_hide.duplicate()

	if SceneCache.has(sceneID): # If we already have a key-value pair for this SceneID, then append the new cacheID
		SceneCache[sceneID].append(cacheID)
	else: # Else, create array for first time
		SceneCache[sceneID] = [cacheID]
	
	while queue.size() > 0:
		var node : Node = queue.pop_front()
		
		if node in dont_hide: # Node is an excluded node, no need to check children
			continue
		
		var ignore_node = false # Ignore Node if its a parent of an excluded node
		for excluded_node : Node in dont_hide:
			if node.find_child(excluded_node.name, true):
				ignore_node = true
				break
		
		if node.has_method("hide") and not ignore_node:
			if node.visible == false: # If the node was already hidden before hide() called
				HiddenCache[cacheID].append(node)
			node.visible = false
		
		var children = node.get_children()
		queue.append_array(children)


# Private method. Called by [method commit_hide_nodes]
# 
func _undo_hide(hide: Node, dont_hide: Array, cacheID: int, sceneID: int):
	var queue : Array[Node] = hide.get_children()

	while queue.size() > 0:
		var node : Node = queue.pop_front()
		
		if node in dont_hide: # Node is an excluded node, no need to check children
			continue
		
		var ignore_node = false # Ignore Node if its a parent of an excluded node
		for excluded_node : Node in dont_hide:
			if node.find_child(excluded_node.name, true):
				ignore_node = true
				break
		
		if node.has_method("show") and not ignore_node:
			if not node in HiddenCache[cacheID]:
				node.visible = true
		
		var children = node.get_children()
		queue.append_array(children)
	
	# Clear the cache
	HiddenCache[cacheID].clear()
	SceneCache[sceneID].pop_back()


# @experimental
# Not implemented yet.
func _do_undo_last_hide(root: Node):
	var queue : Array[Node] = root.get_children()
	
	
	
	var ignore = DontHideCache # simulates [param dont_hide]
