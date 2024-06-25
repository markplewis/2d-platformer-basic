class_name GameManager
extends Node

@onready var score_label: Label = $ScoreLabel
@onready var stats_label: Label = %StatsLabel

@export var debug_mode: bool = false

var score: int = 0

var jump_start_pos: Vector2 = Vector2.ZERO
var jump_start_dir: float = 0
var jump_end_pos: Vector2 = Vector2.ZERO
var jump_end_dir: float = 0

var jump_height: float = 0
var jump_height_percent: float = 0
var jump_distance: float = 0
var jump_distance_percent: float = 0


func update_text():
  #var multiplier: float = 1

  #if jump_start_dir >= 0 and jump_end_pos.x >= jump_start_pos.x:
    #multiplier = 1
  #if jump_start_dir < 0 and jump_end_pos.x < jump_start_pos.x:
    #multiplier = 1
  #if jump_start_dir >= 0 and jump_end_pos.x < jump_start_pos.x:
    #multiplier = -1
  #if jump_start_dir < 0 and jump_end_pos.x >= jump_start_pos.x:
    #multiplier = -1

  score_label.text = "You collected " + str(score) + " coins!"

  var format_string: String = """
    Score: %s
    Jump height: %s (%s%%)
    Jump distance: %s (%s%%)
  """
  stats_label.text = format_string.dedent().strip_edges() % [
    score, jump_height, jump_height_percent, jump_distance, jump_distance_percent
  ]


func add_point():
  score += 1
  update_text()


func _on_player_jump_start(_dict: Dictionary) -> void:
  jump_start_pos = Vector2.ZERO
  jump_start_dir = 0
  jump_end_pos = Vector2.ZERO
  jump_end_dir = 0
  jump_height = 0
  jump_height_percent = 0
  jump_distance = 0
  jump_distance_percent = 0
  update_text()


func _on_player_jump_end(dict: Dictionary) -> void:
  jump_start_pos = dict.start_pos
  jump_start_dir = dict.start_dir
  jump_end_pos = dict.end_pos
  jump_end_dir = dict.end_dir
  jump_height = round(dict.height_reached)
  jump_height_percent = dict.height_percent_reached
  jump_distance = round(dict.distance_reached)
  jump_distance_percent = dict.distance_percent_reached
  update_text()


func _on_player_died() -> void:
  score = 0
  jump_height = 0
  jump_distance = 0
  update_text()
