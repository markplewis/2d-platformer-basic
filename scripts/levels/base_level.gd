class_name BaseLevel extends Node

@onready var _player: Player = %Player

const _player_scene: PackedScene = preload("res://scenes/player/player.tscn")
var _spawn_position: Vector2 = Vector2.ZERO
var _current_player_node: Player = null


func _ready() -> void:
  _spawn_position = _player.global_position
  _register_player(_player)


func _register_player(player: Player) -> void:
  _current_player_node = player
  # TODO: can I connect to GameManager.player_dead instead? Then I could delete the Player's dead signal
  _current_player_node.dead.connect(_on_player_dead)


func _create_player() -> void:
  var player_instance: Player = _player_scene.instantiate() as Player
  _current_player_node.add_sibling(player_instance)
  player_instance.global_position = _spawn_position
  _register_player(player_instance)


func _on_player_dead() -> void:
  # Doesn't happen immediately, so the add_sibling() invocation in _create_player() will still work
  _current_player_node.queue_free()
  _create_player()
