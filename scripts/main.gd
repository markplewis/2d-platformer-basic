class_name Main extends Node2D

@onready var _main_menu: MainMenu = $UICanvas/MainMenu
@onready var _pause_menu: PauseMenu = $UICanvas/PauseMenu
@onready var _hud: HUD = $UICanvas/HUD


func _ready() -> void:
  _show_main_menu()
  SceneManager.scene_added.connect(_on_scene_manager_scene_added)


func _on_main_menu_started_game() -> void:
  SceneManager.swap_scenes("res://scenes/levels/level_01.tscn", "fade_to_black")


func _on_scene_manager_scene_added(_incoming_scene, _loading_screen) -> void:
  _show_hud()


func _on_player_paused_game() -> void:
  Engine.time_scale = 0
  _show_pause_menu()


func _on_pause_menu_resumed_game() -> void:
  Engine.time_scale = 1
  _show_hud()


# Gameplay actions


func _on_player_dying() -> void:
  Engine.time_scale = 0.5


func _on_player_dead() -> void:
  Engine.time_scale = 1
  SceneManager.swap_scenes("", "fade_to_black") # Reload current scene


func _on_player_opened_door(dict: Dictionary) -> void:
  SceneManager.swap_scenes(dict.path_to_new_scene, dict.transition_type)


func _on_player_acquired_item(dict: Dictionary) -> void:
  if dict.item is Coin:
    if dict.entity.has_method("increase_score"):
      dict.entity.increase_score(1)


# Toggle element visibility


func _show_main_menu() -> void:
  _main_menu.show()
  _pause_menu.hide()
  _hud.hide()


func _show_pause_menu() -> void:
  _main_menu.hide()
  _pause_menu.show()
  _hud.hide()


func _show_hud() -> void:
  _main_menu.hide()
  _pause_menu.hide()
  _hud.show()
