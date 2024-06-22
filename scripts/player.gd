class_name Player
extends CharacterBody2D

# Parabolic jump trajectory (projectile motion equations) were borrowed from:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# Which attempted to implement the physics principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8
# See also:
# - https://youtu.be/PlT44xr0iW0?si=v2mpnxFHaUXQxmo9&t=373

# Jump buffering: https://www.youtube.com/watch?v=hRQW580zEJE
# Coyote time: https://www.youtube.com/watch?v=4Vhcqh9S2LM

@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ground_cast: RayCast2D = $GroundDetectionRaycast

var is_dead: bool = false

@export_category("Walking")
@export var walk_speed: float = 130.0
@export var run_speed: float = 230.0
@export var acceleration_speed: float = 10
@export var deceleration_speed: float = 15
@export var rotate_on_slopes: bool = true

var move_direction: float = 0
var last_move_direction: float = 1.0
var run_modifier_active: bool = false
var on_floor: bool = true
var floor_normal: Vector2 = Vector2.UP
var floor_angle: float = 0

@export_category("Jumping")
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
@onready var air_speed: float = jump_distance / (jump_peak_time + jump_fall_time)
@onready var air_speed_running: float = jump_distance_running / (jump_peak_time + jump_fall_time)

var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_buffer: bool = false
var jump_available: bool = true

@export_category("Debugging")
@export var draw_debug_lines: bool = true

@onready var slope_line: Line2D = Line2D.new()
@onready var velocity_line: Line2D = Line2D.new()
@onready var floor_normal_line: Line2D = Line2D.new()
@onready var trajectory_line: Line2D = Line2D.new()

func _ready() -> void:
  if OS.is_debug_build() and draw_debug_lines:
    slope_line.position = Vector2.ZERO
    slope_line.default_color = Color.WHITE
    slope_line.width = 1
    add_child(slope_line)

    velocity_line.position = Vector2(collision_shape.position.x, collision_shape.position.y)
    velocity_line.default_color = Color.CHARTREUSE
    velocity_line.width = 1
    add_child(velocity_line)

    floor_normal_line.position = Vector2.ZERO
    floor_normal_line.default_color = Color.INDIAN_RED
    floor_normal_line.width = 1
    add_child(floor_normal_line)

    trajectory_line.position = Vector2.ZERO
    trajectory_line.default_color = Color.AQUAMARINE
    trajectory_line.width = 1
    add_child(trajectory_line)


func _process(_delta: float) -> void:
  if OS.is_debug_build() and draw_debug_lines:
    # https://www.reddit.com/r/godot/comments/17d4cyg/how_do_you_draw_lines_for_visualising_the_velocity/
    slope_line.clear_points()
    velocity_line.clear_points()
    floor_normal_line.clear_points()

    if on_floor and not is_dead:
      slope_line.add_point(Vector2.from_angle(floor_angle) * -10)
      slope_line.add_point(Vector2.from_angle(floor_angle) * 10)

      velocity_line.add_point(Vector2.ZERO)
      velocity_line.add_point(velocity.normalized() * 15)

      floor_normal_line.add_point(Vector2.ZERO)
      floor_normal_line.add_point(floor_normal * 20)


func update_trajectory(new_velocity: Vector2, gravity: float, speed: float, delta: float) -> void:
  var max_points: int = 300
  trajectory_line.clear_points()
  var pos: Vector2 = Vector2.ZERO
  var vel: Vector2 = new_velocity * speed
  # print(str(new_velocity) + ", " + str(speed) + ", " + str(gravity))

  for i in max_points:
    trajectory_line.add_point(pos)
    vel.y += gravity * delta
    pos += vel * delta


func _physics_process(delta: float) -> void:
  move_direction = Input.get_axis("move_left", "move_right") # Range between -1.0 and 1.0
  run_modifier_active = Input.is_action_pressed("run")
  on_floor = is_on_floor()

  var gravity: float = calculate_gravity()
  var speed: float = calculate_speed()

  var new_velocity_y: float = calculate_velocity_y(velocity.y, gravity, delta)
  var new_velocity_x: float = calculate_velocity_x(velocity.x, speed, delta)

  var new_velocity: Vector2 = Vector2(new_velocity_x, new_velocity_y)

  update_trajectory(new_velocity, gravity, speed, delta)

  velocity = new_velocity

  rotate_sprite()
  flip_sprite()
  play_animation()

  if move_direction != 0:
    last_move_direction = move_direction

  move_and_slide()


func calculate_gravity() -> float:
  var gravity: float = 0

  if not on_floor:
    if jump_available: # Falling (did not jump)
      # Comment out to pause gravity until coyote timer has elapsed
      gravity = default_gravity # Fall
    else:
      if velocity.y < 0:
        gravity = jump_gravity # Jump ascent
      else:
        gravity = fall_gravity # Jump apex or descent

  return gravity


func calculate_speed() -> float:
  var speed: float = 0

  if on_floor:
    if move_direction != 0:
      speed = run_speed if run_modifier_active else walk_speed
  else:
    speed = air_speed_running if run_modifier_active else air_speed

  return speed


func calculate_velocity_y(velocity_y: float, gravity: float, delta: float) -> float:
  var new_velocity_y: float = velocity_y
  new_velocity_y = apply_gravity(velocity_y, gravity, delta)
  var should_jump: bool = handle_jump()

  if (should_jump):
    new_velocity_y = apply_jump(new_velocity_y)

  return new_velocity_y


func calculate_velocity_x(velocity_x: float, speed: float, delta: float) -> float:
  var new_velocity_x: float = velocity_x
  new_velocity_x = handle_movement(velocity_x, speed, delta)
  return new_velocity_x


func apply_gravity(velocity_y: float, gravity: float, delta: float) -> float:
  var new_velocity_y: float = velocity_y

  if not on_floor:
    new_velocity_y += gravity * delta

  return new_velocity_y


func handle_jump() -> bool:
  var should_jump: bool = false

  if not on_floor:
    if jump_available: # Falling (did not jump)
      if coyote_timer.is_stopped():
        coyote_timer.start(coyote_time)
  else:
    coyote_timer.stop()
    jump_available = true

    if jump_buffer:
      should_jump = true
      jump_buffer = false

  if Input.is_action_just_pressed("jump"):
    if jump_available:
      should_jump = true
    else:
      jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)

  return should_jump


func apply_jump(velocity_y: float) -> float:
  var new_velocity_y: float = velocity_y

  if jump_available:
    new_velocity_y = jump_velocity
    jump_available = false

  return new_velocity_y


func handle_movement(velocity_x: float, speed: float, delta: float) -> float:
  var new_velocity_x: float

  if on_floor:
    # This method provides tighter control over acceleration and deceleration
    if move_direction < 0:
      new_velocity_x = lerp(velocity_x, -speed, acceleration_speed * delta)
    if move_direction > 0:
      new_velocity_x = lerp(velocity_x, speed, acceleration_speed * delta)
    if move_direction == 0:
      new_velocity_x = lerp(velocity_x, 0.0, deceleration_speed * delta)
  else:
    if move_direction:
      new_velocity_x = move_direction * speed
    else:
      new_velocity_x = move_toward(velocity_x, 0, speed)

  return new_velocity_x


func rotate_sprite() -> void:
  sprite_container.rotation = 0
  # up_direction = Vector2.UP
  # rotation = 0

  # https://www.reddit.com/r/godot/comments/1agit6k/why_is_the_characterbody2d_property_max_floor/
  if on_floor and ground_cast.is_colliding():
    floor_normal = ground_cast.get_collision_normal()
    floor_angle = Vector2.UP.angle_to(floor_normal)
    # print("Angle: " + str(round(abs(rad_to_deg(floor_angle)))))
    # print("Max: " + str(rad_to_deg(floor_max_angle)))

    if floor_angle <= floor_max_angle and rotate_on_slopes:
      sprite_container.rotation = floor_angle
      # up_direction = floor_normal
      # rotation = floor_angle
      # rotation = lerp_angle(rotation, floor_angle, delta * 20)
      # velocity = raw_velocity.rotated(floor_angle)


func flip_sprite() -> void:
  if move_direction > 0:
    animated_sprite.flip_h = false
  elif move_direction < 0:
    animated_sprite.flip_h = true
  else:
    animated_sprite.flip_h = last_move_direction < 0


func play_animation() -> void:
  if is_dead:
    animated_sprite.play("die")
  else:
    if on_floor:
      if move_direction == 0:
        animated_sprite.play("idle")
      else:
        animated_sprite.play("run")
    else:
      if velocity.y < 0:
        animated_sprite.play("jump")
      else:
        animated_sprite.play("fall")


func die() -> void:
  is_dead = true;
  velocity.y = jump_velocity / 2


func on_jump_buffer_timeout() -> void:
  jump_buffer = false


func _on_coyote_timer_timeout() -> void:
  jump_available = false
