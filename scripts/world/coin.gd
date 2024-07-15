class_name Coin extends Area2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(entity: Node2D) -> void:
  if entity.has_method("acquire_item"):
    entity.acquire_item(self)
    _animation_player.play("pickup")
