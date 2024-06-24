class_name InputHandler
extends Node


func get_move_direction() -> float:
  # Range between -1.0 and 1.0
  return Input.get_axis("move_left", "move_right")


func get_run_button_pressed() -> bool:
  return Input.is_action_pressed("run")


func get_jump_button_pressed() -> bool:
  return Input.is_action_just_pressed("jump")


#func get_jump_button_released() -> bool:
  #return Input.is_action_just_released("jump")
