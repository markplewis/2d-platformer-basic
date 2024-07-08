class_name Level01 extends Level


func get_level_name() -> String:
  return "level_01"


func get_next_level_name() -> String:
  return "level_02"


func init(player: Player) -> void:
  player.resurrect(Vector2(0, 0))
