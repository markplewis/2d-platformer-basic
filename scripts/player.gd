extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var mode_speed: float = 130.0
@export var jump_speed: float = 300.0
@export var fall_speed: float = 300.0

var last_direction: float = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
  apply_gravity(delta)

  # Get the input direction: range between -1.0 and 1.0
  var direction: float = Input.get_axis("move_left", "move_right")

  handle_jump()
  handle_movement(direction)
  flip_sprite(direction)
  play_animation(direction)

  if direction != 0:
    last_direction = direction

  move_and_slide() # Apply velocity changes

func apply_gravity(delta: float) -> void:
  if not is_on_floor():
    velocity.y += gravity * delta

func handle_jump() -> void:
  if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = -jump_speed

  # Clamp Y velocity between min and max jump/fall speeds
  clampf(velocity.y, -jump_speed, fall_speed)

func handle_movement(direction: float) -> void:
  if direction:
    velocity.x = direction * mode_speed
  else:
    velocity.x = move_toward(velocity.x, 0, mode_speed)

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
    animated_sprite.play("jump")
