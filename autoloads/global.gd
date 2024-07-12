extends Node

# https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

signal player_interacted
signal player_dying
signal player_dead
signal player_resurrected
signal player_score_changed
signal player_health_changed

var debug_mode: bool = true
var debug: bool = OS.is_debug_build() and debug_mode

var _score_default: int = 0
var _health_default: int = 100

var _score: int = _score_default
var _health: int = _health_default


func on_door_opened(_door: Door, path_to_new_scene: String, _transition_type: String) -> void:
  SceneManager.swap_scenes(path_to_new_scene, "fade_to_black")


func on_player_interacted() -> void:
  player_interacted.emit()


func on_player_dying() -> void:
  Engine.time_scale = 0.5
  set_player_score(_score_default)
  set_player_health(_health_default)
  get_tree().create_timer(0.6).timeout.connect(_on_player_dead_timeout)
  player_dying.emit()


func _on_player_dead_timeout() -> void:
  Engine.time_scale = 1
  player_dead.emit()
  SceneManager.swap_scenes("", "fade_to_black") # Reload scene


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
