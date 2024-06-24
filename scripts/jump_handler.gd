class_name JumpHandler
extends Node

@export var jump_height: float = 64.0 # Pixels
@export var jump_distance: float = 64.0 # Pixels
@export var jump_distance_running: float = 96.0 # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_gravity: float = ((-2.0 * jump_height) / pow(jump_peak_time, 2)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / pow(jump_fall_time, 2)) * -1.0
@onready var jump_velocity: float = (jump_gravity * jump_peak_time) * -1.0
@onready var jump_duration: float = jump_peak_time + jump_fall_time
@onready var air_speed: float = jump_distance / jump_duration
@onready var air_speed_running: float = jump_distance_running / jump_duration

var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_buffer: bool = false
var jump_available: bool = true

# Metrics for logging
var jump_height_reached: float = 0
var jump_distance_reached: float = 0
var jump_start_pos: Vector2 = Vector2.ZERO
var jump_start_dir: float = 0

signal jump_start
signal jump_end


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

  # Calculate gravity
  if not on_floor:
    if jump_available: # Falling (did not jump)
      # Comment out to pause gravity until coyote timer has elapsed
      gravity = default_gravity # Fall
    else:
      if velocity_y < 0:
        gravity = jump_gravity # Jump ascent
        jump_height_reached = abs(position_vector.y - jump_start_pos.y)
      else:
        gravity = fall_gravity # Jump apex or descent

  # Apply gravity
  if not on_floor:
    velocity_y += gravity * delta

  # Handle jump
  var should_jump: bool = false

  if not on_floor:
    if jump_available: # Falling (did not jump)
      if coyote_timer.is_stopped():
        coyote_timer.start(coyote_time)
  else:
    if not jump_available:
      jump_distance_reached = abs(position_vector.x - jump_start_pos.x)
      jump_end.emit(jump_height_reached, jump_distance_reached)

    coyote_timer.stop()
    jump_available = true

    jump_height_reached = 0
    jump_distance_reached = 0
    jump_start_pos = Vector2.ZERO
    jump_start_dir = 0

    if jump_buffer:
      should_jump = true
      jump_buffer = false

  if jump_button_pressed:
    if jump_available:
      should_jump = true
    else:
      jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)

  if should_jump:
    if jump_available:
      velocity_y = jump_velocity
      jump_available = false
      jump_start_pos = position_vector
      jump_start_dir = move_direction

      var speed: float = air_speed_running if run_button_pressed else air_speed
      jump_start.emit(
        entity.collision_shape.global_position,
        jump_start_dir,
        jump_duration,
        speed,
        jump_velocity,
        jump_gravity,
        fall_gravity,
        delta
      )

  return { "velocity_y": velocity_y, "air_speed": air_speed, "air_speed_running": air_speed_running }


func on_jump_buffer_timeout() -> void:
  jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  jump_available = false
