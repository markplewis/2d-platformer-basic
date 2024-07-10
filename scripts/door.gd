class_name Door extends Node2D

signal door_opened

# Must match the destination level's file name (e.g. "level_02")
@export var door_id: String

var _can_open_door: bool = false


func _ready() -> void:
  Global.player_interacted.connect(_on_global_player_interacted)


func _on_global_player_interacted() -> void:
  if _can_open_door:
    Global.on_player_opened_door(door_id)
    door_opened.emit(door_id)


func _on_door_area_body_entered(body: Node2D) -> void:
  if body is Player:
    _can_open_door = true


func _on_door_area_body_exited(body: Node2D) -> void:
  if body is Player:
    _can_open_door = false
