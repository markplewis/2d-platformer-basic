class_name GameCamera extends Camera2D

@export var target_node: Node2D = null


func _ready() -> void:
  # Smoothing is disabled by default and the level_ready signal doesn't
  # get emitted when the game starts via the "Run Current Scene" button
  if GameManager.running_individual_scene:
    position_smoothing_enabled = true

  GameManager.level_loading.connect(_on_game_manager_level_loading)
  GameManager.level_loaded.connect(_on_game_manager_level_loaded)
  GameManager.level_ready.connect(_on_game_manager_level_ready)


func _process(_delta) -> void:
  if target_node != null:
    set_position(target_node.get_position())


func _on_game_manager_level_loading(_loading_screen: LoadingScreen) -> void:
  position_smoothing_enabled = false


func _on_game_manager_level_loaded(_loaded_scene: Node, _loading_screen: LoadingScreen) -> void:
  position_smoothing_enabled = false


func _on_game_manager_level_ready(_incoming_scene: Node) -> void:
  position_smoothing_enabled = true


## This didn't really work but it contains some useful bits
#func _main_scene_is_running() -> bool:
  #var current: Node = get_tree().current_scene
  #if current != null:
    #print(current)
    #print(current.scene_file_path)
    #print(ProjectSettings.get_setting("application/run/main_scene"))
    #return current.scene_file_path == ProjectSettings.get_setting("application/run/main_scene")
  #return true
