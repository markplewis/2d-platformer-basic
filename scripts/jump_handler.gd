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

# Jump calculation input (defaults)
@export var jump_max_height: float = 64.0 # Pixels
@export var jump_max_peak_time: float = 0.4
@export var jump_max_fall_time: float = 0.3
@export var jump_max_distance: float = 64.0 # Pixels
@export var jump_max_distance_running: float = 96.0 # Pixels

# Jump calculation input (state)
@onready var _jump_current_height: float = jump_max_height
@onready var _jump_current_peak_time: float = jump_max_peak_time
@onready var _jump_current_fall_time: float = jump_max_fall_time
@onready var _jump_current_distance: float = jump_max_distance
@onready var _jump_current_distance_running: float = jump_max_distance_running

# Jump calculation output
var _rise_gravity: float
var _fall_gravity: float
var _jump_velocity: float
var _jump_duration: float
var _air_speed: float
var _air_speed_running: float

# Jump state
var _jump_buffer: bool = false
var _jump_available: bool = true

# Jump metrics
var _jump_height_reached: float = 0
var _jump_height_percent_reached: float = 0
var _jump_distance_reached: float = 0
var _jump_distance_percent_reached: float = 0
var _jump_start_pos: Vector2 = Vector2.ZERO
var _jump_end_pos: Vector2 = Vector2.ZERO
var _jump_start_dir: float = 0
var _jump_end_dir: float = 0


func _ready() -> void:
  _calculate_jump_params(
    _jump_current_height,
    _jump_current_peak_time,
    _jump_current_fall_time,
    _jump_current_distance,
    _jump_current_distance_running
  )


func _calculate_jump_params(
  height: float,
  peak_time: float,
  fall_time: float,
  distance: float,
  distance_running: float
) -> void:

  _rise_gravity = ((-2.0 * height) / pow(peak_time, 2)) * -1.0
  _fall_gravity = ((-2.0 * height) / pow(fall_time, 2)) * -1.0
  _jump_velocity = (_rise_gravity * peak_time) * -1.0
  _jump_duration = peak_time + fall_time
  _air_speed = distance / _jump_duration
  _air_speed_running = distance_running / _jump_duration

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
        gravity = _rise_gravity # Jump ascent
        _jump_height_reached = abs(position_vector.y - _jump_start_pos.y)
        _jump_height_percent_reached = round(clamp(_jump_height_reached / _jump_current_height, 0, 1) * 100)
      else:
        gravity = _fall_gravity # Jump apex or descent

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
      _jump_distance_reached = abs(position_vector.x - _jump_start_pos.x)
      _jump_distance_percent_reached = round(clamp(_jump_distance_reached / _jump_current_distance, 0, 1) * 100)
      _jump_end_pos = position_vector
      _jump_end_dir = move_direction
  else:
    if not _jump_available:
      # Landed on floor (after jumping or falling)
      jump_end.emit({
        "start_pos_offset": entity.collision_shape.global_position,
        "start_pos": _jump_start_pos,
        "end_pos": _jump_end_pos,
        "start_dir": _jump_start_dir,
        "end_dir": _jump_end_dir,
        "height_reached": _jump_height_reached,
        "height_percent_reached": _jump_height_percent_reached,
        "distance_reached": _jump_distance_reached,
        "distance_percent_reached": _jump_distance_percent_reached
      })

    _coyote_timer.stop()
    _jump_available = true

    # Reset jump metrics
    _jump_height_reached = 0
    _jump_height_percent_reached = 0
    _jump_distance_reached = 0
    _jump_distance_percent_reached = 0
    _jump_start_pos = Vector2.ZERO
    _jump_end_pos = Vector2.ZERO
    _jump_start_dir = 0
    _jump_end_dir = 0

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
      velocity_y = _jump_velocity
      _jump_available = false

      # Jump metrics
      _jump_start_pos = position_vector
      _jump_start_dir = move_direction

      jump_start.emit({
        # Emit collider.global_position so that it aligns with trajectory line,
        # because player's global_position is aligned to bottom of sprite
        "start_pos_offset": entity.collision_shape.global_position,
        "start_pos": _jump_start_pos,
        "start_dir":  _jump_start_dir,
        "duration": _jump_duration,
        "speed": _air_speed_running if run_button_pressed else _air_speed,
        "jump_velocity": _jump_velocity,
        "rise_gravity": _rise_gravity,
        "fall_gravity":  _fall_gravity,
        "delta": delta
      })

  return { "velocity_y": velocity_y, "air_speed": _air_speed, "air_speed_running": _air_speed_running }


func _on_jump_buffer_timeout() -> void:
  _jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  _jump_available = false
