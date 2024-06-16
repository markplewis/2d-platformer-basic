class_name Player
extends CharacterBody2D

# Inspired by:
# - https://www.youtube.com/watch?v=FvFx1R3p-aw
# - https://www.youtube.com/watch?v=IOe1aGY6hXA
# Which attempted to implement the physics math and principles described here:
# - https://www.youtube.com/watch?v=hG9SzQxaCm8

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export_category("Walking")
@export var ground_speed: float = 130.0
@export var acceleration_speed: float = 10
@export var deceleration_speed: float = 15

@export_category("Jumping")
@export var jump_height: float = 64.0 # Pixels
@export var jump_distance: float = 64.0  # Pixels
@export var jump_peak_time: float = 0.4
@export var jump_fall_time: float = 0.3

@onready var jump_gravity: float = ((-2.0 * jump_height) / pow(jump_peak_time, 2)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / pow(jump_fall_time, 2)) * -1.0
@onready var jump_velocity: float = (jump_gravity * jump_peak_time) * -1.0
@onready var air_speed: float = jump_distance / (jump_peak_time + jump_fall_time)

var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_direction: float = 1.0
var has_jumped: bool = false

func _physics_process(delta: float) -> void:
  apply_gravity(delta)
  handle_jump()

  # Get the input direction: range between -1.0 and 1.0
  var direction: float = Input.get_axis("move_left", "move_right")

  handle_movement(direction, delta)
  flip_sprite(direction)
  play_animation(direction)

  if direction != 0:
    last_direction = direction

  move_and_slide() # Apply velocity changes


func apply_gravity(delta: float) -> void:
  if not is_on_floor():
    if has_jumped:
      if velocity.y < 0:
        velocity.y += jump_gravity * delta
        # print("jump_gravity: " + str(jump_gravity))
      else:
        velocity.y += fall_gravity * delta
        # print("fall_gravity: " + str(fall_gravity))
    else:
      velocity.y += default_gravity * delta
      # print("default_gravity: " + str(default_gravity))
  else:
    if has_jumped:
      # print("Landed")
      has_jumped = false


func handle_jump() -> void:
  if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    # print("Jumped")
    has_jumped = true
    velocity.y = jump_velocity


func handle_movement(direction: float, delta: float) -> void:
  # Ternary operator equivalent
  # var speed: float = ground_speed if is_on_floor() else air_speed

  if is_on_floor():
    # This method provides tighter control over acceleration and deceleration
    if direction < 0:
      velocity.x = lerp(velocity.x, -ground_speed, acceleration_speed * delta)
    if direction > 0:
      velocity.x = lerp(velocity.x, ground_speed, acceleration_speed * delta)
    if direction == 0:
      velocity.x = lerp(velocity.x, 0.0, deceleration_speed * delta)
  else:
    if direction:
      velocity.x = direction * air_speed
    else:
      velocity.x = move_toward(velocity.x, 0, air_speed)


func flip_sprite(direction: float) -> void:
  if direction > 0:
    animated_sprite.flip_h = false
  elif direction < 0:
    animated_sprite.flip_h = true
  else:
    animated_sprite.flip_h = last_direction < 0


func play_animation(direction: float) -> void:
  if is_on_floor():
    if direction == 0:
      animated_sprite.play("idle")
    else:
      animated_sprite.play("run")
  else:
    if velocity.y < 0:
      animated_sprite.play("jump")
    else:
      animated_sprite.play("fall")
