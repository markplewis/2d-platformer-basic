class_name MainCamera extends Camera2D

@export var target_node: Node2D = null

@onready var _current_target: Node2D = target_node


func _ready() -> void:
  SceneManager.load_start.connect(_on_scene_manager_load_start)
  SceneManager.scene_added.connect(_on_scene_manager_scene_added)
  SceneManager.load_complete.connect(_on_scene_manager_load_complete)


func _process(_delta) -> void:
  if _current_target:
    set_position(_current_target.get_position())


func _on_scene_manager_load_start(_loading_screen) -> void:
  _current_target = null
  position_smoothing_enabled = false


func _on_scene_manager_scene_added(_incoming_scene, _loading_screen) -> void:
  _current_target = target_node

func _on_scene_manager_load_complete(_incoming_scene) -> void:
  #get_tree().create_timer(1).timeout.connect(func(): position_smoothing_enabled = true)
  position_smoothing_enabled = true
