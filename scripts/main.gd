class_name Main extends Node2D

var _main_menu: MainMenu = null


func _ready() -> void:
  SceneManager.scene_added.connect(_on_scene_manager_scene_added)


func _on_main_menu_start_game(menu: MainMenu) -> void:
  _main_menu = menu
  SceneManager.swap_scenes("res://scenes/levels/level_01.tscn", "fade_to_black")


func _on_scene_manager_scene_added(_incoming_scene, _loading_screen) -> void:
  if _main_menu != null and _main_menu.visible:
    _main_menu.hide()


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
