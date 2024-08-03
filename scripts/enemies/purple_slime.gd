class_name PurpleSlime extends CharacterBody2D

@export var move_speed: float = 60.0
@export var attack_strength: int = 20
@export var defence_strength: int = 5
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _stun_timer: Timer = $StunTimer
@onready var _progress_bar: ProgressBar = $ProgressBar

@onready var _health: int = health

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _direction: int = 1
var _is_stunned: bool = false
var _is_attacking: bool = false
var _knockback_direction: int = 0
var _progress_bar_style_box: StyleBoxFlat = StyleBoxFlat.new()

# This enemy extends CharacterBody2D, which is a kinematic style character controller:
# https://docs.godotengine.org/en/stable/tutorials/physics/kinematic_character_2d.html
# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
# Demos:
# - Kinematic Character 2D Demo: https://godotengine.org/asset-library/asset/2719
# - RigidBody Character 3D Demo: https://godotengine.org/asset-library/asset/2750


func _ready() -> void:
  _progress_bar.max_value = _health
  _progress_bar.value = _health

  _progress_bar.add_theme_stylebox_override("fill", _progress_bar_style_box)
  _progress_bar_style_box.bg_color = Color(Color.LIME_GREEN)
  _progress_bar_style_box.border_width_left = 1
  _progress_bar_style_box.border_width_top = 1
  _progress_bar_style_box.border_width_right = 1
  _progress_bar_style_box.border_width_bottom = 1
  _progress_bar_style_box.border_color = Color(Color.BLACK)


func _physics_process(delta) -> void:
  # TODO: consider replacing these ray casts with "EnemyGoal" Area2D scene instances
  # func on_goal_entered(_area2d) -> void: _direction *= -1
  # See chapter 15: Creating an Enemy:
  # https://www.udemy.com/course/create-a-complete-2d-platformer-in-the-godot-engine/

  if _ray_cast_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _ray_cast_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  # Velocity is defined as direction * speed and represents movement measured in pixels per frame
  # (physics frames, in this case, since we're defining it within _physics_process). Acceleration
  # forces such as gravity, however, are time-based and are measured in pixels per second.
  #
  # Unlike move_and_collide, move_and_slide multiplies velocity by delta internally, so it's
  # inappropriate to do that here. Acceleration forces such as gravity, however, must be multiplied
  # by delta and added to the velocity before passing the final velocity to move_and_slide (which
  # then calculates a distance). When not using move_and_slide, both velocity and acceleration must
  # be multiplied by delta.
  #
  # https://docs.godotengine.org/en/stable/tutorials/physics/kinematic_character_2d.html
  # https://forum.godotengine.org/t/character-controller-why-only-use-delta-on-gravity-in-physicsprocess/50422/5
  # https://forum.godotengine.org/t/when-using-move-and-slide-is-it-correct-to-use-delta-for-accelleration/12437/2
  # https://forum.godotengine.org/t/acceleration-and-velocity-for-2d-character-controller/68881/2

  if _knockback_direction != 0:
    velocity.y -= 150
    if _knockback_direction > 0:
      velocity.x = 80
    else:
      velocity.x = -80
    _knockback_direction = 0

  if not _is_stunned:
    velocity.x = _direction * move_speed

  if not is_on_floor():
    velocity.y += _gravity * delta

  move_and_slide()

  # How to detect collisions between CollisionShape2D nodes:
  # https://www.reddit.com/r/godot/comments/13cgr2b/how_to_get_collision_detected_with/
  # Instead of relying on CollisionShape2D nodes for enemy-to-player collision detection,
  # I'm now using Area2D nodes (see PurpleSlime's HazardArea and Player's HazardDetectionArea).
  # This facilitates better separation of concerns and makes it easier to understand which
  # collision layers and masks each node should be assigned to. I've kept my previous code
  # commented out below, for future reference:

  #var colliding_with_player: bool = false

  #for i in get_slide_collision_count():
    #var collision: KinematicCollision2D = get_slide_collision(i)
    #var collider: Object = collision.get_collider()
    #print("Collided with ", collider.name)

    #if collider is Player and collider.has_method("take_damage"):
      #colliding_with_player = true

    #if colliding_with_player and not _is_attacking:
      #_is_attacking = true
      #collider.take_damage(self, attack_strength)

  #if not colliding_with_player:
    #_is_attacking = false


func _on_hazard_area_area_entered(area: Area2D) -> void:
  if not _is_attacking:
    var entity: Node = area.owner

    if entity != null and entity.has_method("take_damage"):
      # TODO: keep attacking on a time interval, so long as player is within Area2D
      # TODO: maybe stop moving while attacking?
      _is_attacking = true
      entity.take_damage(self, attack_strength)


func _on_hazard_area_area_exited(_area: Area2D) -> void:
  _is_attacking = false


func take_damage(attacker: Object, value: int) -> void:
  _health -= max(0, value - defence_strength)
  _progress_bar.value = _health

  if _health < health / 1.5:
    _progress_bar_style_box.bg_color = Color(Color.YELLOW)
  if _health < health / 3.0:
    _progress_bar_style_box.bg_color = Color(Color.RED)

  if _health <= 0:
    _die()
  else:
    if attacker.global_position.x > global_position.x:
      _knockback_direction = -1
    elif attacker.global_position.x < global_position.x:
      _knockback_direction = 1
    else:
      _knockback_direction = 0
    _stun()


func _stun() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start(0.5)
  _animated_sprite.play("stunned")


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")


func _die() -> void:
  queue_free()
