class_name PurpleSlime extends Node2D

@export var move_speed: float = 60.0
@export var attack_damage: int = 1
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _damage_timer: Timer = $DamageTimer

@onready var _health: int = health

var _direction: int = 1
var _is_damaged: bool = false


func _process(delta: float) -> void:
  if _ray_cast_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _ray_cast_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  position.x += _direction * move_speed * delta


func _on_damage_zone_body_entered(body: Node2D) -> void:
  if body.has_method("decrease_health"):
    body.decrease_health(attack_damage)


func decrease_health(value: int = 10) -> void:
  _health -= value
  if _health <= 0:
    _die()
    return
  _damage()


func _die() -> void:
  queue_free()


func _damage() -> void:
  _is_damaged = true
  _damage_timer.stop()
  _damage_timer.start(0.5)
  _animated_sprite.play("damaged")


func _on_damage_timer_timeout() -> void:
  _is_damaged = false
  _animated_sprite.play("default")
