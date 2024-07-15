class_name Door extends Area2D

@export_enum("fade_to_black", "wipe_to_right", "no_transition") var transition_type: String
@export var path_to_new_scene: String # Scene we want to load when entering this door
@export var entry_door_name: String # Name of door we're entering through in the next room


func _on_body_entered(entity: Node2D) -> void:
  if entity.has_signal("interacted") and not entity.interacted.is_connected(_on_entity_interacted):
    entity.interacted.connect(_on_entity_interacted)


func _on_body_exited(entity: Node2D) -> void:
  if entity.has_signal("interacted") and entity.interacted.is_connected(_on_entity_interacted):
    entity.interacted.disconnect(_on_entity_interacted)


func _on_entity_interacted(entity: Node2D) -> void:
  if entity.has_method("open_door"):
    entity.open_door({
      "door": self,
      "path_to_new_scene": path_to_new_scene,
      "transition_type": transition_type
    })
