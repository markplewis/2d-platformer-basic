class_name MovementHandler
extends Node

@export var walk_speed: float = 130.0
@export var run_speed: float = 230.0
@export var acceleration: float = 10
@export var friction: float = 15


func handle_movement(entity: CharacterBody2D, move_direction: float, is_running: bool, air_speed: float, air_speed_running: float, delta: float) -> float:
  var on_floor: bool = entity.is_on_floor()
  var velocity_x: float = entity.velocity.x
  var speed: float = 0

  # Determine speed
  if on_floor:
    if move_direction != 0:
      speed = run_speed if is_running else walk_speed
  else:
    # air_speed can be optionally supplied as an argument
    if air_speed != 0:
      speed = air_speed_running if is_running else air_speed
    else:
      speed = run_speed if is_running else walk_speed

  # Calculate velocity
  if on_floor:
    if move_direction != 0:
      velocity_x = lerp(velocity_x, move_direction * speed, acceleration * delta)
    else:
      velocity_x = lerp(velocity_x, 0.0, friction * delta)
  else:
    if move_direction:
      velocity_x = move_direction * speed
    else:
      velocity_x = move_toward(velocity_x, 0, speed)

  return velocity_x
