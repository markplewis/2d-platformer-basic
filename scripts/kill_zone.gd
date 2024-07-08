class_name KillZone extends Area2D

@onready var _timer: Timer = $Timer

var _body: Node2D = null


func _on_body_entered(body: Node2D) -> void:
  if _body == null:
    _body = body

    Engine.time_scale = 0.5
    _timer.start()

    if _body.has_method("kill"):
      _body.kill()


func _on_timer_timeout() -> void:
  Engine.time_scale = 1

  if _body.has_method("killed"):
    _body.killed()

  _body = null
