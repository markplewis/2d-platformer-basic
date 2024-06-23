class_name TrajectoryLine
extends Line2D

# https://www.youtube.com/watch?app=desktop&v=Mry6FdWnN7I
# https://www.reddit.com/r/godot/comments/qgg6dm/how_to_create_a_ballistic_trajectory_line/

@onready var game_manager: GameManager = %GameManager
@onready var timer: Timer = $Timer

var fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var max_points: int = 50


func _ready() -> void:
  if OS.is_debug_build() and game_manager.debug_mode:
    var col: Color = Color.WHITE
    col.a = 0.5
    default_color = col
    width = 1


func _on_player_jump_start(
  start_pos: Vector2,
  start_dir: float,
  duration: float,
  speed: float,
  jump_velocity: float,
  jump_gravity: float,
  fall_gravity: float,
  delta: float
) -> void:

  if OS.is_debug_build() and game_manager.debug_mode:
    clear_points()
    timer.stop()
    position = start_pos

    var point_count: int = fps * duration + 2
    var gravity: float = 0
    var vel: Vector2 = Vector2(start_dir * speed, jump_velocity)
    var pos: Vector2 = Vector2.ZERO

    for i in point_count:
      add_point(pos)
      gravity = jump_gravity if vel.y < 0 else fall_gravity

      if i > 0:
        vel.y += gravity * delta
      pos += vel * delta


func _on_player_jump_end(_jump_height_reached: float, _jump_distance_reached: float) -> void:
  if OS.is_debug_build() and game_manager.debug_mode:
    timer.stop()
    timer.start(2)


func _on_timer_timeout() -> void:
  clear_points()
