class_name PurpleSlime extends CharacterBody2D

@export var move_speed: float = 60.0
@export var attack_strength: int = 20
@export var defence_strength: int = 5
@export var health: int = 60

@onready var _ray_cast_left: RayCast2D = $RayCastLeft
@onready var _ray_cast_right: RayCast2D = $RayCastRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _stun_timer: Timer = $StunTimer
@onready var _attack_timer: Timer = $AttackTimer
@onready var _health_bar: ProgressBar = $HealthBar

@onready var _health: int = health

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _direction: int = 1
var _is_stunned: bool = false
var _attack_target: Node = null
var _knockback_direction: int = 0
var _health_bar_style_box: StyleBoxFlat = StyleBoxFlat.new()

# This enemy extends CharacterBody2D, which is a kinematic style character controller:
# https://docs.godotengine.org/en/stable/tutorials/physics/kinematic_character_2d.html
# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
# Demos:
# - Kinematic Character 2D Demo: https://godotengine.org/asset-library/asset/2719
# - RigidBody Character 3D Demo: https://godotengine.org/asset-library/asset/2750


func _ready() -> void:
  _health_bar.max_value = _health
  _health_bar.value = _health

  _health_bar.add_theme_stylebox_override("fill", _health_bar_style_box)
  _health_bar_style_box.bg_color = Color(Color.LIME_GREEN)
  _health_bar_style_box.border_width_left = 1
  _health_bar_style_box.border_width_top = 1
  _health_bar_style_box.border_width_right = 1
  _health_bar_style_box.border_width_bottom = 1
  _health_bar_style_box.border_color = Color(Color.BLACK)


func _physics_process(delta) -> void:
  if _attack_target != null:
    _animated_sprite.flip_h = _attack_target.global_position.x < global_position.x
  else:
    # This enemy moves between waypoints but I also kept the raycasts because it's possible
    # for the player to knock the enemy outside of the waypoint containment area
    if _ray_cast_left.is_colliding(): _direction = 1
    if _ray_cast_right.is_colliding(): _direction = -1
    _animated_sprite.flip_h = _direction < 0

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
    velocity.x = (_direction * move_speed) if _attack_target == null else 0.0

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


func _on_waypoint_detector_area_entered(area: EnemyWaypoint) -> void:
  var change_direction: bool = false

  if _attack_target == null:
    match area.entry_direction:
      "all":
        change_direction = true
      "left":
        if _direction > 0:
          change_direction = true
      "right":
        if _direction < 0:
          change_direction = true

  if change_direction:
    _direction *= -1


func _on_hazard_area_entered(area: Area2D) -> void:
  if _attack_target == null:
    var entity: Node = area.owner

    if entity != null and entity.has_method("take_damage"):
      _attack_target = entity
      _attack_timer.stop()
      _attack_timer.start()
      _attack(_attack_target)


func _on_hazard_area_exited(_area: Area2D) -> void:
  _attack_target = null
  _attack_timer.stop()


func _on_attack_timer_timeout() -> void:
  if _attack_target == null:
    _attack_timer.stop()
  else:
    _attack(_attack_target) # If still in attack range, attack again


func _attack(entity: Node) -> void:
  if entity.has_method("take_damage"):
    entity.take_damage(self, attack_strength)


func take_damage(attacker: Object, value: int) -> void:
  _health -= max(0, value - defence_strength)
  _health_bar.value = _health

  if _health < health / 1.5:
    _health_bar_style_box.bg_color = Color(Color.YELLOW)
  if _health < health / 3.0:
    _health_bar_style_box.bg_color = Color(Color.RED)

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


func _die() -> void:
  queue_free()


func _stun() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start()
  _animated_sprite.play("stunned")


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")
