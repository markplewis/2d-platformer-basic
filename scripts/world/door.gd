class_name Door extends Area2D

@export_enum("fade_to_black", "wipe_to_right", "no_transition") var transition_type: String
@export var level_index: int # Level we want to load when entering this door
@export var entry_door_name: String # Name of door we're entering through in the next room


func _on_body_entered(body: Node2D) -> void:
  if body.has_signal("interacted") and not body.interacted.is_connected(_on_body_interacted):
    body.interacted.connect(_on_body_interacted)


func _on_body_exited(body: Node2D) -> void:
  if body.has_signal("interacted") and body.interacted.is_connected(_on_body_interacted):
    body.interacted.disconnect(_on_body_interacted)


func _on_body_interacted(body: Node2D) -> void:
  if body.has_method("open_door"):
    body.open_door({
      "door": self,
      "level_index": level_index,
      "transition_type": transition_type
    })
