class_name PurpleSlime extends Node2D

@export var move_speed: float = 60.0
@export var attack_damage: int = 1

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _direction: int = 1


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
