class_name Player
extends CharacterBody2D

@export var rotate_on_slopes: bool = true

# Game manager
@onready var game_manager: GameManager = %GameManager

# Input
@onready var input_handler: InputHandler = $InputHandler
@onready var movement_handler: MovementHandler = $MovementHandler
@onready var jump_handler: JumpHandler = $JumpHandler

# Physics and visuals
@onready var sprite_container: Node2D = $SpriteContainer
@onready var animated_sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ground_cast: RayCast2D = $GroundDetectionRaycast

# Debugging
@onready var slope_line: Line2D = Line2D.new()
@onready var velocity_line: Line2D = Line2D.new()
@onready var floor_normal_line: Line2D = Line2D.new()

var move_direction: float = 0
var last_move_direction: float = 1.0
var run_button_pressed: bool = false
var jump_button_pressed: bool = false
var on_floor: bool = true
var floor_normal: Vector2 = Vector2.UP
var floor_angle: float = 0
var is_dead: bool = false

signal jump_start
signal jump_end
signal died

func _ready() -> void:
  if OS.is_debug_build() and game_manager.debug_mode:
    slope_line.position = Vector2.ZERO
    slope_line.default_color = Color.WHITE
    slope_line.width = 1
    add_child(slope_line)

    velocity_line.position = collision_shape.position
    velocity_line.default_color = Color.CHARTREUSE
    velocity_line.width = 1
    add_child(velocity_line)

    floor_normal_line.position = Vector2.ZERO
    floor_normal_line.default_color = Color.INDIAN_RED
    floor_normal_line.width = 1
    add_child(floor_normal_line)


func _process(_delta: float) -> void:
  if OS.is_debug_build() and game_manager.debug_mode:
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


func _physics_process(delta: float) -> void:
  move_direction = input_handler.get_move_direction()
  run_button_pressed = input_handler.get_run_button_pressed()
  jump_button_pressed = input_handler.get_jump_button_pressed()
  # jump_button_released = input_handler.get_jump_button_released()

  on_floor = is_on_floor()

  # Y velocity
  var dict: Dictionary = jump_handler.handle_jump(
    self,
    jump_button_pressed,
    move_direction,
    run_button_pressed,
    delta
  )
  var new_velocity_y: float = dict.velocity_y
  var air_speed: float = dict.air_speed
  var air_speed_running: float = dict.air_speed_running

  # X velocity
  var new_velocity_x: float = movement_handler.handle_movement(
    self,
    move_direction,
    run_button_pressed,
    air_speed,
    air_speed_running,
    delta
  )

  var new_velocity: Vector2 = Vector2(new_velocity_x, new_velocity_y)
  velocity = new_velocity

  rotate_sprite()
  flip_sprite()
  play_animation()

  if move_direction != 0:
    last_move_direction = move_direction

  move_and_slide()


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
  velocity.y = -150.0
  died.emit()


func _on_jump_handler_jump_start(dict: Dictionary) -> void:
  jump_start.emit(dict) # Re-emit


func _on_jump_handler_jump_end(dict: Dictionary) -> void:
  jump_end.emit(dict) # Re-emit
