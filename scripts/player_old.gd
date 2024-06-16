class_name PlayerOld
extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var move_speed: float = 130.0
@export var acceleration_speed: float = 10
@export var deceleration_speed: float = 15

@export var jump_speed: float = 300.0
@export var fall_speed: float = 300.0


# https://www.youtube.com/watch?v=IOe1aGY6hXA
@export var jump_height: float = 64.0 # Pixels
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_descent: float = 0.3

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

func get_gravity() -> float:
  return jump_gravity if velocity.y < 0.0 else fall_gravity


var last_direction: float = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes
# var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
  apply_gravity(delta)

  # Get the input direction: range between -1.0 and 1.0
  var direction: float = Input.get_axis("move_left", "move_right")

  handle_jump()
  handle_movement(direction, delta)
  flip_sprite(direction)
  play_animation(direction)

  if direction != 0:
    last_direction = direction

  move_and_slide() # Apply velocity changes


func apply_gravity(delta: float) -> void:
  if not is_on_floor():
    velocity.y += get_gravity() * delta
  #if not is_on_floor():
    #velocity.y += gravity * delta


func handle_jump() -> void:
  if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = jump_velocity
    #velocity.y = -jump_speed

  #if not is_on_floor():
    ## Clamp Y velocity between min and max jump/fall speeds
    #clampf(velocity.y, -jump_speed, fall_speed)


func handle_movement(direction: float, delta: float) -> void:
  #if direction:
    #velocity.x = direction * move_speed
  #else:
    #velocity.x = move_toward(velocity.x, 0, move_speed)

  # This method provides tighter control over acceleration and deceleration
  if direction < 0:
    velocity.x = lerp(velocity.x, -move_speed, acceleration_speed * delta)
  if direction > 0:
    velocity.x = lerp(velocity.x, move_speed, acceleration_speed * delta)
  if direction == 0:
    velocity.x = lerp(velocity.x, 0.0, deceleration_speed * delta)


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
