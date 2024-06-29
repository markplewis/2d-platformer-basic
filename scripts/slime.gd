class_name Slime
extends Node2D

@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var move_speed: float = 60.0

var _direction: int = 1

func _process(delta: float) -> void:
  if ray_cast_left.is_colliding():
    _direction = 1
    animated_sprite.flip_h = false;

  if ray_cast_right.is_colliding():
    _direction = -1
    animated_sprite.flip_h = true;

  position.x += _direction * move_speed * delta
