# GdUnit generated TestSuite
class_name PlayerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://scripts/player/player.gd'

# https://mikeschulze.github.io/gdUnit4/first_steps/getting-started/

func test_increase_health(increase: int, current: int, expected: int, test_parameters:= [
  [5, 100, 100], # Already maxxed out = no change
  [5, 80, 85], # Valid increase
  [-5, 80, 80] # Invalid increase = no change
]) -> void:
  var player := Player.new()
  assert_int(player._increase_health(increase, current)).is_equal(expected)
  player.free()


func test_decrease_health(decrease: int, current: int, expected: int, test_parameters:= [
  [5, 100, 95], # Valid decrease
  [110, 100, 0] # Invalid decrease = no change
]) -> void:
  var player := Player.new()
  assert_int(player._decrease_health(decrease, current)).is_equal(expected)
  player.free()


func test_increase_score(increase: int, current: int, expected: int, test_parameters:= [
  [5, 20, 25], # Valid increase
  [-5, 20, 20] # Invalid increase = no change
]) -> void:
  var player := Player.new()
  assert_int(player._increase_score(increase, current)).is_equal(expected)
  player.free()


func test_decrease_score(decrease: int, current: int, expected: int, test_parameters:= [
  [5, 20, 15], # Valid decrease
  [-5, 20, 20] # Invalid decrease = no change
]) -> void:
  var player := Player.new()
  assert_int(player._decrease_score(decrease, current)).is_equal(expected)
  player.free()
