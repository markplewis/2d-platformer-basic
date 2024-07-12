extends Node

signal load_start(loading_screen) ## Triggered when an asset begins loading
signal scene_added(loaded_scene: Node, loading_screen) ## Triggered right after asset is added to SceneTree but before transition animation finishes
signal load_complete(loaded_scene: Node) ## Triggered when loading has completed

signal _content_finished_loading(content) ## Triggered when content is loaded and final data handoff and transition out begins
signal _content_invalid(content_path: String) ## Triggered when attempting to load invalid content (e.g. an asset does not exist or path is incorrect)
signal _content_failed_to_load(content_path: String) ## Triggered when loading has started but failed to complete

var _loading_screen_scene: PackedScene = preload("res://scenes/loading_screen.tscn") ## Reference to loading screen PackedScene
var _loading_screen: LoadingScreen ## Reference to loading screen instance

var _transition: String ## Transition being used for current load
var _load_progress_timer: Timer ## Timer used to check in on load progress
var _load_scene_into: Node ## Node into which we're loading the new scene, defaults to [code]get_tree().root[/code] if left [code]null[/null]
var _scene_to_unload: Node ## Node we're unloading. In almost all cases, SceneManager will be used to swap between two scenes - after all that it the primary focus. However, passing in [code]null[/code] for the scene to unload will skip the unloading process and simply add the new scene. This isn't recommended, as it can have some adverse affects depending on how it is used, but it does work. Use with caution :)
var _loading_in_progress: bool = false ## Used to block SceneManager from attempting to load two things at the same time

var _levels_node: Node
var _current_scene_node: Node
var _current_scene_path: String ## Internal - stores the path to the asset SceneManager is trying to load
#var _player: Player = null


func _ready() -> void:
  var root: Node = get_tree().root
  var main: Node = root.get_child(root.get_child_count() - 1)

  _levels_node = main.get_node("Levels")
  _current_scene_node = _levels_node.get_child(0)
  _current_scene_path = _current_scene_node.scene_file_path
  #_player = main.get_node("Player")

  _content_invalid.connect(_on_content_invalid)
  _content_failed_to_load.connect(_on_content_failed_to_load)
  _content_finished_loading.connect(_on_content_finished_loading)


func _add_loading_screen(transition_type: String = "fade_to_black"):
  _transition = "no_to_transition" if transition_type == "no_transition" else transition_type
  _loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
  get_tree().root.add_child(_loading_screen)
  _loading_screen.start_transition(_transition)


func swap_scenes(scene_to_load: String, transition_type: String = "fade_to_black") -> void:
  if _loading_in_progress:
    push_warning("SceneManager is already loading something")
    return

  _loading_in_progress = true
  _load_scene_into = _levels_node
  _scene_to_unload = _current_scene_node
  var reload_current_scene: bool = scene_to_load == ""

  if not reload_current_scene:
    _current_scene_path = scene_to_load

  _add_loading_screen(transition_type)
  _load_content(_current_scene_path)


func _load_content(content_path: String) -> void:
  load_start.emit(_loading_screen)
  var loader = ResourceLoader.load_threaded_request(content_path)

  if not ResourceLoader.exists(content_path) or loader == null:
    _content_invalid.emit(content_path)
    return

  _load_progress_timer = Timer.new()
  _load_progress_timer.wait_time = 0.1
  _load_progress_timer.timeout.connect(_monitor_load_status)

  get_tree().root.add_child(_load_progress_timer)
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
        _loading_screen.update_bar(load_progress[0] * 100) # 0.1
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


## internal - fires when content is done loading. This is responsible for data transfer, adding the
## incoming scene removing the outgoing scene, halting the game until the out transition finishes,
## and also fires off the signals you can listen for to manage the SceneTree as things are added.
## These will also be useful for initializing things before the user gains control after a
## transition as well as controlling when the user can resume control.
## A Few Examples:
## - load_start: allows you to trigger something as soon as the loading screen is added to the tree, like for example playing a sound effect
## - scene_added: triggers after the incoming scene is added to the tree, useful for rearraging your scene tree to make sure the loading screen stays on top of everything or perhaps keeping your HUD above the loading screen. The world is your oyster, friend! You can also initialize stuff here before passing control back to the user, because at this stage the transition hasn't finished yet
## - load_complete: triggers at the end of _on_content_finished_loading, I use this to return control to the player
## Methods that a scene loaded through SceneManager can optionall implement:
## - pass_data: a scene should implement this if you want a scene to expose data to pass to an incoming scene
## - receive_data: a scene should implement this if you want that scene to be able to receive data from the outgoing scene. It is recommended that you check the data type of the incoming data to make sure it's of a type the incoming scene wants. If not, simply discard or don't set the data. This allows you to control which classes can send/receive information without having to worry about running into data mismatches. Think of it like an internal version of the "has_method" check.
## - init_scene: implement this to be able to execute code (like initializing stuff based on what was passed in through receive_data) - this should fire before the _ready method of the scene
## - start_scene: implement this to kick off your scene. I use it to return control to the player. But you could also trigger events with the scene or anything else you want to hold until loading and transitioning are both totally done.
func _on_content_finished_loading(incoming_scene) -> void:
  var outgoing_scene = _scene_to_unload

  if outgoing_scene != null:
    if outgoing_scene.has_method("pass_data") and incoming_scene.has_method("receive_data"):
      incoming_scene.receive_data(outgoing_scene.pass_data())

  _load_scene_into.add_child(incoming_scene)
  scene_added.emit(incoming_scene, _loading_screen)

  if _scene_to_unload != null:
    if _scene_to_unload != get_tree().root:
      _scene_to_unload.queue_free()

  if incoming_scene.has_method("init_scene"):
    incoming_scene.init_scene()

  if _loading_screen != null:
    _loading_screen.finish_transition()
    # Wait for loading animation to finish
    await _loading_screen.anim_player.animation_finished

  if incoming_scene.has_method("start_scene"):
    incoming_scene.start_scene()

  _loading_in_progress = false
  _current_scene_node = incoming_scene
  load_complete.emit(incoming_scene)
