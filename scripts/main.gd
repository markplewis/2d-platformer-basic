extends Node2D

func _ready() -> void:
  GameManager.running_individual_scene = false
  GameManager.show_main_menu()
