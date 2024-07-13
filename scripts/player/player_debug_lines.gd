class_name PlayerDebugLines extends Resource

# https://www.reddit.com/r/godot/comments/17d4cyg/how_do_you_draw_lines_for_visualising_the_velocity/

var _slope_line: Line2D = Line2D.new()
var _velocity_line: Line2D = Line2D.new()
var _floor_normal_line: Line2D = Line2D.new()


func init(entity: CharacterBody2D, velocity_line_pos: Vector2) -> void:
  _slope_line.position = Vector2.ZERO
  _slope_line.default_color = Color.WHITE
  _slope_line.width = 1

  _velocity_line.position = velocity_line_pos
  _velocity_line.default_color = Color.CHARTREUSE
  _velocity_line.width = 1

  _floor_normal_line.position = Vector2.ZERO
  _floor_normal_line.default_color = Color.INDIAN_RED
  _floor_normal_line.width = 1

  entity.add_child(_slope_line)
  entity.add_child(_velocity_line)
  entity.add_child(_floor_normal_line)


func draw(on_floor: bool, floor_normal: Vector2, floor_angle: float, velocity: Vector2) -> void:
  _slope_line.clear_points()
  _velocity_line.clear_points()
  _floor_normal_line.clear_points()

  if on_floor:
    _slope_line.add_point(Vector2.from_angle(floor_angle) * -10)
    _slope_line.add_point(Vector2.from_angle(floor_angle) * 10)

    _velocity_line.add_point(Vector2.ZERO)
    _velocity_line.add_point(velocity.normalized() * 15)

    _floor_normal_line.add_point(Vector2.ZERO)
    _floor_normal_line.add_point(floor_normal * 20)
