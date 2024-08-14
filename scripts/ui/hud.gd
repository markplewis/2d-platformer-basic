class_name HUD extends Control

@onready var _stats_label: Label = %StatsLabel
@onready var _progress_bar: ProgressBar = %ProgressBar

var _progress_bar_style_box: StyleBoxFlat = StyleBoxFlat.new()

var _health_initial: int
var _health: int
var _score: int

var _jump_start_dir: float
var _jump_start_pos: Vector2
var _jump_end_pos: Vector2

var _jump_height: float
var _jump_height_percent: float
var _jump_distance: float
var _jump_distance_percent: float


func _ready() -> void:
  _health_initial = GameManager.get_max_health()
  _progress_bar.max_value = _health_initial
  _progress_bar.add_theme_stylebox_override("fill", _progress_bar_style_box)

  _on_player_health_changed(GameManager.get_health())
  _on_player_score_changed(GameManager.get_score())

  _reset_jump_stats()
  _update_text()

  GameManager.player_jump_started.connect(_on_player_jump_started)
  GameManager.player_jump_ended.connect(_on_player_jump_ended)
  GameManager.player_health_changed.connect(_on_player_health_changed)
  GameManager.player_score_changed.connect(_on_player_score_changed)
  GameManager.player_dying.connect(_on_player_dying)


func _reset_jump_stats() -> void:
  _jump_start_dir = 0
  _jump_start_pos = Vector2.ZERO
  _jump_end_pos = Vector2.ZERO

  _jump_height = 0
  _jump_height_percent = 0
  _jump_distance = 0
  _jump_distance_percent = 0


func _update_text() -> void:
  # Determine whether player landed beyond their starting jump position or behind it
  var multiplier: float = 1

  var moved_right: bool = _jump_end_pos.x > _jump_start_pos.x
  var moved_left: bool = _jump_end_pos.x < _jump_start_pos.x

  var stated_moving_right: bool = _jump_start_dir == 1
  var stated_moving_left: bool = _jump_start_dir == -1
  var did_not_start_moving: bool = _jump_start_dir == 0

  if (stated_moving_right and moved_right) or (stated_moving_left and moved_left):
    multiplier = 1

  if (stated_moving_right and moved_left) or (stated_moving_left and moved_right):
    multiplier = -1

  if did_not_start_moving:
    multiplier = 1

  var format_string: String = """
    Score: %s
    Jump height: %s (%s%%)
    Jump distance: %s (%s%%)
  """
  _stats_label.text = format_string.dedent().strip_edges() % [
    _score,
    _jump_height,
    _jump_height_percent,
    _jump_distance * multiplier,
    _jump_distance_percent
  ]


func _on_player_jump_started(_dict: Dictionary) -> void:
  _reset_jump_stats()
  _update_text()


func _on_player_jump_ended(dict: Dictionary) -> void:
  _jump_start_dir = dict.start_dir
  _jump_start_pos = dict.start_pos
  _jump_end_pos = dict.end_pos
  _jump_height = round(dict.height_reached)
  _jump_height_percent = dict.height_percent_reached
  _jump_distance = round(dict.distance_reached)
  _jump_distance_percent = dict.distance_percent_reached
  _update_text()


func _on_player_health_changed(health: int) -> void:
  _health = health
  _progress_bar.value = _health

  if _health < _health_initial / 3.0:
    _progress_bar_style_box.bg_color = Color(Color.FIREBRICK)
  elif _health < _health_initial / 1.5:
    _progress_bar_style_box.bg_color = Color(Color.GOLDENROD)
  else:
    _progress_bar_style_box.bg_color = Color(Color.WEB_GREEN)

  _update_text()


func _on_player_score_changed(score: int) -> void:
  _score = score
  _update_text()


func _on_player_dying() -> void:
  _reset_jump_stats()
  _update_text()
