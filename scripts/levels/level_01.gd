class_name Level01 extends BaseLevel


func _ready() -> void:
  super()
  #print("Level 1 ready")


func pass_data() -> String:
  return "Data from level 1"


func receive_data(_data: String) -> void:
  #print("Level 1 received: '%s'" % [data])
  pass


func init_scene() -> void:
  #print("Level 1 init")
  pass


func start_scene() -> void:
  #print("Level 1 start")
  pass
