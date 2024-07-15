class_name KillZone extends Area2D


func _on_body_entered(entity: Node2D) -> void:
  if entity.has_method("die"):
    entity.die()
