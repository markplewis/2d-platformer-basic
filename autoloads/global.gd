extends Node

# https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

signal player_dying
signal player_dead
signal player_resurrected
signal player_score_changed
signal player_health_changed
# signal level_changed

var debug_mode: bool = true
var debug: bool = OS.is_debug_build() and debug_mode

var _score_default: int = 0
var _health_default: int = 100

var _score: int = _score_default
var _health: int = _health_default

var _levels_node: Node = null
var _current_level: Node = null
var _player: Player = null


func _ready() -> void:
  var root: Node = get_tree().root
  var main: Node = root.get_child(root.get_child_count() - 1)
  _levels_node = main.get_node("Levels")
  _current_level = _levels_node.get_child(0)
  _player = main.get_node("Player")


func go_to_next_level() -> void:
  if _current_level.has_method("get_next_level_name"):
    go_to_level(_current_level.get_next_level_name())


func restart_level() -> void:
  if _current_level.has_method("get_level_name"):
    go_to_level(_current_level.get_level_name())


func go_to_level(file_name: String) -> void:
  # This function will usually be called from a signal callback,
  # or some other function in the current scene.
  # Deleting the current scene at this point is
  # a bad idea, because it may still be executing code.
  # This will result in a crash or unexpected behavior.
  # The solution is to defer the load to a later time, when
  # we can be sure that no code from the current scene is running:
  call_deferred("_deferred_go_to_level", file_name)


func _deferred_go_to_level(file_name: String) -> void:
  # It is now safe to remove the current scene.
  _current_level.free()
  # Load the new scene.
  var s: PackedScene = ResourceLoader.load("res://scenes/levels/" + file_name + ".tscn")
  # Instance the new scene.
  _current_level = s.instantiate()
  # Add it to the active scene, as child of root.
  _levels_node.add_child(_current_level)
  # Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
  # get_tree().current_scene = _current_level

  if _current_level.has_method("init"):
    _current_level.init(_player)

  # get_tree().create_timer(10).timeout.connect(func(): level_changed.emit())
  # level_changed.emit()


func on_player_dying() -> void:
  player_dying.emit()
  set_player_score(_score_default)
  set_player_health(_health_default)


func on_player_dead() -> void:
  player_dead.emit()
  restart_level()


func on_player_resurrected() -> void:
  player_resurrected.emit()


func increase_player_score(value: int = 1) -> void:
  _score += value
  player_score_changed.emit(_score)


func decrease_player_score(value: int = 1) -> void:
  _score -= value
  player_score_changed.emit(_score)


func set_player_score(value: int = 0) -> void:
  _score = value
  player_score_changed.emit(_score)


func increase_player_health(value: int = 1) -> void:
  _health += value
  player_health_changed.emit(_health)


func decrease_player_health(value: int = 1) -> void:
  _health -= value
  player_health_changed.emit(_health)


func set_player_health(value: int = 0) -> void:
  _health = value
  player_health_changed.emit(_health)
