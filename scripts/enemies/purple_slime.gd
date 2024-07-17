class_name PurpleSlime extends CharacterBody2D

@export var move_speed: float = 60.0
@export var attack_damage: int = 20
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _stun_timer: Timer = $StunTimer

@onready var _health: int = health

var _direction: int = 1
var _is_stunned: bool = false
var _is_attacking: bool = false

# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
# https://www.reddit.com/r/godot/comments/13cgr2b/how_to_get_collision_detected_with/


func _physics_process(_delta):
  if _ray_cast_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _ray_cast_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  if not _is_stunned:
    # move_and_slide internally multiplies by delta, so no need to do it here
    velocity.x = _direction * move_speed

  move_and_slide()

  var colliding_with_player: bool = false

  for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
    #print("I collided with ", collision.get_collider().name)

    if collider is Player and collider.has_method("decrease_health"):
      colliding_with_player = true

    if colliding_with_player and not _is_attacking:
      _is_attacking = true
      collider.decrease_health(attack_damage)

  if not colliding_with_player:
    _is_attacking = false


func decrease_health(value: int = 10) -> void:
  _health -= value
  if _health <= 0:
    _die()
    return
  _damage()


func _damage() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start(0.5)
  _animated_sprite.play("stunned")


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")


func _die() -> void:
  queue_free()
