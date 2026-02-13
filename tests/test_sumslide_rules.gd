extends GdUnitTestSuite

const SumSlideRules = preload("res://src/modes/sumslide/SumSlideRules.gd")


class FixedRng:
	extends RefCounted

	var _values: Array = []
	var _index := 0

	func _init(values: Array) -> void:
		_values = values.duplicate()

	func randi_range(_from: int, _to: int) -> int:
		if _values.is_empty():
			return 1
		var value := int(_values[_index % _values.size()])
		_index += 1
		return value


func test_shift_board_left_moves_cells_and_spawns_on_right() -> void:
	var board := PackedInt32Array([
		1, 2, 3, 4, 5,
		6, 7, 8, 9, 10,
		11, 12, 13, 14, 15,
		16, 17, 18, 19, 20,
		21, 22, 23, 24, 25
	])
	var rng := FixedRng.new([9, 8, 7, 6, 5])

	var shifted := SumSlideRules.shift_board(board, "left", rng)
	var expected := PackedInt32Array([
		2, 3, 4, 5, 9,
		7, 8, 9, 10, 8,
		12, 13, 14, 15, 7,
		17, 18, 19, 20, 6,
		22, 23, 24, 25, 5
	])

	for i in range(expected.size()):
		assert_int(shifted[i]).is_equal(expected[i])


func test_find_pairs_detects_horizontal_and_vertical_pairs() -> void:
	var board := PackedInt32Array()
	board.resize(SumSlideRules.BOARD_CELLS)
	board[SumSlideRules.index_of(0, 0)] = 4
	board[SumSlideRules.index_of(0, 1)] = 6
	board[SumSlideRules.index_of(2, 2)] = 7
	board[SumSlideRules.index_of(3, 2)] = 3

	var pairs := SumSlideRules.find_pairs(board, 10)

	assert_int(pairs.size()).is_equal(2)
	assert_bool(_has_pair(pairs, SumSlideRules.index_of(0, 0), SumSlideRules.index_of(0, 1))).is_true()
	assert_bool(_has_pair(pairs, SumSlideRules.index_of(2, 2), SumSlideRules.index_of(3, 2))).is_true()


func test_clear_pairs_sets_cells_to_zero() -> void:
	var board := PackedInt32Array()
	board.resize(SumSlideRules.BOARD_CELLS)
	board[SumSlideRules.index_of(0, 0)] = 4
	board[SumSlideRules.index_of(0, 1)] = 6
	board[SumSlideRules.index_of(1, 1)] = 9

	var pairs := [
		{"a": SumSlideRules.index_of(0, 0), "b": SumSlideRules.index_of(0, 1)}
	]
	var cleared := SumSlideRules.clear_pairs(board, pairs)

	assert_int(cleared[SumSlideRules.index_of(0, 0)]).is_equal(0)
	assert_int(cleared[SumSlideRules.index_of(0, 1)]).is_equal(0)
	assert_int(cleared[SumSlideRules.index_of(1, 1)]).is_equal(9)


func test_step_scoring_allows_combo_increment_and_reset() -> void:
	var board := PackedInt32Array([
		1, 4, 6, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
		1, 1, 1, 1, 1
	])
	var rng := FixedRng.new([1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	var combo := 0
	var total_score := 0

	var first := SumSlideRules.step(board, "left", 10, rng)
	var first_pairs := int(first.get("pairs_cleared", 0))
	var first_delta := int(first.get("score_delta", 0))

	if first_pairs > 0:
		combo += 1
		total_score += first_delta + first_pairs * (5 * combo)
	else:
		combo = 0

	assert_int(first_pairs).is_equal(1)
	assert_int(first_delta).is_equal(10)
	assert_int(total_score).is_equal(15)
	assert_int(combo).is_equal(1)

	var second := SumSlideRules.step(first.get("board"), "left", 10, rng)
	var second_pairs := int(second.get("pairs_cleared", 0))

	if second_pairs > 0:
		combo += 1
	else:
		combo = 0

	assert_int(second_pairs).is_equal(0)
	assert_int(combo).is_equal(0)


func test_shuffle_board_with_pair_creates_pair_within_retry_bound() -> void:
	var rng := FixedRng.new([1])
	var shuffled := SumSlideRules.shuffle_board_with_pair(10, rng, 1)

	assert_bool(SumSlideRules.has_any_pairs(shuffled, 10)).is_true()


func _has_pair(pairs: Array, a: int, b: int) -> bool:
	for pair in pairs:
		var left := int(pair.get("a", -1))
		var right := int(pair.get("b", -1))
		if (left == a and right == b) or (left == b and right == a):
			return true
	return false
