extends Node

# See: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html

signal player_died
signal player_score_changed
signal player_health_changed

var debug_mode: bool = true
var debug: bool = OS.is_debug_build() and debug_mode

var _score_default: int = 0
var _health_default: int = 100

var _score: int = _score_default
var _health: int = _health_default


func kill_player() -> void:
  set_player_score(_score_default)
  set_player_health(_health_default)
  player_died.emit()


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
