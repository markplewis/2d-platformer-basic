extends Node

# https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

signal level_loading(loading_screen: LoadingScreen)
signal level_loaded(loaded_scene: Node, loading_screen: LoadingScreen)
signal level_ready(loaded_scene: Node)

signal player_jump_started(dict: Dictionary)
signal player_jump_ended(dict: Dictionary)
signal player_health_changed(int)
signal player_score_changed(int)
signal player_dying()
signal player_dead()

@export var _levels: Array[PackedScene] = []

var debug_mode: bool = true # Change this to false before building the game
var debug: bool = OS.is_debug_build() and debug_mode

# True when the "Run Current Scene" button was pressed in the editor instead of "Run Project"
var running_individual_scene: bool = true

const _level_manager_class: Resource = preload("res://scripts/levels/level_manager.gd")
var _level_manager: LevelManager = null

const _ui_canvas_scene: PackedScene = preload("res://scenes/ui/ui_canvas.tscn")
var _ui_canvas: UICanvas = null

const _health_max: int = 100
var _health: int = _health_max
var _score: int = 0


func _ready() -> void:
  _level_manager = _level_manager_class.new()
  _level_manager.init(_levels, get_tree())

  _level_manager.load_started.connect(_on_level_manager_load_started)
  _level_manager.scene_added.connect(_on_level_manager_scene_added)
  _level_manager.load_completed.connect(_on_level_manager_load_completed)

  _ui_canvas = _ui_canvas_scene.instantiate() as UICanvas
  add_child(_ui_canvas)

  _ui_canvas.game_started.connect(_start_game)
  _ui_canvas.game_resumed.connect(_resume_game)
  _ui_canvas.hide_all()


# Level manager


func _on_level_manager_load_started(loading_screen: LoadingScreen) -> void:
  level_loading.emit(loading_screen)


func _on_level_manager_scene_added(loaded_scene: Node, loading_screen: LoadingScreen) -> void:
  _ui_canvas.hide_all()
  level_loaded.emit(loaded_scene, loading_screen)


func _on_level_manager_load_completed(loaded_scene: Node) -> void:
  level_ready.emit(loaded_scene)


# Commands (called directly from other nodes, unless private)


func show_main_menu() -> void:
  _ui_canvas.show_main_menu()


func pause_game() -> void:
  Engine.time_scale = 0
  _ui_canvas.show_pause_menu()


func _start_game() -> void:
  _level_manager.change_level(0)


func _resume_game() -> void:
  Engine.time_scale = 1
  _ui_canvas.hide_all()


# Score


func get_score() -> int:
  return _score


func set_score(new_value: int) -> void:
  if new_value == _score:
    return
  _score = new_value
  player_score_changed.emit(_score)


func increase_score(increase: int, current: int = _score) -> int:
  return current + max(0, increase)


func decrease_score(decrease: int, current: int = _score) -> int:
  return current - max(0, decrease)


# Health


func get_health() -> int:
  return _health


func get_max_health() -> int:
  return _health_max


func set_health(new_value: int) -> void:
  if new_value == _health:
    return
  _health = new_value
  player_health_changed.emit(_health)


func increase_health(increase: int, current: int = _health) -> int:
  return clamp(current + max(0, increase), 0, _health_max)


func decrease_health(decrease: int, current: int = _health) -> int:
  return clamp(current - max(0, decrease), 0, _health_max)


# Gameplay events (called directly from other nodes)


func on_player_opened_door(dict: Dictionary) -> void:
  _level_manager.change_level(dict.level_index, dict.transition_type)


func on_player_jump_started(dict: Dictionary) -> void:
  player_jump_started.emit(dict)


func on_player_jump_ended(dict: Dictionary) -> void:
  player_jump_ended.emit(dict)


func on_player_dying() -> void:
  Engine.time_scale = 0.5
  set_health(0)
  set_score(0)
  player_dying.emit()


func on_player_dead() -> void:
  Engine.time_scale = 1
  set_health(_health_max)
  set_score(0)
  player_dead.emit()
  _level_manager.change_level(-1) # Reload current scene
