class_name LoadingScreen extends CanvasLayer

signal transition_in_complete

@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _timer: Timer = %Timer

var _starting_animation_name: String


func _ready() -> void:
  _progress_bar.visible = false


## Called from the SceneManager
func start_transition(animation_name: String) -> void:
  if !anim_player.has_animation(animation_name):
    push_warning("'%s' animation does not exist" % animation_name)
    animation_name = "fade_to_black"

  _starting_animation_name = animation_name
  anim_player.play(animation_name)

  # If _timer reaches the end before we finish loading, this will show the progress bar
  _timer.start()


## Called from the SceneManager
func finish_transition() -> void:
  if _timer: _timer.stop()

  # Construct second half of the transition's animation name
  var ending_animation_name: String = _starting_animation_name.replace("to", "from")

  if !anim_player.has_animation(ending_animation_name):
    push_warning("'%s' animation does not exist" % ending_animation_name)
    ending_animation_name = "fade_from_black"

  anim_player.play(ending_animation_name)

  # Once this final animation plays, we can free this scene
  await anim_player.animation_finished
  queue_free()


## Called at the end of "in" transitions on the method track of the AnimationPlayer
## Let SceneManager know that the screen is obscured and loading of the incoming scene can begin
func report_midpoint() -> void:
  transition_in_complete.emit()


## If loading takes long enough that this _timer fires, the loading bar will become visible and
## progress is displayed
func _on_timer_timeout() -> void:
  _progress_bar.visible = true


func update_bar(val: float) -> void:
  _progress_bar.value = val
