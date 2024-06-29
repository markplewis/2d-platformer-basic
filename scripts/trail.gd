class_name Trail
extends Line2D

# See: https://www.youtube.com/watch?v=y8bi0_Fggn0

@export var max_length: int = 20

var _queue : Array

func _process(_delta: float) -> void:
  var pos = get_parent().position
  _queue.push_front(pos)

  if _queue.size() > max_length:
    _queue.pop_back()

  clear_points()

  for point in _queue:
    add_point(point)
