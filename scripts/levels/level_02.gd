class_name Level02 extends BaseLevel


func _ready() -> void:
  super()
  #print("Level02")


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
