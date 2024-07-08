class_name InputHandler extends Node

var _jump_button_released: bool = false


func _input(event: InputEvent) -> void:
  _jump_button_released = event.is_action_released("jump")


func get_jump_button_released() -> bool:
  return _jump_button_released


func get_jump_button_just_released() -> bool:
  return Input.is_action_just_released("jump")


func get_jump_button_pressed() -> bool:
  return Input.is_action_pressed("jump")


func get_jump_button_just_pressed() -> bool:
  return Input.is_action_just_pressed("jump")


func get_run_button_pressed() -> bool:
  return Input.is_action_pressed("run")


func get_move_direction() -> float:
  return Input.get_axis("move_left", "move_right") # Range between -1.0 and 1.0


func get_interact_button_just_pressed() -> bool:
  return Input.is_action_just_pressed("interact")
