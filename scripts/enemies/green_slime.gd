class_name GreenSlime extends Node2D

@export var move_speed: float = 60.0
@export var defence_strength: int = 5
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _stun_timer: Timer = $StunTimer

@onready var _health: int = health

var _direction: int = 1
var _is_stunned: bool = false


func _physics_process(delta):
  if _ray_cast_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _ray_cast_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  if not _is_stunned:
    position.x += _direction * move_speed * delta


func take_damage(value: int) -> void:
  _health -= max(0, value - defence_strength)
  if _health <= 0:
    _die()
  else:
    _stun()


func _stun() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start(0.5)
  _animated_sprite.play("stunned")


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")


func _die() -> void:
  queue_free()
