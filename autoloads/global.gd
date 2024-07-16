extends Node

# https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html

var debug_mode: bool = false # Change this to false before building the game

var debug: bool = OS.is_debug_build() and debug_mode
