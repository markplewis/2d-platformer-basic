class_name GreenSlime extends Node2D

@export var move_speed: float = 60.0
@export var defence_strength: int = 5
@export var health: int = 60

@onready var _wall_sensor_left: RayCast2D = $WallSensorLeft
@onready var _wall_sensor_right: RayCast2D = $WallSensorRight
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _stun_timer: Timer = $StunTimer
@onready var _progress_bar: ProgressBar = $ProgressBar

@onready var _health: int = health

var _direction: int = 1
var _is_stunned: bool = false
var _progress_bar_style_box: StyleBoxFlat = StyleBoxFlat.new()

# This enemy extends Node2D instead of CharacterBody2D


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
  if _wall_sensor_left.is_colliding():
    _direction = 1
    _animated_sprite.flip_h = false;

  if _wall_sensor_right.is_colliding():
    _direction = -1
    _animated_sprite.flip_h = true;

  if not _is_stunned:
    position.x += _direction * move_speed * delta


func take_damage(_attacker: Object, value: int) -> void:
  _health -= max(0, value - defence_strength)
  _progress_bar.value = _health

  if _health < health / 1.5:
    _progress_bar_style_box.bg_color = Color(Color.YELLOW)
  if _health < health / 3.0:
    _progress_bar_style_box.bg_color = Color(Color.RED)

  if _health <= 0:
    _die()
  else:
    _stun()


func _die() -> void:
  queue_free()
  GameManager.apply_camera_shake(1)


func _stun() -> void:
  _is_stunned = true
  _stun_timer.stop()
  _stun_timer.start(0.5)
  _animated_sprite.play("stunned")
  GameManager.apply_camera_shake(0.6)


func _on_stun_timer_timeout() -> void:
  _is_stunned = false
  _animated_sprite.play("default")
