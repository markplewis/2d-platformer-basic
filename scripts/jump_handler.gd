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

# Variable jump height:
# - https://gist.github.com/sjvnnings/5f02d2f2fc417f3804e967daa73cccfd?permalink_comment_id=5074318#gistcomment-5074318
# - https://www.reddit.com/r/godot/comments/17ate0w/adding_variable_jump_height/
# - https://www.youtube.com/watch?v=5D0XXRM5gMQ

signal jump_started
signal jump_ended

# Globals
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

const JumpMetrics: Resource = preload("res://scripts/jump_metrics.gd")
var _default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _coyote_timer: Timer = $CoyoteTimer
@onready var _jump_timer: Timer = Timer.new()
@onready var _jump_metrics: JumpMetrics = JumpMetrics.new()

# TODO: because we're using CharacterBody2D instead of RigidBody2D, the jump_height may vary
# based on the game's frame rate. There doesn't seem to be any way around this, unfortunately.
# - https://www.reddit.com/r/godot/comments/16fgryr/help_jumping_height_frame_dependent_even_though_i/
# - https://www.gamedev.net/blogs/entry/2265460-fixing-your-timestep-and-evaluating-godot/

# Settings
@export var jump_height: float = 48.0 # Pixels
@export var jump_rise_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_distance: float = 128.0 # Pixels
@export var jump_friction: float = 0.625 # 128 * 0.625 = 80

# Calculations
@onready var _jump_height: float = jump_height
@onready var _jump_distance: float = jump_distance
@onready var _jump_friction: float = jump_friction
@onready var _jump_duration: float = jump_rise_time + jump_fall_time
@onready var _jump_rise_gravity: float = ((-2.0 * _jump_height) / pow(jump_rise_time, 2)) * -1.0
@onready var _jump_fall_gravity: float = ((-2.0 * _jump_height) / pow(jump_fall_time, 2)) * -1.0
@onready var _jump_velocity: float = (_jump_rise_gravity * jump_rise_time) * -1.0
# The above line is functionally the same as:
# @onready var _jump_velocity: float = ((2.0 * _jump_height) / jump_rise_time) * -1.0

# State
var _jump_buffer: bool = false
var _can_jump: bool = true


func _ready() -> void:
  # Should be more than enough time (is setting this even necessary?)
  _jump_timer.wait_time = _jump_duration
  add_child(_jump_timer)


func handle_jump(
  entity: CharacterBody2D,
  collision_shape_position: Vector2,
  jump_button_pressed: bool,
  jump_button_just_pressed: bool,
  jump_button_released: bool,
  jump_button_just_released: bool,
  move_direction: float,
  run_button_pressed: bool,
  delta: float
) -> Dictionary:

  var on_floor: bool = entity.is_on_floor()
  var velocity_y: float = entity.velocity.y
  var position_vector: Vector2 = entity.position
  var should_jump: bool = false

  # Handle jump
  if not on_floor:
    if _can_jump:
      # Falling (did not jump)
      if _coyote_timer.is_stopped():
        _coyote_timer.start(coyote_time)
  else:
    if not _can_jump:
      # Landed on floor (after jumping or falling)
      jump_ended.emit(_jump_metrics.on_jump_end(position_vector, move_direction))

    _coyote_timer.stop()
    _jump_timer.stop()
    _jump_metrics.reset()
    _can_jump = true

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

  var move_speed: float

  if run_button_pressed:
    move_speed = _jump_distance / _jump_duration # No friction
  else:
    move_speed = (_jump_distance * _jump_friction) / _jump_duration
    # Clamp to ensure player can jump at least (_jump_distance * _jump_friction)
    # var walk_speed: float = 130.0
    # var run_speed: float = 230.0
    # move_speed = (_jump_distance * clamp(walk_speed / run_speed, _jump_friction, 1)) / _jump_duration

  # Apply jump
  if _can_jump and should_jump:
    velocity_y = _jump_velocity # Start jumping
    should_jump = false
    _can_jump = false
    _jump_timer.start()

    jump_started.emit(_jump_metrics.on_jump_start(
      collision_shape_position,
      position_vector,
      move_direction,
      move_speed,
      _jump_distance,
      _jump_duration,
      _jump_velocity,
      _jump_rise_gravity,
      _jump_fall_gravity,
      delta
    ))

  # Keep checking input while timer is running
  if jump_button_pressed and not _jump_timer.is_stopped():
    velocity_y = _jump_velocity # Continue jumping

  if jump_button_just_released:
    _jump_timer.stop()
    # velocity_y = move_toward(velocity_y, 0, move_speed)

  # if jump_button_released:
    # if velocity_y < 0:
      # velocity_y *= 0.5 # Reduce the velocity each frame
      # var percent_height_reached: float = _metric_height_reached / _jump_height

  velocity_y = _apply_gravity(on_floor, velocity_y, position_vector, delta)

  return { "velocity_y": velocity_y, "move_speed": move_speed }


func _apply_gravity(on_floor: bool, velocity_y: float, position_vector: Vector2, delta: float) -> float:
  var new_velocity_y: float = velocity_y
  var gravity: float = 0.0

  if not on_floor:
    if _can_jump:
      # Falling (did not jump)
      # (comment out to pause gravity until coyote timer has elapsed)
      gravity = _default_gravity # Fall
    else:
      if new_velocity_y >= 0 or _jump_timer.is_stopped():
        gravity = _jump_fall_gravity # Jump apex or descent
      else:
        gravity = _jump_rise_gravity # Jump ascent
        _jump_metrics.calculate_jump_height(position_vector, _jump_height)

      _jump_metrics.calculate_jump_distance(position_vector)

    new_velocity_y += gravity * delta

  return new_velocity_y


func _on_jump_buffer_timeout() -> void:
  _jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  _can_jump = false
