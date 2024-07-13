class_name Coin extends Area2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(_body: Node2D) -> void:
  PlayerContext.increase_score(1)
  _animation_player.play("pickup")
