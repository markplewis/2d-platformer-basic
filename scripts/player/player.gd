class_name Player extends CharacterBody2D

signal interacted(entity: Node2D) ## Needed for door.gd

@export var rotate_on_slopes: bool = true

## Ways to access the scene's root node:
#@onready var _root_node: Node = $"/root/Main"
#@onready var _root_node: Node = get_node(^"/root/Main")
#@onready var _root_node: Node = self.owner

## Input
@onready var _input_handler: InputHandler = $InputHandler
@onready var _movement_handler: MovementHandler = $MovementHandler
@onready var _jump_handler: JumpHandler = $JumpHandler
@onready var _damage_timer: Timer = $DamageTimer

var _controls_disabled: bool = false

## Physics and visuals
@onready var _sprite_container: Node2D = $SpriteContainer
@onready var _animated_sprite: AnimatedSprite2D = $SpriteContainer/AnimatedSprite
@onready var _collider: CollisionShape2D = $Collider
@onready var _trail: Trail = $Trail

## Sensors
@onready var _attack_range_sensor_left: RayCast2D = $AttackRangeSensorLeft
@onready var _attack_range_sensor_right: RayCast2D = $AttackRangeSensorRight
@onready var _ground_sensor: RayCast2D = $GroundSensor

## Debugging
const _player_debug_lines_class: Resource = preload("res://scripts/player/player_debug_lines.gd")
@onready var _player_debug_lines: PlayerDebugLines = _player_debug_lines_class.new()

## State
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
var _is_attacking: bool = false
var _attack_target: Node = null

const _attack_strength_default: int = 15
const _defence_strength_default: int = 5

var _attack_strength: int = _attack_strength_default
var _defence_strength: int = _defence_strength_default


func _ready() -> void:
  if GameManager.debug and not _is_dead:
    _player_debug_lines.init(self, _collider.position)


func _process(_delta: float) -> void:
  if GameManager.debug and not _is_dead:
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

  _attack_collision_check()

  if _pause_button_just_pressed:
    GameManager.pause_game()

  var collision_shape_pos: Vector2 = Vector2.ZERO if _is_dead else _collider.global_position

  ## Vertical velocity
  var jump_values: Dictionary = _jump_handler.handle_jump(
    self,
    collision_shape_pos,
    _jump_button_pressed,
    _jump_button_just_pressed,
    #_jump_button_released,
    _jump_button_just_released,
    _move_direction,
    _run_button_pressed,
    delta
  )
  var new_velocity_y: float = jump_values.velocity_y
  var move_speed: float = jump_values.move_speed

  ## Horizontal velocity
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
  #up_direction = Vector2.UP
  #rotation = 0.0

  ## https://www.reddit.com/r/godot/comments/1agit6k/why_is_the_characterbody2d_property_max_floor/
  if _on_floor and _ground_sensor.is_colliding():
    _floor_normal = _ground_sensor.get_collision_normal()
    _floor_angle = Vector2.UP.angle_to(_floor_normal)
    #print("Angle: " + str(round(abs(rad_to_deg(_floor_angle)))))
    #print("Max: " + str(rad_to_deg(floor_max_angle)))

    if _floor_angle <= floor_max_angle and rotate_on_slopes:
      _sprite_container.rotation = _floor_angle
      #up_direction = _floor_normal
      #rotation = _floor_angle
      #rotation = lerp_angle(rotation, _floor_angle, delta * 20.0)
      #velocity = raw_velocity.rotated(_floor_angle)


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
  elif _is_attacking:
    if _animated_sprite.animation != "attack": # This animation shouldn't loop
      _animated_sprite.play("attack")
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


## Death


func _die() -> void:
  if not _is_dead:
    _is_dead = true;
    _disable_movement()
    _disable_collider()
    velocity.y = -150.0
    GameManager.apply_camera_shake(1)
    GameManager.on_player_dying()

    get_tree().create_timer(0.6).timeout.connect(func():
      _trail.disable()
      GameManager.on_player_dead()
    )


func _on_hazard_sensor_area_entered(area: Area2D) -> void:
  if area is HazardArea and area.instant_death:
    _die()
  #else:
    #print("Hazard damage!")


## Interactions


func open_door(dict: Dictionary) -> void:
  _disable_movement()
  dict.merge({ "entity": self })
  GameManager.on_player_opened_door(dict)


func _attack_collision_check() -> void:
  var entity_collider: Object = null
  var entity: Node2D = null

  if _attack_range_sensor_left.is_colliding() and _last_move_direction < 0:
    entity_collider = _attack_range_sensor_left.get_collider()

  if _attack_range_sensor_right.is_colliding() and _last_move_direction > 0:
    entity_collider = _attack_range_sensor_right.get_collider()

  if entity_collider != null:
    if entity_collider is CharacterBody2D:
      entity = entity_collider
    else:
      entity = entity_collider.owner

  if entity != null and entity.has_method("take_damage") and _interact_button_just_pressed and not _is_attacking:
    _is_attacking = true
    _attack_target = entity
    # Wait until half-way through the animation to attack (see signal handler, below)


func _on_animated_sprite_frame_changed() -> void:
  if (
    _animated_sprite != null and
    _animated_sprite.animation == "attack" and
    _animated_sprite.get_frame() == 2 and
    _attack_target != null
  ):
    _attack_target.take_damage(self, _attack_strength)
    _attack_target = null


func _on_animated_sprite_animation_finished() -> void:
  if _animated_sprite.animation == "attack":
    _is_attacking = false
    _attack_target = null


## Score


func acquire_item(item: Node2D) -> void:
  if item is Coin:
    GameManager.set_score(GameManager.increase_score(1))


## Health


func take_damage(_attacker: Object, damage: int) -> void:
  var new_value: int = GameManager.decrease_health(max(0, damage - _defence_strength))
  var previous_value: int = GameManager.get_health()

  if new_value <= 0:
    _die() ## Health gets set to zero within _die() method
  elif new_value < previous_value:
    _damage()
    GameManager.set_health(new_value)


func _damage() -> void:
  _is_damaged = true
  _damage_timer.stop()
  _damage_timer.start(0.5)
  GameManager.apply_camera_shake(0.6)


func _on_damage_timer_timeout() -> void:
  _is_damaged = false


## Disable/enable stuff


func _disable_movement() -> void:
  velocity = Vector2.ZERO
  _controls_disabled = true


## Unused
#func _enable_movement() -> void:
  #_controls_disabled = false
  #_trail.enable()


func _disable_collider() -> void:
  _collider.set_deferred("disabled", true)


## Unused
## Due to the following bug, we must wait exactly 2 physics frames before re-enabling the
## player's collision shape. Otherwise, if the player died by falling into a "KillZone"
## (an Area2D node with a WorldBoundary collision shape), then the Area2D's body_entered signal
## will fire twice (once when the player touches it and again when the level/scene re-loads,
## even if the player's position has changed by that point and they're no longer touching it).
## https://github.com/godotengine/godot/issues/88592#issuecomment-1958670810
## https://github.com/godotengine/godot/issues/61584
## https://github.com/godotengine/godot/issues/14578
## https://github.com/godotengine/godot/issues/18748
## https://www.reddit.com/r/godot/comments/1d285xl/player_is_dying_twice/
#func _enable_collider() -> void:
  #await get_tree().physics_frame
  #await get_tree().physics_frame
  #_collider.set_deferred("disabled", false)
