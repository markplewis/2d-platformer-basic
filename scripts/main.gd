class_name Main extends Node2D


func _on_player_opened_door(dict: Dictionary) -> void:
  SceneManager.swap_scenes(dict.path_to_new_scene, dict.transition_type)


func _on_player_acquired_item(dict: Dictionary) -> void:
  if dict.item is Coin:
    if dict.entity.has_method("increase_score"):
      dict.entity.increase_score(1)


func _on_player_dying() -> void:
  Engine.time_scale = 0.5


func _on_player_dead() -> void:
  Engine.time_scale = 1
  SceneManager.swap_scenes("", "fade_to_black") # Reload current scene
