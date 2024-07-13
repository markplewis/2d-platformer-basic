extends Node

# https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

signal jump_started
signal jump_ended
signal interacted
signal dying
signal dead
signal resurrected
signal score_changed
signal health_changed

# Defaults
var _score_default: int = 0
var _health_default: int = 100

# Current state
var _score: int = _score_default
var _health: int = _health_default


# -------------------------------
# Getters and setters
# -------------------------------


# Score

func get_score() -> int:
  return _score


func set_score(value: int = 0) -> void:
  _score = value
  score_changed.emit(_score)


func increase_score(value: int = 1) -> void:
  _score += value
  score_changed.emit(_score)


func decrease_score(value: int = 1) -> void:
  _score -= value
  score_changed.emit(_score)


# Health


func get_health() -> int:
  return _health


func set_health(value: int = 0) -> void:
  _health = value
  health_changed.emit(_health)


func increase_health(value: int = 1) -> void:
  _health += value
  health_changed.emit(_health)


func decrease_health(value: int = 1) -> void:
  _health -= value
  health_changed.emit(_health)


# -------------------------------
# Dispatch methods
# (Instead of the Player emitting these signals directly, it invokes these methods like a relay)
# -------------------------------


# Interactions


func dispatch_opened_door(_door: Door, path_to_new_scene: String, _transition_type: String) -> void:
  SceneManager.swap_scenes(path_to_new_scene, "fade_to_black")


func dispatch_interacted() -> void:
  interacted.emit()


# Jumping


func dispatch_jump_started(dict: Dictionary) -> void:
  jump_started.emit(dict)


func dispatch_jump_ended(dict: Dictionary) -> void:
  jump_ended.emit(dict)


# Death and resurrection


func dispatch_dying() -> void:
  Engine.time_scale = 0.5
  set_score(_score_default)
  set_health(_health_default)
  get_tree().create_timer(0.6).timeout.connect(_on_dying_timeout)
  dying.emit()


func _on_dying_timeout() -> void:
  Engine.time_scale = 1
  dead.emit()
  SceneManager.swap_scenes("", "fade_to_black") # Reload current scene


func dispatch_resurrected() -> void:
  resurrected.emit()





