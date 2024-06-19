class_name Player
extends CharacterBody2D

# Parabolic jump trajectory (projectile motion equations) were borrowed from:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# Which attempted to implement the physics principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8

# Jump buffering: https://www.youtube.com/watch?v=hRQW580zEJE
# Coyote time: https://www.youtube.com/watch?v=4Vhcqh9S2LM

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var is_dead: bool = false

@export_category("Walking")
@export var ground_speed: float = 130.0
@export var acceleration_speed: float = 10
@export var deceleration_speed: float = 15

var move_direction: float = 0
var last_move_direction: float = 1.0
var on_floor: bool = true
var floor_normal: Vector2 = Vector2.UP
var floor_angle: float = 0

@export_category("Jumping")
@export var jump_height: float = 64.0 # Pixels
@export var jump_distance: float = 64.0 # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_gravity: float = ((-2.0 * jump_height) / pow(jump_peak_time, 2)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / pow(jump_fall_time, 2)) * -1.0
@onready var jump_velocity: float = (jump_gravity * jump_peak_time) * -1.0
@onready var air_speed: float = jump_distance / (jump_peak_time + jump_fall_time)

var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_buffer: bool = false
var jump_available: bool = true

@export_category("Debugging")
@export var draw_debug_lines: bool = true


@onready var  slope_line: Line2D = Line2D.new()
@onready var  velocity_line: Line2D = Line2D.new()
@onready var  l: Line2D = Line2D.new()

func _ready() -> void:
  if OS.is_debug_build() and draw_debug_lines:
    slope_line.position = Vector2.ZERO
    slope_line.default_color = Color.WHITE
    slope_line.width = 1
    # slope_line.global_rotation = 0
    add_child(slope_line)

    velocity_line.position = Vector2(collision_shape.position.x, collision_shape.position.y)
    velocity_line.default_color = Color.GOLD
    velocity_line.width = 1
    # velocity_line.global_rotation = 0
    add_child(velocity_line)

    l.position = Vector2.ZERO
    l.default_color = Color.INDIAN_RED
    l.width = 1
    add_child(l)


func _process(delta: float) -> void:
  if OS.is_debug_build() and draw_debug_lines:
    # https://www.reddit.com/r/godot/comments/17d4cyg/how_do_you_draw_lines_for_visualising_the_velocity/
    slope_line.clear_points()
    velocity_line.clear_points()
    l.clear_points()

    if on_floor and not is_dead:
      slope_line.add_point(Vector2.ZERO)
      if floor_normal.x < 0:
        # Sloping upward to right
        if velocity.x < 0:
          slope_line.add_point(Vector2.UP.rotated(-floor_angle) * 10)
        else:
          slope_line.add_point(Vector2.DOWN.rotated(-floor_angle) * 10)
      else:
        # Sloping upward to left
        if velocity.x > 0:
          slope_line.add_point(Vector2.UP.rotated(floor_angle) * 10)
        else:
          slope_line.add_point(Vector2.DOWN.rotated(floor_angle) * 10)

      velocity_line.add_point(Vector2.ZERO)
      velocity_line.add_point(velocity.normalized() * 15)

      l.add_point(Vector2.ZERO)
      l.add_point(floor_normal * 20)


func _physics_process(delta: float) -> void:
  # Get the input direction: range between -1.0 and 1.0
  move_direction = Input.get_axis("move_left", "move_right")
  on_floor = is_on_floor()

  apply_gravity(delta)
  handle_jump()
  handle_movement(delta)
  flip_sprite()
  play_animation()

  if move_direction != 0:
    last_move_direction = move_direction

  move_and_slide() # Apply velocity changes

  if on_floor:
    floor_normal = get_floor_normal()
    floor_angle = get_floor_angle() + deg_to_rad(90)
    # print(get_floor_normal().rotated(deg_to_rad(90)))
  else:
    floor_normal = Vector2.UP
    floor_angle = 0

# See: Assets/Scripts/Shinjingi/Capabilities/Move.cs - FixedUpdate method
# And: Assets/Scripts/Shinjingi/Sensors/GroundSensor.cs - SlopeCheck method
#
# if (OnGround) {
#   Vector2 slopeAdjustedVelocity = new Vector2(_moveInputX, 0f);
#
#   // Convert ground hit normal from world space to player's local space
#   Vector2 localGroundCheckHitNormal = _body.transform.InverseTransformDirection(_groundHit.normal);
#
#   // Get angle between player up and ground hit normal (0 degrees when on a flat surface)
#   SlopeAngle = Vector2.Angle(localGroundCheckHitNormal, _body.transform.up);
#   OnSlope = SlopeAngle != 0f;
#
#   // Calculate amount of rotation needed to align player up with ground hit normal
#   SlopeAngleRotation = OnSlope
#     ? Quaternion.FromToRotation(_body.transform.up, localGroundCheckHitNormal)
#     : Quaternion.identity;
#
#   // SlopeAngleRotation includes both X and Y values, so Y velocity may no longer be zero
#   slopeAdjustedVelocity = SlopeAngleRotation * slopeAdjustedVelocity;
#   newVelocity = slopeAdjustedVelocity * speed;
# }


func apply_gravity(delta: float) -> void:
  if not on_floor:
    if jump_available: # About to fall (did not jump)
      if coyote_timer.is_stopped():
        coyote_timer.start(coyote_time)
      # Comment out to pause gravity until coyote timer has elapsed
      velocity.y += default_gravity * delta # Fall
    else:
      if velocity.y < 0:
        velocity.y += jump_gravity * delta # Jump ascent
      else:
        velocity.y += fall_gravity * delta # Jump descent
  else:
    coyote_timer.stop()
    jump_available = true

    if jump_buffer:
      jump()
      jump_buffer = false


func handle_jump() -> void:
  if Input.is_action_just_pressed("ui_accept"):
    if jump_available:
      jump()
    else:
      jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)


func jump() -> void:
  if jump_available:
    velocity.y = jump_velocity
    jump_available = false


func handle_movement(delta: float) -> void:
  if on_floor:
    # This method provides tighter control over acceleration and deceleration
    if move_direction < 0:
      velocity.x = lerp(velocity.x, -ground_speed, acceleration_speed * delta)
    if move_direction > 0:
      velocity.x = lerp(velocity.x, ground_speed, acceleration_speed * delta)
    if move_direction == 0:
      velocity.x = lerp(velocity.x, 0.0, deceleration_speed * delta)
  else:
    if move_direction:
      velocity.x = move_direction * air_speed
    else:
      velocity.x = move_toward(velocity.x, 0, air_speed)


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
