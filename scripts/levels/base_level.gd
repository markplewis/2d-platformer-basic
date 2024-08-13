class_name BaseLevel extends Node

@onready var _player: Player = $Player


func _ready() -> void:
  GameManager.player_dead.connect(func():
    if _player != null:
      _player.queue_free()
  )


## Because we load a new level (or reload the current level) whenever the player
## dies, there's no need to create a new player instance, since each level includes
## one by default. The commented code demonstrates how we could, however.
## See Chapter 14 - Player Death and Respawn:
## https://www.udemy.com/course/create-a-complete-2d-platformer-in-the-godot-engine/learn/lecture/28245022

#var _current_player_node: Player = null
#const _player_scene: PackedScene = preload("res://scenes/player/player.tscn")
#var _spawn_position: Vector2 = Vector2.ZERO

#func _ready() -> void:
  #_spawn_position = _player.global_position
  #GameManager.player_dead.connect(_on_player_dead)
  #_register_player(_player)

#func _register_player(player: Player) -> void:
  #_current_player_node = player
  #print("Player '%s' registered" % [_current_player_node.get_name()])

#func _create_player() -> void:
  #var player_instance: Player = _player_scene.instantiate() as Player
  #_current_player_node.add_sibling(player_instance)
  #player_instance.global_position = _spawn_position
  #_register_player(player_instance)

#func _on_player_dead() -> void:
  ### Because queue_free doesn't happen immediately, the add_sibling call in _create_player still works
  #_current_player_node.queue_free()
  #_create_player()
