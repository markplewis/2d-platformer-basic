class_name InputHandler
extends Node


func get_move_direction() -> float:
  return Input.get_axis("move_left", "move_right") # Range between -1.0 and 1.0


func get_run_button_pressed() -> bool:
  return Input.is_action_pressed("run")


func get_jump_button_just_pressed() -> bool:
  return Input.is_action_just_pressed("jump")


func get_jump_button_pressed() -> bool:
  return Input.is_action_pressed("jump")
