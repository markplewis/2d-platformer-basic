class_name Player
extends CharacterBody2D

# Parabolic jump trajectory (projectile motion equations) were borrowed from:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# Which attempted to implement the physics principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8

# Jump buffering: https://www.youtube.com/watch?v=hRQW580zEJE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var on_floor: bool = true

@export_category("Walking")
@export var ground_speed: float = 130.0
@export var acceleration_speed: float = 10
@export var deceleration_speed: float = 15
var move_direction: float = 0
var last_direction: float = 1.0

@export_category("Jumping")
@export var jump_height: float = 64.0 # Pixels
@export var jump_distance: float = 64.0  # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3
@export var jump_buffer_time: float = 0.1
var has_jumped: bool = false
var jump_buffer: bool = false

@onready var jump_gravity: float = ((-2.0 * jump_height) / pow(jump_peak_time, 2)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / pow(jump_fall_time, 2)) * -1.0
@onready var jump_velocity: float = (jump_gravity * jump_peak_time) * -1.0
@onready var air_speed: float = jump_distance / (jump_peak_time + jump_fall_time)
var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

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
    last_direction = move_direction

  move_and_slide() # Apply velocity changes


func apply_gravity(delta: float) -> void:
  if not on_floor:
    if has_jumped:
      if velocity.y < 0:
        # Jump ascent
        velocity.y += jump_gravity * delta
      else:
        # Jump descent
        velocity.y += fall_gravity * delta
    else:
      # Falling (did not jump)
      velocity.y += default_gravity * delta
  else:
    if has_jumped:
      # Jump landed
      has_jumped = false
    if jump_buffer == true:
      jump()
      jump_buffer = false


func handle_jump() -> void:
  if Input.is_action_just_pressed("ui_accept"):
    if on_floor: # Make this jump_available when we implement coyote time
      jump()
    else:
      jump_buffer = true
      get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)


func jump() -> void:
  if not has_jumped:
    velocity.y = jump_velocity
    has_jumped = true


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
    animated_sprite.flip_h = last_direction < 0


func play_animation() -> void:
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


func on_jump_buffer_timeout() -> void:
  jump_buffer = false
