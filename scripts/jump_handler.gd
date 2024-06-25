class_name JumpHandler
extends Node

# Parabolic jump trajectory (projectile motion equations) were borrowed from:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# Which attempted to implement the physics principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8
# See also:
# - https://youtu.be/PlT44xr0iW0?si=v2mpnxFHaUXQxmo9&t=373

# Jump buffering: https://www.youtube.com/watch?v=hRQW580zEJE
# Coyote time: https://www.youtube.com/watch?v=4Vhcqh9S2LM

signal jump_start
signal jump_end

# Globals
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1

@onready var _coyote_timer: Timer = $CoyoteTimer

var _default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Jump calculation input (default)
@export var jump_height: float = 64.0 # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_distance: float = 64.0 # Pixels
@export var jump_distance_running: float = 96.0 # Pixels

# Jump calculation input (current)
@onready var _base_height: float = jump_height
@onready var _base_peak_time: float = jump_peak_time
@onready var _base_fall_time: float = jump_fall_time
@onready var _base_distance: float = jump_distance
@onready var _base_distance_running: float = jump_distance_running

# Jump calculation output
var _calc_rise_gravity: float
var _calc_fall_gravity: float
var _calc_velocity: float
var _calc_duration: float
var _calc_air_speed: float
var _calc_air_speed_running: float

# Jump state
var _jump_buffer: bool = false
var _jump_available: bool = true

# Jump metrics
var _metric_start_dir: float = 0
var _metric_start_pos: Vector2 = Vector2.ZERO
var _metric_end_dir: float = 0
var _metric_end_pos: Vector2 = Vector2.ZERO
var _metric_height_reached: float = 0
var _metric_height_reached_percent: float = 0
var _metric_distance_reached: float = 0
var _metric_distance_reached_percent: float = 0


func _ready() -> void:
  _calculate_jump_params(
    _base_height,
    _base_peak_time,
    _base_fall_time,
    _base_distance,
    _base_distance_running
  )


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
  _calc_duration = peak_time + fall_time
  _calc_air_speed = distance / _calc_duration
  _calc_air_speed_running = distance_running / _calc_duration

  # TODO: calculate the percentage of the jump's total height/distance that the user is expected to
  # travel and scale these numbers by multiplying them by that percentage (i.e. user releases move
  # buttons or jump button early, before jump has completed)


func handle_jump(
  entity: CharacterBody2D,
  jump_button_pressed: bool,
  move_direction: float,
  run_button_pressed: bool,
  delta: float
) -> Dictionary:

  var on_floor: bool = entity.is_on_floor()
  var velocity_y: float = entity.velocity.y
  var position_vector: Vector2 = entity.position
  var gravity: float = 0
  var should_jump: bool = false

  if not on_floor:
    # Calculate gravity
    if _jump_available:
      # Falling (did not jump)
      # (Comment out to pause gravity until coyote timer has elapsed)
      gravity = _default_gravity # Fall
    else:
      if velocity_y < 0:
        gravity = _calc_rise_gravity # Jump ascent
        _metric_height_reached = abs(position_vector.y - _metric_start_pos.y)
        _metric_height_reached_percent = round(clamp(_metric_height_reached / _base_height, 0, 1) * 100)
      else:
        gravity = _calc_fall_gravity # Jump apex or descent

    # Apply gravity
    velocity_y += gravity * delta

  # Handle jump
  if not on_floor:
    if _jump_available:
      # Falling (did not jump)
      if _coyote_timer.is_stopped():
        _coyote_timer.start(coyote_time)
    else:
      # Jumping
      _metric_end_dir = move_direction
      _metric_end_pos = position_vector
      _metric_distance_reached = abs(position_vector.x - _metric_start_pos.x)
      _metric_distance_reached_percent = round(clamp(_metric_distance_reached / _base_distance, 0, 1) * 100)
  else:
    if not _jump_available:
      # Landed on floor (after jumping or falling)
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

    _coyote_timer.stop()
    _jump_available = true

    # Reset jump metrics
    _metric_start_dir = 0
    _metric_start_pos = Vector2.ZERO
    _metric_end_dir = 0
    _metric_end_pos = Vector2.ZERO
    _metric_height_reached = 0
    _metric_height_reached_percent = 0
    _metric_distance_reached = 0
    _metric_distance_reached_percent = 0

    if _jump_buffer:
      # Initiate delayed/buffered jump
      should_jump = true
      _jump_buffer = false

  # Handle jump button input
  if jump_button_pressed:
    if _jump_available:
      should_jump = true
    else:
      _jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(_on_jump_buffer_timeout)

  # Apply jump
  if should_jump:
    if _jump_available:
      velocity_y = _calc_velocity
      _jump_available = false

      # Jump metrics
      _metric_start_pos = position_vector
      _metric_start_dir = move_direction

      jump_start.emit({
        "start_dir":  _metric_start_dir,
        "start_pos": _metric_start_pos,
        # Emit collider.global_position so that it aligns with trajectory line,
        # because player's global_position is aligned to bottom of sprite
        "start_pos_offset": entity.collision_shape.global_position,
        "duration": _calc_duration,
        "speed": _calc_air_speed_running if run_button_pressed else _calc_air_speed,
        "velocity": _calc_velocity,
        "rise_gravity": _calc_rise_gravity,
        "fall_gravity":  _calc_fall_gravity,
        "delta": delta
      })

  return { "velocity_y": velocity_y, "air_speed": _calc_air_speed, "air_speed_running": _calc_air_speed_running }


func _on_jump_buffer_timeout() -> void:
  _jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  _jump_available = false
