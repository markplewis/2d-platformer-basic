class_name Trail
extends Line2D

# See: https://www.youtube.com/watch?v=y8bi0_Fggn0
@export var max_length: int = 20
var queue : Array

func _process(_delta: float) -> void:
  var pos = get_parent().position
  queue.push_front(pos)

  if queue.size() > max_length:
    queue.pop_back()

  clear_points()

  for point in queue:
    add_point(point)
