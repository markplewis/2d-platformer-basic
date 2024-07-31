class_name GameCamera extends Camera2D

@export var target_node: Node2D = null


func _process(_delta) -> void:
  if target_node != null:
    set_position(target_node.get_position())


#class_name GameCamera extends Camera2D
#
#@export var target_node: Node2D = null
#
#@onready var _current_target: Node2D = target_node
#
#
#func _ready() -> void:
  #GameManager.level_load_start.connect(_on_game_manager_level_load_start)
  #GameManager.level_loaded.connect(_on_game_manager_level_loaded)
  #GameManager.level_load_complete.connect(_on_game_manager_level_load_complete)
#
#
#func _process(_delta) -> void:
  #if _current_target:
    #set_position(_current_target.get_position())
#
#
#func _on_game_manager_level_load_start(_loading_screen: LoadingScreen) -> void:
  #_current_target = null
  #position_smoothing_enabled = false
#
#
#func _on_game_manager_level_loaded(_incoming_scene: Node, _loading_screen: LoadingScreen) -> void:
  #_current_target = target_node
#
#
#func _on_game_manager_level_load_complete(_incoming_scene: Node) -> void:
  #position_smoothing_enabled = true
