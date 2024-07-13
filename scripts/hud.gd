class_name HUD extends Node

@onready var _stats_label: Label = $ColorRect/StatsLabel

var _score: int = 0

var _jump_start_pos: Vector2 = Vector2.ZERO
var _jump_start_dir: float = 0
var _jump_end_pos: Vector2 = Vector2.ZERO

var _jump_height: float = 0
var _jump_height_percent: float = 0
var _jump_distance: float = 0
var _jump_distance_percent: float = 0


func _ready() -> void:
  #SceneManager.scene_added.connect(_on_scene_manager_scene_added)
  PlayerContext.jump_started.connect(_on_player_context_jump_started)
  PlayerContext.jump_ended.connect(_on_player_context_jump_ended)
  PlayerContext.dying.connect(_on_player_context_dying)
  PlayerContext.resurrected.connect(_on_player_context_resurrected)
  PlayerContext.score_changed.connect(_on_global_score_changed)
  _update_text()


func _reset() -> void:
  _score = 0
  _jump_height = 0
  _jump_height_percent = 0
  _jump_distance = 0
  _jump_distance_percent = 0


func _update_text() -> void:
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

  var format_string: String = """
    Score: %s
    Jump height: %s (%s%%)
    Jump distance: %s (%s%%)
  """
  _stats_label.text = format_string.dedent().strip_edges() % [
    _score, _jump_height, _jump_height_percent, _jump_distance * multiplier, _jump_distance_percent
  ]


# Programmatically-connected signals from autoload scope(s)


func _on_player_context_jump_started(_dict: Dictionary) -> void:
  _jump_start_dir = 0
  _jump_start_pos = Vector2.ZERO
  _jump_end_pos = Vector2.ZERO
  _jump_height = 0
  _jump_height_percent = 0
  _jump_distance = 0
  _jump_distance_percent = 0
  _update_text()


func _on_player_context_jump_ended(dict: Dictionary) -> void:
  _jump_start_dir = dict.start_dir
  _jump_start_pos = dict.start_pos
  _jump_end_pos = dict.end_pos
  _jump_height = round(dict.height_reached)
  _jump_height_percent = dict.height_percent_reached
  _jump_distance = round(dict.distance_reached)
  _jump_distance_percent = dict.distance_percent_reached
  _update_text()


#func _on_scene_manager_scene_added(incoming_scene, _loading_screen) -> void:
  #_reset()
  #_update_text()


func _on_player_context_dying() -> void:
  _reset()
  _update_text()


func _on_player_context_resurrected() -> void:
  _reset()
  _update_text()


func _on_global_score_changed(score: int) -> void:
  _score = score
  _update_text()
