class_name PurpleSlime extends CharacterBody2D

@export var move_speed: float = 60.0
@export var attack_strength: int = 20
@export var defence_strength: int = 5
@export var health: int = 60

# Sensors and physics
@onready var _physics_collider: CollisionShape2D = $PhysicsCollider
#@onready var _enemy_sensor: RayCast2D = $EnemySensor
@onready var _wall_sensor_left: RayCast2D = $WallSensorLeft
@onready var _wall_sensor_right: RayCast2D = $WallSensorRight
@onready var _enemy_sensor_collider: CollisionShape2D = $EnemySensor/CollisionShape2D
@onready var _enemy_tracker_collider: CollisionShape2D = $EnemyTracker/CollisionShape2D

# Sprites
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _alerted_sprite: Sprite2D = $AlertedSprite

# Timers
@onready var _stun_timer: Timer = $StunTimer
@onready var _attack_timer: Timer = $AttackTimer
@onready var _enemy_tracker_timer: Timer = $EnemyTrackerTimer

# Health
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _health: int = health

const _projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")
var _projectile: Projectile = null

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _direction: int = 1
var _is_stunned: bool = false
var _enemy: Node = null
var _enemy_in_range: bool = false
var _knockback_direction: int = 0
var _health_bar_style_box: StyleBoxFlat = StyleBoxFlat.new()
#var _enemy_sensor_initial_pos: float = 0.0
var _enemy_sensor_collider_initial_pos: float = 0.0

var _flipped: bool = false

# This enemy extends CharacterBody2D, which is a kinematic style character controller:
# https://docs.godotengine.org/en/stable/tutorials/physics/kinematic_character_2d.html
# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
# Demos:
# - Kinematic Character 2D Demo: https://godotengine.org/asset-library/asset/2719
# - RigidBody Character 3D Demo: https://godotengine.org/asset-library/asset/2750


func _ready() -> void:
  _alerted_sprite.visible = false
  #_enemy_sensor_initial_pos = _enemy_sensor.target_position.x
  _enemy_sensor_collider_initial_pos = _enemy_sensor_collider.position.x
  _enemy_tracker_collider.disabled = true

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
  #_sense_enemy()
  var enemy_visible: bool = _enemy != null and _enemy_in_range

  if enemy_visible:
    _flip(_enemy.global_position.x < global_position.x) # Flip to face target
  else:
    # This enemy moves between waypoints but raycasts are still necessary for when it chases
    # the player outside of the waypoint containment area or gets knocked outside of it
    if _wall_sensor_left.is_colliding(): _direction = 1
    if _wall_sensor_right.is_colliding(): _direction = -1
    _flip(_direction < 0)

  _alerted_sprite.visible = enemy_visible

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

  # Apply a one-time knock-back force this physics frame
  if _knockback_direction != 0:
    velocity.y -= 150
    if _knockback_direction > 0:
      velocity.x = 80
    else:
      velocity.x = -80
    _knockback_direction = 0

  # If stunned, then this enemy is probably still being knocked back. Otherwise,
  # continue to partol until a target is in sight, in which case stop moving.
  if not _is_stunned:
    # TODO: make slime chase player if no longer in range but tracker timer has not elapsed
    velocity.x = 0.0 if enemy_visible else (_direction * move_speed)

  if not is_on_floor():
    velocity.y += _gravity * delta

  move_and_slide()

  # How to detect collisions between CollisionShape2D nodes:
  # https://www.reddit.com/r/godot/comments/13cgr2b/how_to_get_collision_detected_with/
  # Instead of relying on CollisionShape2D nodes for enemy-to-player collision detection,
  # I'm now using Area2D nodes (see PurpleSlime's AttackArea and Player's HazardSensor).
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


func _on_waypoint_sensor_area_entered(area: EnemyWaypoint) -> void:
  var change_direction: bool = false

  # Ignore the waypoint if a target is in sight (continue moving past it, if necessary)
  if _enemy == null or not _enemy_in_range:
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
  GameManager.apply_camera_shake(1)


func _stun() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start()
  _animated_sprite.play("stunned")
  GameManager.apply_camera_shake(0.6)


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")


func _flip(flip: bool) -> void:
  _flipped = flip
  _animated_sprite.flip_h = flip
  # Player sensor raycast should always extend in front of this enemy, not behind
  #_enemy_sensor.target_position.x = -_enemy_sensor_initial_pos if flip else _enemy_sensor_initial_pos
  _enemy_sensor_collider.position.x = -_enemy_sensor_collider_initial_pos if flip else _enemy_sensor_collider_initial_pos


#func _sense_enemy() -> void:
  #if _enemy != null and not _enemy_sensor.is_colliding():
    ## Allow _attack_timer to elapse naturally instead of calling stop() here
    #_enemy = null

  #elif _enemy == null and _enemy_sensor.is_colliding():
    #var entityCollider: Object = _enemy_sensor.get_collider()
    #var entity: Node2D = null

    #if entityCollider != null:
      #if entityCollider is CharacterBody2D:
        #entity = entityCollider
      #else:
        #entity = entityCollider.owner

    #if entity != null and entity.has_method("take_damage"):
      #_enemy = entity
      ## Immediately restarting the timer would cause this enemy to apply immediate damage
      ## whenever the player moves out of range then back into range again. This felt too difficult.
      #if _attack_timer.is_stopped():
        #_attack_timer.start()
        #_attack(_enemy)


func _on_enemy_sensor_area_entered(area: Area2D) -> void:
  if area.owner.has_method("take_damage"):
    _enemy = area.owner
    _enemy_in_range = true
    _enemy_tracker_collider.set_deferred("disabled", false)

    # Immediately restarting the timer would cause this enemy to apply immediate damage
    # whenever the player moves out of range then back into range again, which felt too difficult
    if _attack_timer.is_stopped():
      _attack_timer.start()
      _attack(_enemy)


func _on_attack_timer_timeout() -> void:
  if _enemy == null or not _enemy_in_range:
    _attack_timer.stop()
  else:
    _attack(_enemy) # If still in range, attack again


func _attack(_entity: Node) -> void:
  _projectile = _projectile_scene.instantiate() as Projectile
  _projectile.damage = attack_strength
  _projectile.direction = Vector2(-1, 0) if _flipped else Vector2(1, 0)
  _projectile.global_position = _physics_collider.global_position
  call_deferred("add_child", _projectile)

  # Deal immediate damage:
  #if entity.has_method("take_damage"):
    #entity.take_damage(self, attack_strength)


func _on_enemy_tracker_area_entered(area: Area2D) -> void:
   if _enemy != null and _enemy == area.owner:
    _enemy_in_range = true


func _on_enemy_tracker_area_exited(area: Area2D) -> void:
  if _enemy != null and _enemy == area.owner and _enemy_tracker_timer.is_stopped():
    _enemy_tracker_timer.start()


func _on_enemy_tracker_timer_timeout() -> void:
  _enemy = null
  _enemy_in_range = false
  _enemy_tracker_collider.set_deferred("disabled", true)
