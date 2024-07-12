class_name Door extends Area2D

@export_enum("fade_to_black", "wipe_to_right", "no_transition") var transition_type: String
@export var path_to_new_scene: String # Scene we want to load when entering this door
@export var entry_door_name: String # Name of door we're entering through in the next room

var _within_range: bool = false
var _locked: bool = false


func _ready() -> void:
  Global.player_interacted.connect(_on_global_player_interacted)


# Manually-connected signals from this node


func _on_body_entered(body: Node2D) -> void:
  if body is Player:
    _within_range = true


func _on_body_exited(body: Node2D) -> void:
  if body is Player:
    _within_range = false


# Programmatically-connected signals from the Global autoload scope


func _on_global_player_interacted() -> void:
  if _within_range and not _locked:
    _locked = true
    Global.on_door_opened(self, path_to_new_scene, transition_type)
