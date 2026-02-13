extends RefCounted
class_name SumSlideRules

const BOARD_SIZE := 5
const BOARD_CELLS := BOARD_SIZE * BOARD_SIZE
const VALUE_MIN := 1
const VALUE_MAX := 9


static func index_of(row: int, col: int) -> int:
	return row * BOARD_SIZE + col


static func create_random_board(rng: Variant) -> PackedInt32Array:
	var board := PackedInt32Array()
	board.resize(BOARD_CELLS)
	for i in range(BOARD_CELLS):
		board[i] = _rand_value(rng)
	return board


static func shift_board(board: Variant, dir: String, rng: Variant) -> PackedInt32Array:
	var source := _normalize_board(board)
	var shifted := PackedInt32Array()
	shifted.resize(BOARD_CELLS)

	match dir:
		"left":
			for row in range(BOARD_SIZE):
				for col in range(BOARD_SIZE - 1):
					shifted[index_of(row, col)] = source[index_of(row, col + 1)]
				shifted[index_of(row, BOARD_SIZE - 1)] = _rand_value(rng)
		"right":
			for row in range(BOARD_SIZE):
				for col in range(1, BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row, col - 1)]
				shifted[index_of(row, 0)] = _rand_value(rng)
		"up":
			for row in range(BOARD_SIZE - 1):
				for col in range(BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row + 1, col)]
			for col in range(BOARD_SIZE):
				shifted[index_of(BOARD_SIZE - 1, col)] = _rand_value(rng)
		"down":
			for row in range(1, BOARD_SIZE):
				for col in range(BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row - 1, col)]
			for col in range(BOARD_SIZE):
				shifted[index_of(0, col)] = _rand_value(rng)
		_:
			return source

	return shifted


static func find_pairs(board: Variant, target: int) -> Array:
	var source := _normalize_board(board)
	var pairs: Array = []

	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var value := source[index_of(row, col)]
			if value <= 0:
				continue
			if col < BOARD_SIZE - 1:
				var right_index := index_of(row, col + 1)
				var right_value := source[right_index]
				if right_value > 0 and value + right_value == target:
					pairs.append({"a": index_of(row, col), "b": right_index})
			if row < BOARD_SIZE - 1:
				var down_index := index_of(row + 1, col)
				var down_value := source[down_index]
				if down_value > 0 and value + down_value == target:
					pairs.append({"a": index_of(row, col), "b": down_index})

	return pairs


static func clear_pairs(board: Variant, pairs: Array) -> PackedInt32Array:
	var cleared := _normalize_board(board)

	for pair in pairs:
		if pair is Dictionary:
			var a := int(pair.get("a", -1))
			var b := int(pair.get("b", -1))
			if a >= 0 and a < BOARD_CELLS:
				cleared[a] = 0
			if b >= 0 and b < BOARD_CELLS:
				cleared[b] = 0
		elif pair is Array and pair.size() >= 2:
			var aa := int(pair[0])
			var bb := int(pair[1])
			if aa >= 0 and aa < BOARD_CELLS:
				cleared[aa] = 0
			if bb >= 0 and bb < BOARD_CELLS:
				cleared[bb] = 0

	return cleared


static func step(board: Variant, dir: String, target: int, rng: Variant) -> Dictionary:
	var working := shift_board(board, dir, rng)
	var total_pairs := 0

	while true:
		var pairs := find_pairs(working, target)
		if pairs.is_empty():
			break
		total_pairs += pairs.size()
		working = clear_pairs(working, pairs)
		working = refill_empties(working, rng)

	return {
		"board": working,
		"pairs_cleared": total_pairs,
		"score_delta": total_pairs * 10
	}


static func has_any_pairs(board: Variant, target: int) -> bool:
	return not find_pairs(board, target).is_empty()


static func has_potential_pair_after_any_shift(board: Variant, target: int) -> bool:
	for dir in ["left", "right", "up", "down"]:
		var shifted := _shift_without_spawn(board, dir)
		if has_any_pairs(shifted, target):
			return true
	return false


static func shuffle_board_with_pair(target: int, rng: Variant, max_retries: int = 8) -> PackedInt32Array:
	var retries := maxi(1, max_retries)
	var shuffled := PackedInt32Array()

	for _i in range(retries):
		shuffled = create_random_board(rng)
		if has_any_pairs(shuffled, target):
			return shuffled

	var forced_pair := _forced_pair_values(target)
	if forced_pair.x > 0:
		if shuffled.size() != BOARD_CELLS:
			shuffled = create_random_board(rng)
		shuffled[index_of(0, 0)] = forced_pair.x
		shuffled[index_of(0, 1)] = forced_pair.y
	return shuffled


static func refill_empties(board: Variant, rng: Variant) -> PackedInt32Array:
	var refilled := _normalize_board(board)
	for i in range(refilled.size()):
		if refilled[i] <= 0:
			refilled[i] = _rand_value(rng)
	return refilled


static func _shift_without_spawn(board: Variant, dir: String) -> PackedInt32Array:
	var source := _normalize_board(board)
	var shifted := PackedInt32Array()
	shifted.resize(BOARD_CELLS)

	match dir:
		"left":
			for row in range(BOARD_SIZE):
				for col in range(BOARD_SIZE - 1):
					shifted[index_of(row, col)] = source[index_of(row, col + 1)]
				shifted[index_of(row, BOARD_SIZE - 1)] = 0
		"right":
			for row in range(BOARD_SIZE):
				for col in range(1, BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row, col - 1)]
				shifted[index_of(row, 0)] = 0
		"up":
			for row in range(BOARD_SIZE - 1):
				for col in range(BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row + 1, col)]
			for col in range(BOARD_SIZE):
				shifted[index_of(BOARD_SIZE - 1, col)] = 0
		"down":
			for row in range(1, BOARD_SIZE):
				for col in range(BOARD_SIZE):
					shifted[index_of(row, col)] = source[index_of(row - 1, col)]
			for col in range(BOARD_SIZE):
				shifted[index_of(0, col)] = 0
		_:
			return source

	return shifted


static func _forced_pair_values(target: int) -> Vector2i:
	for left in range(VALUE_MIN, VALUE_MAX + 1):
		var right := target - left
		if right >= VALUE_MIN and right <= VALUE_MAX:
			return Vector2i(left, right)
	return Vector2i(-1, -1)


static func _normalize_board(board: Variant) -> PackedInt32Array:
	var normalized := PackedInt32Array()
	normalized.resize(BOARD_CELLS)

	if board is PackedInt32Array:
		var packed: PackedInt32Array = board
		var packed_size := mini(packed.size(), BOARD_CELLS)
		for i in range(packed_size):
			normalized[i] = int(packed[i])
	elif board is Array:
		var values: Array = board
		var array_size := mini(values.size(), BOARD_CELLS)
		for i in range(array_size):
			normalized[i] = int(values[i])

	return normalized


static func _rand_value(rng: Variant) -> int:
	if rng != null and rng.has_method("randi_range"):
		return int(rng.call("randi_range", VALUE_MIN, VALUE_MAX))
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback.randi_range(VALUE_MIN, VALUE_MAX)
