class_name GreenSlime extends Node2D

@export var move_speed: float = 60.0
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var _health: int = health

var _direction: int = 1


func _process(delta: float) -> void:
  if _ray_cast_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _ray_cast_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  position.x += _direction * move_speed * delta


func decrease_health(value: int = 10) -> void:
  _health -= value
  if _health <= 0:
    _die()


func _die() -> void:
  queue_free()
