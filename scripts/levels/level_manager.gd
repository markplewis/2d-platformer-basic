class_name LevelManager extends Node

signal load_started(loading_screen: LoadingScreen) ## Triggered when an asset begins loading
signal scene_added(loaded_scene: Node, loading_screen: LoadingScreen) ## Triggered right after asset is added to SceneTree but before transition animation finishes
signal load_completed(loaded_scene: Node) ## Triggered when loading has completed

signal _content_finished_loading(content) ## Triggered when content is loaded and final data handoff and transition out begins
signal _content_invalid(content_path: String) ## Triggered when attempting to load invalid content (e.g. an asset does not exist or path is incorrect)
signal _content_failed_to_load(content_path: String) ## Triggered when loading has started but failed to complete

var _loading_screen_scene: PackedScene = preload("res://scenes/ui/loading_screen.tscn") ## Reference to loading screen PackedScene
var _loading_screen: LoadingScreen ## Reference to loading screen instance

var _load_progress_timer: Timer ## Timer used to check in on load progress if left [code]null[/null]
var _scene_to_unload: Node = null ## Node we're unloading. In almost all cases, SceneManager will be used to swap between two scenes - after all that it the primary focus. However, passing in [code]null[/code] for the scene to unload will skip the unloading process and simply add the new scene. This isn't recommended, as it can have some adverse affects depending on how it is used, but it does work. Use with caution :)
var _loading_in_progress: bool = false ## Used to block SceneManager from attempting to load two things at the same time

var _root: Node = null
var _current_scene_node: Node = null
var _current_scene_path: String = "" ## Stores the path to the asset that SceneManager is trying to load


func init(root_node: Node) -> void:
  _root = root_node # get_tree().root
  #_main = _root.get_child(_root.get_child_count() - 1) # Last child
  #_level_container = _main.get_node("LevelContainer")
  #_current_scene_node = _level_container.get_child(0)
  #_current_scene_path = _current_scene_node.scene_file_path

  _content_invalid.connect(_on_content_invalid)
  _content_failed_to_load.connect(_on_content_failed_to_load)
  _content_finished_loading.connect(_on_content_finished_loading)


func swap_scenes(scene_to_load: String, transition_type: String = "fade_to_black") -> void:
  if _loading_in_progress:
    push_warning("SceneManager is already loading something")
    return

  _loading_in_progress = true
  _scene_to_unload = _current_scene_node

  var reload_current_scene: bool = scene_to_load == ""

  if not reload_current_scene:
    _current_scene_path = scene_to_load

  await _add_loading_screen(transition_type)
  _load_content(_current_scene_path)


func _add_loading_screen(transition_type: String = "fade_to_black"):
  _loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
  _root.add_child(_loading_screen)
  _root.move_child(_loading_screen, -1) # Position on top layer (last child)
  _loading_screen.start_transition(transition_type)

  await _loading_screen.anim_player.animation_finished
  # Alternatively, could also use:
  # await _loading_screen.transition_in_complete


func _load_content(content_path: String) -> void:
  load_started.emit(_loading_screen)

  var loader = ResourceLoader.load_threaded_request(content_path)

  if not ResourceLoader.exists(content_path) or loader == null:
    _content_invalid.emit(content_path)
    return

  _load_progress_timer = Timer.new()
  _load_progress_timer.wait_time = 0.1
  _load_progress_timer.timeout.connect(_monitor_load_status)

  _root.add_child(_load_progress_timer)
  _load_progress_timer.start()


func _monitor_load_status() -> void:
  var load_progress = []
  var load_status = ResourceLoader.load_threaded_get_status(_current_scene_path, load_progress)

  match load_status:
    ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
      _content_invalid.emit(_current_scene_path)
      _load_progress_timer.stop()
      return
    ResourceLoader.THREAD_LOAD_IN_PROGRESS:
      if _loading_screen != null:
        _loading_screen.update_bar(load_progress[0] * 100)
    ResourceLoader.THREAD_LOAD_FAILED:
      _content_failed_to_load.emit(_current_scene_path)
      _load_progress_timer.stop()
      return
    ResourceLoader.THREAD_LOAD_LOADED:
      _load_progress_timer.stop()
      _load_progress_timer.queue_free()
      _content_finished_loading.emit(ResourceLoader.load_threaded_get(_current_scene_path).instantiate())


## Fires when content has begun loading but failed to complete
func _on_content_failed_to_load(path: String) -> void:
  printerr("error: Failed to load resource: '%s'" % [path])


## Fires when attempting to load invalid content (e.g. content does not exist or path is incorrect)
func _on_content_invalid(path: String) -> void:
  printerr("error: Cannot load resource: '%s'" % [path])


## Fires when content is done loading. This is responsible for data transfer, adding the
## incoming scene removing the outgoing scene, halting the game until the out transition finishes,
## and also fires off the signals you can listen for to manage the SceneTree as things are added
func _on_content_finished_loading(incoming_scene: Node) -> void:
  var outgoing_scene: Node = _scene_to_unload

  if outgoing_scene != null:
    if outgoing_scene.has_method("pass_data") and incoming_scene.has_method("receive_data"):
      incoming_scene.receive_data(outgoing_scene.pass_data())

  _root.add_child(incoming_scene)
  _root.move_child(incoming_scene, 0) # Position on bottom layer (first child)

  scene_added.emit(incoming_scene, _loading_screen)

  if _scene_to_unload != null and _scene_to_unload != _root:
    _scene_to_unload.queue_free()

  if incoming_scene.has_method("init_scene"):
    incoming_scene.init_scene()

  if _loading_screen != null:
    _loading_screen.finish_transition()
    await _loading_screen.anim_player.animation_finished

  if incoming_scene.has_method("start_scene"):
    incoming_scene.start_scene()

  _loading_in_progress = false
  _current_scene_node = incoming_scene
  load_completed.emit(incoming_scene)
