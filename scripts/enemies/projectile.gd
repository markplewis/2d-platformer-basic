class_name Projectile extends Area2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

var damage: int = 10
var direction: Vector2 = Vector2.ZERO
var speed: float = 80.0

var _destroyed: bool = false


func _ready() -> void:
  set_as_top_level(true)


func _physics_process(delta) -> void:
  if not _destroyed:
    position.x += direction.x * speed * delta


func _destroy() -> void:
  _destroyed = true
  _animation_player.play("destroy") # Calls queue_free() when animation ends


func _on_body_entered(body: Node2D) -> void:
  if body is TileMap:
    _destroy()


func _on_area_entered(area: Area2D) -> void:
  if area.owner.has_method("take_damage"):
    area.owner.take_damage(self, damage)
    _destroy()


func _on_timer_timeout() -> void:
  _destroy()
