class_name Trail extends Line2D

# See: https://www.youtube.com/watch?v=y8bi0_Fggn0

@export var target_node: Node2D = null
@export var max_length: int = 20

var _queue: Array = Array()
var _disabled: bool = false


func _process(_delta: float) -> void:
  if target_node != null and not _disabled:
    var pos: Vector2 = target_node.position
    _queue.push_front(pos)

    if _queue.size() > max_length:
      _queue.pop_back()

    clear_points()

    for point in _queue:
      add_point(point)


func clear() -> void:
  _queue.clear()
  clear_points()


func enable() -> void:
  _disabled = false
  clear()


func disable() -> void:
  _disabled = true
