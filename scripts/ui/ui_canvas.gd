class_name UICanvas extends CanvasLayer

signal game_started()
signal game_resumed()

@onready var _main_menu: MainMenu = $MainMenu
@onready var _pause_menu: PauseMenu = $PauseMenu


func hide_all() -> void:
  _main_menu.hide()
  _pause_menu.hide()


func show_main_menu() -> void:
  _main_menu.show()
  _pause_menu.hide()


func show_pause_menu() -> void:
  _main_menu.hide()
  _pause_menu.show()


func _on_main_menu_game_started() -> void:
  game_started.emit()


func _on_pause_menu_game_resumed() -> void:
  game_resumed.emit()
