class_name GameManager
extends Node

@export var debug_mode: bool = false

@onready var debug: bool = OS.is_debug_build() and debug_mode
@onready var score_label: Label = $ScoreLabel
@onready var stats_label: Label = %StatsLabel

var _score: int = 0

var _jump_start_pos: Vector2 = Vector2.ZERO
var _jump_start_dir: float = 0
var _jump_end_pos: Vector2 = Vector2.ZERO

var _jump_height: float = 0
var _jump_height_percent: float = 0
var _jump_distance: float = 0
var _jump_distance_percent: float = 0


func update_text():
  # Determine whether player landed beyond their starting jump position or behind it
  var multiplier: float = 1

  var moved_right: bool = _jump_end_pos.x > _jump_start_pos.x
  var moved_left: bool = _jump_end_pos.x < _jump_start_pos.x

  var stated_moving_right: bool = _jump_start_dir == 1
  var stated_moving_left: bool = _jump_start_dir == -1
  var did_not_start_moving: bool = _jump_start_dir == 0

  if (stated_moving_right and moved_right) or (stated_moving_left and moved_left):
    multiplier = 1

  if (stated_moving_right and moved_left) or (stated_moving_left and moved_right):
    multiplier = -1

  if did_not_start_moving:
    multiplier = 1

  score_label.text = "You collected " + str(_score) + " coins!"

  var format_string: String = """
    Score: %s
    Jump height: %s (%s%%)
    Jump distance: %s (%s%%)
  """
  stats_label.text = format_string.dedent().strip_edges() % [
    _score, _jump_height, _jump_height_percent, _jump_distance * multiplier, _jump_distance_percent
  ]


func add_point():
  _score += 1
  update_text()


func _on_player_jump_started(_dict: Dictionary) -> void:
  _jump_start_dir = 0
  _jump_start_pos = Vector2.ZERO
  _jump_end_pos = Vector2.ZERO
  _jump_height = 0
  _jump_height_percent = 0
  _jump_distance = 0
  _jump_distance_percent = 0
  update_text()


func _on_player_jump_ended(dict: Dictionary) -> void:
  _jump_start_dir = dict.start_dir
  _jump_start_pos = dict.start_pos
  _jump_end_pos = dict.end_pos
  _jump_height = round(dict.height_reached)
  _jump_height_percent = dict.height_percent_reached
  _jump_distance = round(dict.distance_reached)
  _jump_distance_percent = dict.distance_percent_reached
  update_text()


func _on_player_died() -> void:
  _score = 0
  _jump_height = 0
  _jump_distance = 0
  update_text()
