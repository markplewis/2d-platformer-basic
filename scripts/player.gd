extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
var last_direction = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
  # Add the gravity.
  if not is_on_floor():
    velocity.y += gravity * delta

  # Handle jump.
  if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = JUMP_VELOCITY

  # Get the input direction: -1, 0, 1
  var direction := Input.get_axis("move_left", "move_right")

  # Handle the movement/deceleration
  if direction:
    velocity.x = direction * SPEED
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)

  # Flip the sprite
  if direction > 0:
    animated_sprite.flip_h = false
  elif direction < 0:
    animated_sprite.flip_h = true
  else:
    animated_sprite.flip_h = last_direction < 0

  if direction != 0:
    last_direction = direction

  # Play animations
  if is_on_floor():
    if direction == 0:
      animated_sprite.play("idle")
    else:
      animated_sprite.play("run")
  else:
    animated_sprite.play("jump")

  move_and_slide()
