class_name Level02 extends Level

@onready var _door: Door = $DoorInLevel2
@onready var player_start_pos: Vector2 = _door.position


func pass_data() -> String:
  return "Data from level 2"


func receive_data(_data: String) -> void:
  #print(data)
  pass


func init_scene() -> void:
  #print("Init level 2")
  pass


func start_scene() -> void:
  #print("Start level 2")
  pass
