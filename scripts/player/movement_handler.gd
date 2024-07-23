class_name MovementHandler extends Node

@export var walk_speed: float = 130.0
@export var run_speed: float = 200.0
@export var acceleration: float = 1000.0 # Was 10.0 when I was using lerp
@export var friction: float = 1500.0 # Was 15.0 when I was using lerp


func handle_movement(entity: CharacterBody2D, move_direction: float, air_speed: float, is_running: bool, delta: float) -> float:
  var on_floor: bool = entity.is_on_floor()
  var velocity_x: float = entity.velocity.x
  var speed: float = 0.0

  # Determine speed
  if on_floor:
    if move_direction != 0.0:
      speed = run_speed if is_running else walk_speed
  else:
    speed = air_speed

  # NOTE: Using lerp within _process or _physics_process is a bad idea when the starting value
  # (in this case, velocity.x) changes each frame. The starting position of the lerp gets assigned
  # to the output of the previous lerp, which creates an exponential decay instead of a linear
  # transition. What we really need is a "frame-rate aware damping function", so move_toward is a
  # better choice.
  # https://github.com/godotengine/godot-proposals/discussions/5290
  # https://www.gamedeveloper.com/programming/improved-lerp-smoothing-
  # https://www.reddit.com/r/godot/comments/10twtvu/problem_using_lerp_and_delta_with_low_fps/
  # https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
  # https://www.reddit.com/r/godot/comments/15dzn58/how_to_avoid_easeout_with_lerp/
  # TODO: consider using move_toward_smooth in the future: https://github.com/godotengine/godot/pull/92236

  # Calculate velocity
  if on_floor:
    if move_direction != 0.0:
      #velocity_x = lerp(velocity_x, move_direction * speed, acceleration * delta)
      velocity_x = move_toward(velocity_x, move_direction * speed, acceleration * delta)
      #velocity_x = lerp(move_direction * speed, velocity_x, pow(2, -acceleration * delta))
    else:
      #velocity_x = lerp(velocity_x, 0.0, friction * delta)
      velocity_x = move_toward(velocity_x, 0.0, friction * delta)
      #velocity_x = lerp(0.0, velocity_x, pow(2, -friction * delta))

    velocity_x = clamp(velocity_x, -speed, speed)
  else:
    if move_direction:
      velocity_x = move_direction * speed
    else:
      velocity_x = move_toward(velocity_x, 0.0, speed)

  return velocity_x
