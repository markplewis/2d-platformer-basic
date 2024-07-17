class_name Coin extends Area2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

# TODO: make Coin extend a new Collectable class. Each Collectable will implement an
# on_acquired(entity_who_acquired_it) method, so that it can define its own unique behaviour
# and invoke methods on the entity instance (e.g. increase_score)


func _on_body_entered(body: Node2D) -> void:
  if body.has_method("acquire_item"):
    body.acquire_item(self)
    _animation_player.play("pickup")
