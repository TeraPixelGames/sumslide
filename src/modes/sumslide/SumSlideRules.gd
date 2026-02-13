extends RefCounted
class_name SumSlideRules

const BOARD_SIZE := 5
const BOARD_CELLS := BOARD_SIZE * BOARD_SIZE
const VALUE_MIN := 1
const VALUE_MAX := 9
const DEFAULT_SPAWN_COUNT := 3
const DEFAULT_REPAIR_RETRIES := 30


static func index_of(row: int, col: int) -> int:
	return row * BOARD_SIZE + col


static func create_random_board(rng: Variant) -> PackedInt32Array:
	var board := PackedInt32Array()
	board.resize(BOARD_CELLS)
	for i in range(BOARD_CELLS):
		board[i] = _rand_value(rng)
	return board


static func shift_board(board: Variant, dir: String, _rng: Variant) -> PackedInt32Array:
	var source := _normalize_board(board)
	var shifted := PackedInt32Array()
	shifted.resize(BOARD_CELLS)

	match dir:
		"left":
			for row in range(BOARD_SIZE):
				var write_col := 0
				for col in range(BOARD_SIZE):
					var value := source[index_of(row, col)]
					if value > 0:
						shifted[index_of(row, write_col)] = value
						write_col += 1
		"right":
			for row in range(BOARD_SIZE):
				var write_col := BOARD_SIZE - 1
				for col in range(BOARD_SIZE - 1, -1, -1):
					var value := source[index_of(row, col)]
					if value > 0:
						shifted[index_of(row, write_col)] = value
						write_col -= 1
		"up":
			for col in range(BOARD_SIZE):
				var write_row := 0
				for row in range(BOARD_SIZE):
					var value := source[index_of(row, col)]
					if value > 0:
						shifted[index_of(write_row, col)] = value
						write_row += 1
		"down":
			for col in range(BOARD_SIZE):
				var write_row := BOARD_SIZE - 1
				for row in range(BOARD_SIZE - 1, -1, -1):
					var value := source[index_of(row, col)]
					if value > 0:
						shifted[index_of(write_row, col)] = value
						write_row -= 1
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
	var chains := 0

	while true:
		var pairs := find_pairs(working, target)
		if pairs.is_empty():
			break
		total_pairs += pairs.size()
		chains += 1
		working = clear_pairs(working, pairs)
		working = shift_board(working, dir, rng)

	var spawn_result: Dictionary = spawn_numbers(working, rng, DEFAULT_SPAWN_COUNT)
	var spawn_board_variant: Variant = spawn_result.get("board", working)
	working = _normalize_board(spawn_board_variant)
	var spawned_count := int(spawn_result.get("spawned", 0))
	working = ensure_board_has_pair(working, target, rng, DEFAULT_REPAIR_RETRIES)

	return {
		"board": working,
		"pairs_cleared": total_pairs,
		"score_delta": total_pairs * 10,
		"chains": chains,
		"spawned": spawned_count
	}


static func has_any_pairs(board: Variant, target: int) -> bool:
	return not find_pairs(board, target).is_empty()


static func has_potential_pair_after_any_shift(board: Variant, target: int) -> bool:
	for dir in ["left", "right", "up", "down"]:
		var shifted := shift_board(board, dir, null)
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

	var fallback := create_random_board(rng)
	return ensure_board_has_pair(fallback, target, rng, DEFAULT_REPAIR_RETRIES)


static func shuffle_preserving_distribution(board: Variant, target: int, rng: Variant, max_retries: int = DEFAULT_REPAIR_RETRIES) -> PackedInt32Array:
	var source := _normalize_board(board)
	var retries := maxi(1, max_retries)
	for _i in range(retries):
		var shuffled := _shuffle_copy(source, rng)
		if has_any_pairs(shuffled, target):
			return shuffled
		var forced := _force_pair_with_existing_values(shuffled, target, rng)
		if has_any_pairs(forced, target):
			return forced
	return ensure_board_has_pair(_shuffle_copy(source, rng), target, rng, DEFAULT_REPAIR_RETRIES)


static func spawn_numbers(board: Variant, rng: Variant, count: int) -> Dictionary:
	var working := _normalize_board(board)
	var empties: Array[int] = []
	for i in range(BOARD_CELLS):
		if working[i] <= 0:
			empties.append(i)

	if empties.is_empty() or count <= 0:
		return {
			"board": working,
			"spawned": 0
		}

	_shuffle_int_array(empties, rng)
	var spawn_total := mini(count, empties.size())
	for i in range(spawn_total):
		working[empties[i]] = _rand_value(rng)

	return {
		"board": working,
		"spawned": spawn_total
	}


static func ensure_board_has_pair(board: Variant, target: int, rng: Variant, max_retries: int = DEFAULT_REPAIR_RETRIES) -> PackedInt32Array:
	var working := _normalize_board(board)
	if has_any_pairs(working, target):
		return working

	var retries := maxi(1, max_retries)
	for _i in range(retries):
		working = _repair_once(working, target, rng)
		if has_any_pairs(working, target):
			return working

	return shuffle_board_with_pair(target, rng, retries)


static func apply_strike_state(current_strikes: int, pairs_cleared: int, max_strikes: int = 3) -> Dictionary:
	var strikes := current_strikes
	if pairs_cleared > 0:
		strikes = 0
	else:
		strikes += 1
	var game_over := strikes >= max_strikes
	return {
		"strikes": strikes,
		"game_over": game_over
	}


static func refill_empties(board: Variant, rng: Variant) -> PackedInt32Array:
	var refilled := _normalize_board(board)
	for i in range(refilled.size()):
		if refilled[i] <= 0:
			refilled[i] = _rand_value(rng)
	return refilled


static func _repair_once(board: PackedInt32Array, target: int, rng: Variant) -> PackedInt32Array:
	var working := _normalize_board(board)
	var adjacencies := _all_adjacencies()
	if adjacencies.is_empty():
		return working

	var pair_idx := _rand_index(adjacencies.size(), rng)
	var pair_cells: Vector2i = adjacencies[pair_idx]
	var values := _random_target_pair(target, rng)
	if values.x <= 0 or values.y <= 0:
		values = _forced_pair_values(target)
	if values.x <= 0 or values.y <= 0:
		return working

	working[pair_cells.x] = values.x
	working[pair_cells.y] = values.y
	return working


static func _force_pair_with_existing_values(board: PackedInt32Array, target: int, rng: Variant) -> PackedInt32Array:
	var working := _normalize_board(board)
	var value_pair := _find_pair_indices(working, target, rng)
	if value_pair.x < 0 or value_pair.y < 0:
		return working

	var adjacencies := _all_adjacencies()
	if adjacencies.is_empty():
		return working

	var adjacency := adjacencies[_rand_index(adjacencies.size(), rng)]
	var first_source := value_pair.x
	var second_source := value_pair.y
	_swap(working, adjacency.x, first_source)

	if second_source == adjacency.x:
		second_source = first_source
	elif second_source == adjacency.y:
		second_source = adjacency.y

	_swap(working, adjacency.y, second_source)
	return working


static func _find_pair_indices(board: PackedInt32Array, target: int, rng: Variant) -> Vector2i:
	var pairs: Array[Vector2i] = []
	for i in range(board.size()):
		var left := int(board[i])
		if left <= 0:
			continue
		for j in range(i + 1, board.size()):
			var right := int(board[j])
			if right <= 0:
				continue
			if left + right == target:
				pairs.append(Vector2i(i, j))

	if pairs.is_empty():
		return Vector2i(-1, -1)
	return pairs[_rand_index(pairs.size(), rng)]


static func _all_adjacencies() -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var here := index_of(row, col)
			if col < BOARD_SIZE - 1:
				pairs.append(Vector2i(here, index_of(row, col + 1)))
			if row < BOARD_SIZE - 1:
				pairs.append(Vector2i(here, index_of(row + 1, col)))
	return pairs


static func _random_target_pair(target: int, rng: Variant) -> Vector2i:
	var options: Array[Vector2i] = []
	for left in range(VALUE_MIN, VALUE_MAX + 1):
		var right := target - left
		if right >= VALUE_MIN and right <= VALUE_MAX:
			options.append(Vector2i(left, right))
	if options.is_empty():
		return Vector2i(-1, -1)
	return options[_rand_index(options.size(), rng)]


static func _shuffle_copy(board: PackedInt32Array, rng: Variant) -> PackedInt32Array:
	var shuffled := board.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := _rand_index(i + 1, rng)
		_swap(shuffled, i, j)
	return shuffled


static func _shuffle_int_array(values: Array[int], rng: Variant) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := _rand_index(i + 1, rng)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp


static func _rand_index(max_exclusive: int, rng: Variant) -> int:
	if max_exclusive <= 1:
		return 0
	if rng != null and rng.has_method("randi_range"):
		return int(rng.call("randi_range", 0, max_exclusive - 1))
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback.randi_range(0, max_exclusive - 1)


static func _swap(board: PackedInt32Array, i: int, j: int) -> void:
	if i == j:
		return
	var tmp := board[i]
	board[i] = board[j]
	board[j] = tmp


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
