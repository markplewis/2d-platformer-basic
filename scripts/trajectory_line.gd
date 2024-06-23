class_name TrajectoryLine
extends Line2D

# var fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")


func _ready() -> void:
  if OS.is_debug_build():
    default_color = Color.AQUAMARINE
    width = 1


func _on_player_jump_preview(
    global_position: Vector2,
    move_direction: float,
    run_modifier_active: bool,
    air_speed: float,
    air_speed_running: float,
    jump_velocity: float,
    jump_gravity: float,
    fall_gravity: float,
    delta: float
  ) -> void:

  # print("Player jumped")

  if OS.is_debug_build():
    position = global_position
    clear_points()

    # print("---------------------------")
    var max_points: int = 50
    var speed: float = air_speed_running if run_modifier_active else air_speed
    var gravity: float = 0
    var vel: Vector2 = Vector2(move_direction * speed, jump_velocity)
    var pos: Vector2 = Vector2.ZERO

    for i in max_points:
      # print(vel)
      add_point(pos)
      gravity = jump_gravity if vel.y < 0 else fall_gravity

      if i > 0:
        vel.y += gravity * delta
      pos += vel * delta


func _on_player_jump_end() -> void:
  # print("Player landed")

  if OS.is_debug_build():
    get_tree().create_timer(0.5).timeout.connect(on_timeout)


func on_timeout() -> void:
   clear_points()

