class_name GameManager
extends Node
## General game-wide settings

@export var debug_mode: bool = false

@onready var debug: bool = OS.is_debug_build() and debug_mode
