class_name Level01 extends Node

@onready var _door: Door = $DoorInLevel1
@onready var player_start_pos: Vector2 = _door.position


func pass_data() -> String:
  return "Data from level 1"


func receive_data(_data: String) -> void:
  #print(data)
  pass


func init_scene() -> void:
  #print("Init level 1")
  pass


func start_scene() -> void:
  #print("Start level 1")
  pass
