class_name LevelManager extends Node

signal load_started(loading_screen: LoadingScreen)
signal scene_added(loaded_scene: Node, loading_screen: LoadingScreen)
signal load_completed(loaded_scene: Node)

signal _content_finished_loading(content)
signal _content_invalid(level_path: String)
signal _content_failed_to_load(level_path: String)

var _loading_screen_scene: PackedScene = preload("res://scenes/ui/loading_screen.tscn")
var _loading_screen: LoadingScreen

var _load_progress_timer: Timer
var _loading_in_progress: bool = false

var _levels: Array[PackedScene] = []
var _current_level_index: int = 0
var _current_level_node: Node = null
var _new_level_index: int = 0
var _new_level_path: String = ""

var _tree: SceneTree = null
var _root: Node = null


func init(levels: Array[PackedScene], tree: SceneTree) -> void:
  _levels = levels
  _tree = tree
  _root = tree.root

  _content_invalid.connect(_on_content_invalid)
  _content_failed_to_load.connect(_on_content_failed_to_load)
  _content_finished_loading.connect(_on_content_finished_loading)


func change_level(level_index: int, transition_type: String = "fade_to_black") -> void:
  if _loading_in_progress:
    push_warning("LevelManager is already loading something")
    return

  if _levels[level_index] == null:
    printerr("Error: Level index '%s' doesn't exist" % [level_index])
    return

  if level_index == -1:
    _new_level_index = _current_level_index # Reload current level
  else:
    _new_level_index = level_index

  _loading_in_progress = true
  _new_level_path = _levels[_new_level_index].resource_path

  await _add_loading_screen(transition_type)
  _load_level(_new_level_path)


func _load_level(level_path: String) -> void:
  load_started.emit(_loading_screen)
  var loader = ResourceLoader.load_threaded_request(level_path)

  if not ResourceLoader.exists(level_path) or loader == null:
    _content_invalid.emit(level_path)
    return

  _load_progress_timer = Timer.new()
  _load_progress_timer.wait_time = 0.1
  _load_progress_timer.timeout.connect(_monitor_load_status)

  _root.add_child(_load_progress_timer)
  _load_progress_timer.start()


func _monitor_load_status() -> void:
  var load_progress: Array = []
  var load_status = ResourceLoader.load_threaded_get_status(_new_level_path, load_progress)

  match load_status:
    ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
      _content_invalid.emit(_new_level_path)
      _load_progress_timer.stop()
      return

    ResourceLoader.THREAD_LOAD_IN_PROGRESS:
      if _loading_screen != null:
        _loading_screen.update_bar(load_progress[0] * 100)

    ResourceLoader.THREAD_LOAD_FAILED:
      _content_failed_to_load.emit(_new_level_path)
      _load_progress_timer.stop()
      return

    ResourceLoader.THREAD_LOAD_LOADED:
      _load_progress_timer.stop()
      _load_progress_timer.queue_free()
      _content_finished_loading.emit(ResourceLoader.load_threaded_get(_new_level_path).instantiate())


func _on_content_failed_to_load(path: String) -> void:
  printerr("Error: Failed to load resource: '%s'" % [path])


func _on_content_invalid(path: String) -> void:
  printerr("Error: Cannot load resource: '%s'" % [path])


func _on_content_finished_loading(incoming_level: Node) -> void:
  var outgoing_level: Node = _current_level_node

  if outgoing_level != null:
    if outgoing_level.has_method("pass_data") and incoming_level.has_method("receive_data"):
      incoming_level.receive_data(outgoing_level.pass_data())

  _root.add_child(incoming_level)
  _root.move_child(incoming_level, 0) # Position on bottom layer (first child)

  scene_added.emit(incoming_level, _loading_screen)

  # Remove whichever scene existed when the game was initially run. This will differ
  # depending on whether the "Run Project" or "Run Current Scene" button was clicked.
  if _tree != null:
    _tree.unload_current_scene()

  if _current_level_node != null and _current_level_node != _root:
    _current_level_node.queue_free()

  if incoming_level.has_method("init_scene"):
    incoming_level.init_scene()

  if _loading_screen != null:
    _loading_screen.finish_transition()
    await _loading_screen.anim_player.animation_finished

  if incoming_level.has_method("start_scene"):
    incoming_level.start_scene()

  _loading_in_progress = false
  _current_level_index = _new_level_index
  _current_level_node = incoming_level
  load_completed.emit(incoming_level)


func _add_loading_screen(transition_type: String = "fade_to_black"):
  _loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
  _root.add_child(_loading_screen)
  _root.move_child(_loading_screen, -1) # Position on top layer (last child)
  _loading_screen.start_transition(transition_type)

  await _loading_screen.anim_player.animation_finished
  # Alternatively, could also use:
  # await _loading_screen.transition_in_complete
