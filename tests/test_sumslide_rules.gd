extends GdUnitTestSuite

const SumSlideRules = preload("res://src/modes/sumslide/SumSlideRules.gd")


class FixedRng:
	extends RefCounted

	var _values: Array = []
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate()

	func randi_range(from: int, to: int) -> int:
		if _values.is_empty():
			return from
		var value := int(_values[_index % _values.size()])
		_index += 1
		if value < from or value > to:
			var span := maxi(1, to - from + 1)
			value = from + (absi(value) % span)
		return value


func test_shift_board_compresses_left_without_dropping_values() -> void:
	var board := PackedInt32Array([
		0, 2, 0, 3, 4,
		5, 0, 0, 0, 1,
		0, 0, 0, 0, 0,
		9, 0, 7, 0, 0,
		0, 8, 0, 6, 0
	])
	var rng := FixedRng.new([1, 2, 3, 4, 5])
	var shifted := SumSlideRules.shift_board(board, "left", rng)

	var expected := PackedInt32Array([
		2, 3, 4, 0, 0,
		5, 1, 0, 0, 0,
		0, 0, 0, 0, 0,
		9, 7, 0, 0, 0,
		8, 6, 0, 0, 0
	])
	for i in range(expected.size()):
		assert_int(shifted[i]).is_equal(expected[i])

	assert_int(_count_non_zero(shifted)).is_equal(_count_non_zero(board))


func test_chain_clearing_resolves_multiple_passes() -> void:
	var board := PackedInt32Array([
		2, 4, 6, 8, 1,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	])
	var rng := FixedRng.new([1, 2, 3, 4, 5, 6, 7, 8, 9])
	var result := SumSlideRules.step(board, "left", 10, rng)

	assert_int(int(result.get("pairs_cleared", 0))).is_equal(2)
	assert_int(int(result.get("chains", 0))).is_equal(2)
	assert_int(int(result.get("score_delta", 0))).is_equal(20)


func test_strikes_increment_reset_and_gameover_on_three() -> void:
	var strike_1: Dictionary = SumSlideRules.apply_strike_state(0, 0, 3)
	assert_int(int(strike_1.get("strikes", -1))).is_equal(1)
	assert_bool(bool(strike_1.get("game_over", true))).is_false()

	var strike_2: Dictionary = SumSlideRules.apply_strike_state(1, 0, 3)
	assert_int(int(strike_2.get("strikes", -1))).is_equal(2)
	assert_bool(bool(strike_2.get("game_over", true))).is_false()

	var strike_3: Dictionary = SumSlideRules.apply_strike_state(2, 0, 3)
	assert_int(int(strike_3.get("strikes", -1))).is_equal(3)
	assert_bool(bool(strike_3.get("game_over", false))).is_true()

	var reset_after_clear: Dictionary = SumSlideRules.apply_strike_state(2, 1, 3)
	assert_int(int(reset_after_clear.get("strikes", -1))).is_equal(0)
	assert_bool(bool(reset_after_clear.get("game_over", true))).is_false()


func test_step_solvability_guard_ensures_at_least_one_pair() -> void:
	var board := PackedInt32Array([
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1
	])
	var rng := FixedRng.new([1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var result := SumSlideRules.step(board, "left", 10, rng)
	var stepped_board_variant: Variant = result.get("board", PackedInt32Array())
	var stepped_board := PackedInt32Array()
	if stepped_board_variant is PackedInt32Array:
		stepped_board = stepped_board_variant

	assert_bool(SumSlideRules.has_any_pairs(stepped_board, 10)).is_true()


func _count_non_zero(board: PackedInt32Array) -> int:
	var count := 0
	for value in board:
		if value > 0:
			count += 1
	return count
