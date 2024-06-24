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


func _on_player_jump_start(_dict: Dictionary) -> void:
  jump_height = 0
  jump_distance = 0
  update_text()


func _on_player_jump_end(dict: Dictionary) -> void:
  jump_height = round(dict.jump_height_reached)
  jump_distance = round(dict.jump_distance_reached)
  update_text()


func _on_player_died() -> void:
  score = 0
  jump_height = 0
  jump_distance = 0
  update_text()
