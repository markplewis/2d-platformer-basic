class_name KillZone
extends Area2D

@onready var _timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
  Engine.time_scale = 0.5
  body.get_node("CollisionShape").queue_free()
  _timer.start()

  if body.has_method("die"):
    body.die()

func _on_timer_timeout() -> void:
  Engine.time_scale = 1
  get_tree().reload_current_scene()
