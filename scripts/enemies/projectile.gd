class_name Projectile extends Area2D

var damage: int = 10
var direction: Vector2 = Vector2.ZERO
var speed: float = 80.0


func _ready() -> void:
  set_as_top_level(true)


func _physics_process(delta) -> void:
  position.x += direction.x * speed * delta


func _on_body_entered(body: Node2D) -> void:
  if body is TileMap:
    queue_free()


func _on_area_entered(area: Area2D) -> void:
  if area.owner.has_method("take_damage"):
    area.owner.take_damage(self, damage)
    queue_free()


func _on_timer_timeout() -> void:
  queue_free()
