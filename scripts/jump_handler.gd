class_name JumpHandler
extends Node

# Parabolic jump trajectory (projectile motion equations) were borrowed from:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# - https://youtu.be/PlT44xr0iW0?si=v2mpnxFHaUXQxmo9&t=373
# Which attempt to implement the physics principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8

# Jump buffering: https://www.youtube.com/watch?v=hRQW580zEJE
# Coyote time: https://www.youtube.com/watch?v=4Vhcqh9S2LM

# TODO: implement variable jump height:
# https://gist.github.com/sjvnnings/5f02d2f2fc417f3804e967daa73cccfd?permalink_comment_id=5074318#gistcomment-5074318

signal jump_start
signal jump_end

# Globals
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1

@onready var _coyote_timer: Timer = $CoyoteTimer
@onready var _jump_timer: Timer = $JumpTimer

var _default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# TODO: because we're using CharacterBody2D instead of RigidBody2D, the jump_height may vary
# based on the game's frame rate. There doesn't seem to be any way around this, unfortunately.
# - https://www.reddit.com/r/godot/comments/16fgryr/help_jumping_height_frame_dependent_even_though_i/
# - https://www.gamedev.net/blogs/entry/2265460-fixing-your-timestep-and-evaluating-godot/

# Jump calculation input (default)
@export var jump_height: float = 64.0 # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_distance: float = 64.0 # Pixels
@export var jump_distance_running: float = 96.0 # Pixels

# Jump calculation input (current)
@onready var _jump_height: float = jump_height
@onready var _jump_peak_time: float = jump_peak_time
@onready var _jump_fall_time: float = jump_fall_time
@onready var _jump_distance: float = jump_distance
@onready var _jump_distance_running: float = jump_distance_running

# Jump calculation output
var _calc_rise_gravity: float
var _calc_fall_gravity: float
var _calc_velocity: float
var _calc_duration: float
var _calc_air_speed: float
var _calc_air_speed_running: float

# Jump state
var _jump_buffer: bool = false
var _can_jump: bool = true

# Jump metrics
var _metric_start_dir: float = 0.0
var _metric_start_pos: Vector2 = Vector2.ZERO
var _metric_start_max_distance: float = 0.0
var _metric_start_speed: float = 0.0
var _metric_end_dir: float = 0.0
var _metric_end_pos: Vector2 = Vector2.ZERO
var _metric_height_reached: float = 0.0
var _metric_height_reached_percent: float = 0.0
var _metric_distance_reached: float = 0.0
var _metric_distance_reached_percent: float = 0.0


# TODO: calculate the percentage of the jump's total height/distance that the user is expected to
# travel and scale these numbers by multiplying them by that percentage (i.e. user releases move
# buttons or jump button early, before jump has completed)

func _calculate_jump_params(
  height: float,
  peak_time: float,
  fall_time: float,
  distance: float,
  distance_running: float
) -> void:

  _calc_rise_gravity = ((-2.0 * height) / pow(peak_time, 2)) * -1.0
  _calc_fall_gravity = ((-2.0 * height) / pow(fall_time, 2)) * -1.0
  _calc_velocity = (_calc_rise_gravity * peak_time) * -1.0
  # _calc_velocity = ((2.0 * height) / peak_time) * -1.0

  _calc_duration = peak_time + fall_time
  _calc_air_speed = distance / _calc_duration
  _calc_air_speed_running = distance_running / _calc_duration


func _ready() -> void:
  _calculate_jump_params(
    _jump_height,
    _jump_peak_time,
    _jump_fall_time,
    _jump_distance,
    _jump_distance_running
  )


func handle_jump(
  entity: CharacterBody2D,
  jump_button_pressed: bool,
  jump_button_just_pressed: bool,
  move_direction: float,
  run_button_pressed: bool,
  delta: float
) -> Dictionary:

  var on_floor: bool = entity.is_on_floor()
  var velocity_y: float = entity.velocity.y
  var position_vector: Vector2 = entity.position
  var gravity: float = 0.0
  var should_jump: bool = false

  if not on_floor:
    # Calculate gravity
    if _can_jump: # _jump_timer.is_stopped()
      # Falling (did not jump)
      # (comment out to pause gravity until coyote timer has elapsed)
      gravity = _default_gravity # Fall
    else:
      if velocity_y < 0:
        gravity = _calc_rise_gravity # Jump ascent
        _capture_jump_height_metrics(position_vector)
      else:
        gravity = _calc_fall_gravity # Jump apex or descent

    # Apply gravity
    velocity_y += gravity * delta

  # Handle jump
  if not on_floor:
    if _can_jump: # _jump_timer.is_stopped()
      # Falling (did not jump)
      if _coyote_timer.is_stopped():
        _coyote_timer.start(coyote_time)
    else:
      # Jumping
      _capture_jump_distance_metrics(position_vector)
  else:
    if not _can_jump: # if not _jump_timer.is_stopped() # should be impossible, so _is_jumping?
      # Landed on floor (after jumping or falling)
      _capture_jump_end_metrics(entity, move_direction, position_vector)

    _coyote_timer.stop()
    # _jump_timer.stop()
    _can_jump = true # _is_jumping = false?
    _reset_metrics()

    if _jump_buffer:
      # Initiate delayed/buffered jump
      should_jump = true
      _jump_buffer = false

  # Handle jump button input
  if jump_button_just_pressed:
    if _can_jump:
      should_jump = true
    else:
      _jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(_on_jump_buffer_timeout)

  # keep checking input while timer is running
  #if jump_button_pressed and not _jump_timer.is_stopped():
    #velocity_y = _calc_velocity # should_continue_jumping = true

  # Apply jump
  if should_jump:
    if _can_jump:
      velocity_y = _calc_velocity
      _can_jump = false
      # _jump_timer.start()
      _capture_jump_start_metrics(entity, move_direction, position_vector, run_button_pressed, delta)

  return { "velocity_y": velocity_y, "air_speed": _calc_air_speed, "air_speed_running": _calc_air_speed_running }


func _on_jump_buffer_timeout() -> void:
  _jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  _can_jump = false


func _capture_jump_start_metrics(entity: CharacterBody2D, move_direction: float, position_vector: Vector2, run_button_pressed: bool, delta: float) -> void:
  _metric_start_dir = move_direction
  _metric_start_pos = position_vector
  _metric_start_max_distance = _jump_distance_running if run_button_pressed else _jump_distance
  _metric_start_speed = _calc_air_speed_running if run_button_pressed else _calc_air_speed

  jump_start.emit({
    "start_dir": _metric_start_dir,
    "start_pos": _metric_start_pos,
    # Emit collider.global_position so that it aligns with trajectory line,
    # because player's global_position is aligned to bottom of sprite
    "start_pos_offset": entity.collision_shape.global_position,
    "duration": _calc_duration,
    "speed": _metric_start_speed,
    "max_distance": _metric_start_max_distance,
    "velocity": _calc_velocity,
    "rise_gravity": _calc_rise_gravity,
    "fall_gravity": _calc_fall_gravity,
    "delta": delta
  })


func _capture_jump_height_metrics(position_vector: Vector2) -> void:
  _metric_height_reached = abs(position_vector.y - _metric_start_pos.y)

  if _metric_height_reached != 0.0 and _jump_height != 0.0:
    _metric_height_reached_percent = round(_metric_height_reached / _jump_height * 100.0)
    # _metric_height_reached_percent = round(clamp(_metric_height_reached / _jump_height, 0, 1) * 100)
  else:
    _metric_height_reached_percent = 0.0


func _capture_jump_distance_metrics(position_vector: Vector2) -> void:
  _metric_distance_reached = abs(position_vector.x - _metric_start_pos.x)

  if _metric_distance_reached != 0.0 and _metric_start_max_distance != 0.0:
    _metric_distance_reached_percent = round(_metric_distance_reached / _metric_start_max_distance * 100.0)
    # _metric_distance_reached_percent = round(clamp(_metric_distance_reached / _metric_start_max_distance, 0, 1) * 100)
  else:
    _metric_distance_reached_percent = 0.0


func _capture_jump_end_metrics(entity: CharacterBody2D, move_direction: float, position_vector: Vector2) -> void:
  _metric_end_dir = move_direction
  _metric_end_pos = position_vector

  jump_end.emit({
    "start_dir": _metric_start_dir,
    "start_pos": _metric_start_pos,
    "start_pos_offset": entity.collision_shape.global_position,
    "end_dir": _metric_end_dir,
    "end_pos": _metric_end_pos,
    "height_reached": _metric_height_reached,
    "height_reached_percent": _metric_height_reached_percent,
    "distance_reached": _metric_distance_reached,
    "distance_reached_percent": _metric_distance_reached_percent
  })


func _reset_metrics() -> void:
  _metric_start_dir = 0.0
  _metric_start_pos = Vector2.ZERO
  _metric_start_max_distance = 0.0
  _metric_start_speed = 0.0
  _metric_end_dir = 0.0
  _metric_end_pos = Vector2.ZERO
  _metric_height_reached = 0.0
  _metric_height_reached_percent = 0.0
  _metric_distance_reached = 0.0
  _metric_distance_reached_percent = 0.0
