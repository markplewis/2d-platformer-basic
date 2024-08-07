class_name GameCamera extends Camera2D

@export var target_node: Node2D = null
@export var shake_noise: FastNoiseLite

# See Chapter 32 - Camera shake:
# https://www.udemy.com/course/create-a-complete-2d-platformer-in-the-godot-engine/?couponCode=ST10MT8624
const _noise_sample_travel_rate: int = 500
const _max_shake_offset: int = 15 # In pixels
const _shake_decay: int = 2 # 200 percent per second
const _x_noise_sample_vector: Vector2 = Vector2.RIGHT
const _y_noise_sample_vector: Vector2 = Vector2.DOWN

var _x_noise_sample_position: Vector2 = Vector2.ZERO
var _y_noise_sample_position: Vector2 = Vector2.ZERO
var _current_shake_percentage: float  = 0


func _ready() -> void:
  # Smoothing is disabled by default and the level_ready signal doesn't
  # get emitted when the game starts via the "Run Current Scene" button
  if GameManager.running_individual_scene:
    position_smoothing_enabled = true

  GameManager.level_loading.connect(_on_game_manager_level_loading)
  GameManager.level_loaded.connect(_on_game_manager_level_loaded)
  GameManager.level_ready.connect(_on_game_manager_level_ready)


func _process(delta) -> void:
  if target_node != null:
    set_position(target_node.get_position())

  if _current_shake_percentage > 0:
    _x_noise_sample_position += _x_noise_sample_vector * _noise_sample_travel_rate * delta
    _y_noise_sample_position += _y_noise_sample_vector * _noise_sample_travel_rate * delta
    var x_sample: float = shake_noise.get_noise_2d(_x_noise_sample_position.x, _x_noise_sample_position.y)
    var y_sample: float = shake_noise.get_noise_2d(_y_noise_sample_position.x, _y_noise_sample_position.y)
    var shake_offset: Vector2 = Vector2(x_sample, y_sample) * _max_shake_offset * pow(_current_shake_percentage, 2)
    #var shake_offset: Vector2 = Vector2(x_sample, y_sample) * _max_shake_offset * _current_shake_percentage
    offset = shake_offset
    _current_shake_percentage = clamp(_current_shake_percentage - _shake_decay * delta, 0, 1)


func apply_shake(percentage: float) -> void:
  _current_shake_percentage = clamp(_current_shake_percentage + percentage, 0, 1)


func _on_game_manager_level_loading(_loading_screen: LoadingScreen) -> void:
  position_smoothing_enabled = false


func _on_game_manager_level_loaded(_loaded_scene: Node, _loading_screen: LoadingScreen) -> void:
  position_smoothing_enabled = false


func _on_game_manager_level_ready(_incoming_scene: Node) -> void:
  position_smoothing_enabled = true


## This didn't really work but it contains some useful bits
#func _main_scene_is_running() -> bool:
  #var current: Node = get_tree().current_scene
  #if current != null:
    #print(current)
    #print(current.scene_file_path)
    #print(ProjectSettings.get_setting("application/run/main_scene"))
    #return current.scene_file_path == ProjectSettings.get_setting("application/run/main_scene")
  #return true
