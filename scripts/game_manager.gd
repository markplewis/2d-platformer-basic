class_name GameManager
extends Node

@onready var score_label: Label = $ScoreLabel
@onready var stats_label: Label = %StatsLabel

@export var debug_mode: bool = false

var score: int = 0
var jump_height: float = 0
var jump_distance: float = 0


func update_text():
  score_label.text = "You collected " + str(score) + " coins!"
  stats_label.text = """
    Score: %s
    Jump height: %s
    Jump distance: %s
  """.dedent().strip_edges() % [score, jump_height, jump_distance]


func add_point():
  score += 1
  update_text()


func _on_player_jump_start(
  _start_pos: Vector2,
  _start_dir: float,
  _duration: float,
  _speed: float,
  _jump_velocity: float,
  _jump_gravity: float,
  _fall_gravity: float,
  _delta: float
) -> void:
  jump_height = 0
  jump_distance = 0
  update_text()


func _on_player_jump_end(jump_height_reached: float, jump_distance_reached: float) -> void:
  jump_height = round(jump_height_reached)
  jump_distance = round(jump_distance_reached)
  update_text()


func _on_player_died() -> void:
  score = 0
  jump_height = 0
  jump_distance = 0
  update_text()
