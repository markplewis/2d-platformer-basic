class_name MainCamera extends Camera2D

@export var target_node: Node2D = null

@onready var _current_target: Node2D = target_node


func _process(_delta) -> void:
  if _current_target:
    set_position(_current_target.get_position())


func _on_player_dead() -> void:
  _current_target = null
  position_smoothing_enabled = false


func _on_player_changing_level() -> void:
  _current_target = null
  position_smoothing_enabled = false


func _on_player_resurrected() -> void:
  _current_target = target_node
  # TODO: add a transition screen becuase this is too jarring
  get_tree().create_timer(1).timeout.connect(func(): position_smoothing_enabled = true)
