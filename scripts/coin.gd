class_name Coin
extends Area2D

@onready var _game_manager: GameManager = %GameManager
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(_body: Node2D) -> void:
  _game_manager.add_point()
  _animation_player.play("pickup")
