extends Node

# See: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html

signal player_died
signal score_changed

var debug_mode: bool = true
var debug: bool = OS.is_debug_build() and debug_mode

var _score: int = 0


func kill_player() -> void:
  reset_score()
  player_died.emit()


func increase_score(value: int = 1) -> void:
  _score += value
  score_changed.emit(_score)


func reset_score() -> void:
  _score = 0
  score_changed.emit(_score)
