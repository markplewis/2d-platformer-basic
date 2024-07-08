class_name TrajectoryLine extends Line2D

# https://www.youtube.com/watch?app=desktop&v=Mry6FdWnN7I
# https://www.reddit.com/r/godot/comments/qgg6dm/how_to_create_a_ballistic_trajectory_line/

@onready var _timer: Timer = $Timer

var _fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")


func _ready() -> void:
  if Global.debug:
    var col: Color = Color.WHITE
    col.a = 0.5
    default_color = col
    width = 1


func _on_player_jump_started(dict: Dictionary) -> void:
  if Global.debug:
    var start_dir: float = dict.start_dir
    var start_pos_offset: Vector2 = dict.start_pos_offset
    var duration: float = dict.duration
    var speed: float = dict.speed
    var jump_velocity: float = dict.velocity
    var rise_gravity: float = dict.rise_gravity
    var fall_gravity: float = dict.fall_gravity
    var delta: float = dict.delta

    clear_points()
    _timer.stop()
    position = start_pos_offset

    var point_count: int = round(_fps * duration + 2)
    var gravity: float = 0
    var vel: Vector2 = Vector2(start_dir * speed, jump_velocity)
    var pos: Vector2 = Vector2.ZERO

    for i in point_count:
      add_point(pos)
      gravity = rise_gravity if vel.y < 0 else fall_gravity

      if i > 0:
        vel.y += gravity * delta
      pos += vel * delta


func _on_player_jump_ended(_dict: Dictionary) -> void:
  if Global.debug:
    _timer.stop()
    _timer.start(2)


func _on_timer_timeout() -> void:
  if Global.debug:
    clear_points()


func _on_player_resurrected() -> void:
  if Global.debug:
    _timer.stop()
    clear_points()
