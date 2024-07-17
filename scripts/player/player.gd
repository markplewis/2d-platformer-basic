class_name Player extends CharacterBody2D

signal acquired_item(dict: Dictionary)
signal interacted(entity: Node2D)
signal paused_game()
signal opened_door(dict: Dictionary)
signal jump_started(dict: Dictionary)
signal jump_ended(dict: Dictionary)
signal dying()
signal dead()
signal resurrected()
signal score_changed(int)
signal health_changed(int)

@export var rotate_on_slopes: bool = true

# Ways to access the scene's root node:
# @onready var _root_node: Node = $"/root/Main"
# @onready var _root_node: Node = get_node(^"/root/Main")
# @onready var _root_node: Node = self.owner

# Input
@onready var _input_handler: InputHandler = $InputHandler
@onready var _movement_handler: MovementHandler = $MovementHandler
@onready var _jump_handler: JumpHandler = $JumpHandler
@onready var _damage_timer: Timer = $DamageTimer

var _controls_disabled: bool = false

# Physics and visuals
@onready var _sprite_container: Node2D = $SpriteContainer
@onready var _animated_sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape
@onready var _trail: Trail = $Trail

# RayCasts
@onready var _attack_ray_cast_left: RayCast2D = $AttackRayCastLeft
@onready var _attack_ray_cast_right: RayCast2D = $AttackRayCastRight
@onready var _ground_ray_cast: RayCast2D = $GroundDetectionRayCast

# Debugging
const _player_debug_lines_class: Resource = preload("res://scripts/player/player_debug_lines.gd")
@onready var _player_debug_lines: PlayerDebugLines = _player_debug_lines_class.new()

# State
var _move_direction: float = 0.0
var _last_move_direction: float = 1.0
var _run_button_pressed: bool = false
var _jump_button_pressed: bool = false
var _jump_button_just_pressed: bool = false
var _jump_button_released: bool = false
var _jump_button_just_released: bool = false
var _interact_button_just_pressed: bool = false
var _pause_button_just_pressed: bool = false

var _on_floor: bool = true
var _floor_normal: Vector2 = Vector2.UP
var _floor_angle: float = 0.0
var _is_damaged: bool = false
var _is_dead: bool = false

var _score_default: int = 0
var _health_default: int = 100
var _attack_strength_default: int = 15
var _defence_strength_default: int = 5

var _score: int = _score_default
var _health: int = _health_default
var _attack_strength: int = _attack_strength_default
var _defence_strength: int = _defence_strength_default


func _ready() -> void:
  _disable()
  SceneManager.load_start.connect(_on_scene_manager_load_start)
  SceneManager.scene_added.connect(_on_scene_manager_scene_added)
  SceneManager.load_complete.connect(_on_scene_manager_load_complete)

  if Global.debug and not _is_dead:
    _player_debug_lines.init(self, _collision_shape.position)


func _process(_delta: float) -> void:
  if Global.debug and not _is_dead:
    _player_debug_lines.draw(_on_floor, _floor_normal, _floor_angle, velocity)


func _physics_process(delta: float) -> void:
  _move_direction = 0.0 if _controls_disabled else _input_handler.get_move_direction()
  _run_button_pressed = false if _controls_disabled else _input_handler.get_run_button_pressed()
  _jump_button_pressed = false if _controls_disabled else _input_handler.get_jump_button_just_pressed()
  _jump_button_just_pressed = false if _controls_disabled else _input_handler.get_jump_button_just_pressed()
  _jump_button_released = false if _controls_disabled else _input_handler.get_jump_button_released()
  _jump_button_just_released = false if _controls_disabled else _input_handler.get_jump_button_just_released()
  _interact_button_just_pressed = false if _controls_disabled else _input_handler.get_interact_button_just_pressed()
  _pause_button_just_pressed = false if _controls_disabled else _input_handler.get_pause_button_just_pressed()

  _on_floor = is_on_floor()

  if _interact_button_just_pressed:
    interacted.emit(self)

  _attack()

  if _pause_button_just_pressed:
    paused_game.emit()

  var collision_shape_pos: Vector2 = Vector2.ZERO if _is_dead else _collision_shape.global_position

  # Vertical velocity
  var jump_values: Dictionary = _jump_handler.handle_jump(
    self,
    collision_shape_pos,
    _jump_button_pressed,
    _jump_button_just_pressed,
    # _jump_button_released,
    _jump_button_just_released,
    _move_direction,
    _run_button_pressed,
    delta
  )
  var new_velocity_y: float = jump_values.velocity_y
  var move_speed: float = jump_values.move_speed

  # Horizontal velocity
  var new_velocity_x: float = _movement_handler.handle_movement(
    self,
    _move_direction,
    move_speed,
    _run_button_pressed,
    delta
  )

  var new_velocity: Vector2 = Vector2(new_velocity_x, new_velocity_y)
  velocity = new_velocity

  _rotate_sprite()
  _flip_sprite()
  _play_animation()

  if _move_direction != 0.0:
    _last_move_direction = _move_direction

  move_and_slide()


func _rotate_sprite() -> void:
  _sprite_container.rotation = 0.0
  # up_direction = Vector2.UP
  # rotation = 0.0

  # https://www.reddit.com/r/godot/comments/1agit6k/why_is_the_characterbody2d_property_max_floor/
  if _on_floor and _ground_ray_cast.is_colliding():
    _floor_normal = _ground_ray_cast.get_collision_normal()
    _floor_angle = Vector2.UP.angle_to(_floor_normal)
    # print("Angle: " + str(round(abs(rad_to_deg(_floor_angle)))))
    # print("Max: " + str(rad_to_deg(floor_max_angle)))

    if _floor_angle <= floor_max_angle and rotate_on_slopes:
      _sprite_container.rotation = _floor_angle
      # up_direction = _floor_normal
      # rotation = _floor_angle
      # rotation = lerp_angle(rotation, _floor_angle, delta * 20.0)
      # velocity = raw_velocity.rotated(_floor_angle)


func _flip_sprite() -> void:
  if _move_direction > 0.0:
    _animated_sprite.flip_h = false
  elif _move_direction < 0.0:
    _animated_sprite.flip_h = true
  else:
    _animated_sprite.flip_h = _last_move_direction < 0.0


func _play_animation() -> void:
  if _is_dead:
    _animated_sprite.play("die")
  elif _is_damaged:
    _animated_sprite.play("damaged")
  else:
    if _on_floor:
      if _move_direction == 0.0:
        _animated_sprite.play("idle")
      else:
        _animated_sprite.play("run")
    else:
      if velocity.y < 0.0:
        _animated_sprite.play("jump")
      else:
        _animated_sprite.play("fall")


# Death


func die() -> void:
  _is_dead = true;
  _disable_movement()
  _disable_collider()
  velocity.y = -150.0
  set_score(_score_default)
  set_health(_health_default)
  dying.emit()
  get_tree().create_timer(0.6).timeout.connect(func(): dead.emit())


func _resurrect() -> void:
  _is_dead = false;
  resurrected.emit()


# Interactions


func open_door(dict: Dictionary) -> void:
  _disable_movement()
  dict.merge({ "entity": self })
  opened_door.emit(dict)


func _attack() -> void:
  var entityCollider: Object = null
  var entity: Node2D = null

  if _attack_ray_cast_left.is_colliding():
    entityCollider = _attack_ray_cast_left.get_collider()

  if _attack_ray_cast_right.is_colliding():
    entityCollider = _attack_ray_cast_right.get_collider()

  if entityCollider != null:
    if entityCollider is CharacterBody2D:
      entity = entityCollider
    else:
      entity = entityCollider.owner

  if entity != null and entity.has_method("take_damage") and _interact_button_just_pressed:
    entity.take_damage(_attack_strength)


# Items


func acquire_item(item: Node2D) -> void:
  acquired_item.emit({ "entity": self, "item": item })


# Score


func get_score() -> int:
  return _score


func set_score(value: int) -> void:
  _score = value
  score_changed.emit(_score)


func increase_score(value: int = 1) -> void:
  _score += value
  score_changed.emit(_score)


func decrease_score(value: int = 1) -> void:
  _score -= value
  score_changed.emit(_score)


# Health


func get_health() -> int:
  return _health


func set_health(value: int) -> void:
  if value <= 0:
    die()
    return
  if value < _health:
    _damage()
  _health = value
  health_changed.emit(_health)


func increase_health(value: int = 10) -> void:
  _health += value
  health_changed.emit(_health)


func decrease_health(value: int = 10) -> void:
  _health -= value
  if _health <= 0:
    die()
    return
  _damage()
  health_changed.emit(_health)


func take_damage(value: int) -> void:
  decrease_health(max(0, value - _defence_strength))


func _damage() -> void:
  _is_damaged = true
  _damage_timer.stop()
  _damage_timer.start(0.5)


func _on_damage_timer_timeout() -> void:
  _is_damaged = false


# Jump handler


func _on_jump_handler_jump_started(dict: Dictionary) -> void:
  jump_started.emit(dict)


func _on_jump_handler_jump_ended(dict: Dictionary) -> void:
  jump_ended.emit(dict)


# Disable/enable stuff


func _disable() -> void:
  hide()
  _disable_movement()
  _disable_collider()


func _disable_movement() -> void:
  velocity = Vector2.ZERO
  _controls_disabled = true
  _trail.disable()


func _enable_movement() -> void:
  _controls_disabled = false
  _trail.enable()


func _disable_collider() -> void:
  _collision_shape.set_deferred("disabled", true)


func _enable_collider() -> void:
  # Due to the following bug, we must wait exactly 2 physics frames before re-enabling the
  # player's collision shape. Otherwise, if the player died by falling into a "Killzone"
  # (an Area2D node with a WorldBoundary collision shape), then the Area2D's body_entered signal
  # will fire twice (once when the player touches it and again when the level/scene re-loads,
  # even if the player's position has changed by that point and they're no longer touching it).
  # https://github.com/godotengine/godot/issues/88592#issuecomment-1958670810
  # https://github.com/godotengine/godot/issues/61584
  # https://github.com/godotengine/godot/issues/14578
  # https://github.com/godotengine/godot/issues/18748
  # https://www.reddit.com/r/godot/comments/1d285xl/player_is_dying_twice/
  await get_tree().physics_frame
  await get_tree().physics_frame
  _collision_shape.set_deferred("disabled", false)


# Scene manager


func _on_scene_manager_load_start(_loading_screen) -> void:
  _disable_movement()


func _on_scene_manager_scene_added(incoming_scene, _loading_screen) -> void:
  position = incoming_scene.player_start_pos
  _trail.clear()
  _enable_collider()
  show() # In case this is the first level and player hasn't appeared yet

  if _is_dead:
    _resurrect()


func _on_scene_manager_load_complete(_incoming_scene) -> void:
  _enable_movement()
