class_name Level02 extends BaseLevel


func _ready() -> void:
  super()
  #print("Level 2 ready")


func pass_data() -> String:
  return "Data from level 2"


func receive_data(_data: String) -> void:
  #print("Level 2 received: '%s'" % [data])
  pass


func init_scene() -> void:
  #print("Level 2 init")
  pass


func start_scene() -> void:
  #print("Level 2 start")
  pass
