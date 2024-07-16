class_name MainMenu extends Control

signal start_game(menu: MainMenu)

@onready var buttons_v_box: VBoxContainer = %ButtonsVBox


func _ready() -> void:
  _focus_button()


func _on_start_button_pressed() -> void:
  start_game.emit(self)


func _on_quit_button_pressed() -> void:
  get_tree().quit()


func _on_visibility_changed() -> void:
  if visible:
    _focus_button()


func _focus_button() -> void:
  if buttons_v_box:
    var button: Button = buttons_v_box.get_child(0)
    if button is Button:
      button.grab_focus()
