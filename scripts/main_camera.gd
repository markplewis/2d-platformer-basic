class_name GameCamera extends Camera2D

@export var target_node: Node2D = null


func _ready() -> void:
  GameManager.level_loading.connect(_on_game_manager_level_loading)
  GameManager.level_ready.connect(_on_game_manager_level_ready)


func _process(_delta) -> void:
  if target_node != null:
    set_position(target_node.get_position())


func _on_game_manager_level_loading(_loading_screen: LoadingScreen) -> void:
  position_smoothing_enabled = false


func _on_game_manager_level_ready(_incoming_scene: Node) -> void:
  position_smoothing_enabled = true
  position_smoothing_speed = 5.0 # Default value
