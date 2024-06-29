class_name JumpMetrics
extends Node

signal jump_start_metrics
signal jump_end_metrics

var _metric_pos_offset: Vector2 = Vector2.ZERO
var _metric_start_pos: Vector2 = Vector2.ZERO
var _metric_start_dir: float = 0.0
var _metric_start_speed: float = 0.0
var _metric_end_pos: Vector2 = Vector2.ZERO
var _metric_end_dir: float = 0.0
var _metric_height_reached: float = 0.0
var _metric_height_percent_reached: float = 0.0
var _metric_max_distance: float = 0.0
var _metric_distance_reached: float = 0.0
var _metric_distance_percent_reached: float = 0.0


func reset() -> void:
  _metric_pos_offset = Vector2.ZERO
  _metric_start_pos = Vector2.ZERO
  _metric_start_dir = 0.0
  _metric_start_speed = 0.0
  _metric_end_pos = Vector2.ZERO
  _metric_end_dir = 0.0
  _metric_height_reached = 0.0
  _metric_height_percent_reached = 0.0
  _metric_max_distance = 0.0
  _metric_distance_reached = 0.0
  _metric_distance_percent_reached = 0.0


func log_jump_start(
  position_offset: Vector2,
  position_vector: Vector2,
  move_direction: float,
  speed: float,
  distance: float,
  duration: float,
  jump_velocity: float,
  rise_gravity: float,
  fall_gravity: float,
  delta: float
) -> void:

  _metric_pos_offset = position_offset
  _metric_start_pos = position_vector
  _metric_start_dir = move_direction
  _metric_start_speed = speed
  _metric_max_distance = distance

  jump_start_metrics.emit({
    "start_pos": _metric_start_pos,
    # Emit collider.global_position so that it aligns with trajectory line,
    # because player's global_position is aligned to bottom of sprite
    "start_pos_offset": position_offset,
    "start_dir": _metric_start_dir,
    "duration": duration,
    "speed": _metric_start_speed,
    "max_distance": _metric_max_distance,
    "velocity": jump_velocity,
    "rise_gravity": rise_gravity,
    "fall_gravity": fall_gravity,
    "delta": delta
  })

func log_jump_height(position_vector: Vector2, jump_height: float) -> void:
  _metric_height_reached = abs(position_vector.y - _metric_start_pos.y)

  if _metric_height_reached != 0.0 and jump_height != 0.0:
    _metric_height_percent_reached = round(_metric_height_reached / jump_height * 100.0)
  else:
    _metric_height_percent_reached = 0.0


func log_jump_distance(position_vector: Vector2) -> void:
  _metric_distance_reached = abs(position_vector.x - _metric_start_pos.x)

  if _metric_distance_reached != 0.0 and _metric_max_distance != 0.0:
    _metric_distance_percent_reached = round(_metric_distance_reached / _metric_max_distance * 100.0)
  else:
    _metric_distance_percent_reached = 0.0


func log_jump_end(position_vector: Vector2, move_direction: float) -> void:
  _metric_end_pos = position_vector
  _metric_end_dir = move_direction

  jump_end_metrics.emit({
    "start_pos": _metric_start_pos,
    "start_pos_offset": _metric_pos_offset,
    "start_dir": _metric_start_dir,
    "end_pos": _metric_end_pos,
    "end_dir": _metric_end_dir,
    "height_reached": _metric_height_reached,
    "height_percent_reached": _metric_height_percent_reached,
    "distance_reached": _metric_distance_reached,
    "distance_percent_reached": _metric_distance_percent_reached
  })
