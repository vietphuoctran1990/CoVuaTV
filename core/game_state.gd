extends RefCounted
## Quản lý ván đấu: history, undo, kết quả, gợi ý.

const ChessBoard = preload("res://core/board.gd")
const ChessMove = preload("res://core/move.gd")
const MoveGen = preload("res://core/move_gen.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")
const SimpleAI = preload("res://core/ai_simple.gd")

enum Result { ONGOING, CHECKMATE, STALEMATE }

var board
var history: Array = []  # moves
var undos_used: int = 0
var vs_ai: bool = false
var human_side: int = PieceCatalog.Side.WHITE
var last_result: int = Result.ONGOING
var winner_side: int = -1


func _init() -> void:
	board = ChessBoard.new()
	board.setup_start()


func new_game(p_vs_ai: bool = false, p_human_side: int = PieceCatalog.Side.WHITE) -> void:
	board = ChessBoard.new()
	board.setup_start()
	history.clear()
	undos_used = 0
	vs_ai = p_vs_ai
	human_side = p_human_side
	last_result = Result.ONGOING
	winner_side = -1


func get_legal_moves() -> Array:
	return MoveGen.legal_moves(board)


func get_legal_from(sq: int) -> Array:
	return MoveGen.legal_moves_from(board, sq)


func is_human_turn() -> bool:
	if not vs_ai:
		return true
	return board.side_to_move == human_side


func try_move(from_sq: int, to_sq: int, promotion: int = PieceCatalog.Type.QUEEN) -> Dictionary:
	## Returns {ok, move, capture_name, check, result_text}
	var info := {"ok": false, "move": null, "capture_name": "", "check": false, "result_text": "", "need_promo": false}
	if last_result != Result.ONGOING:
		return info
	var candidates: Array = get_legal_from(from_sq)
	var chosen = null
	var promo_options: Array = []
	for m in candidates:
		if m.to_sq != to_sq:
			continue
		if m.promotion != 0:
			promo_options.append(m)
			if m.promotion == promotion:
				chosen = m
		else:
			chosen = m
			break
	if chosen == null and promo_options.size() > 0:
		info.need_promo = true
		return info
	if chosen == null:
		return info

	var cap_type: int = 0
	if chosen.is_en_passant:
		var cap_sq: int = ChessBoard.sq_of(ChessBoard.file_of(chosen.to_sq), ChessBoard.rank_of(chosen.from_sq))
		var cp: int = board.get_piece(cap_sq)
		cap_type = ChessBoard.piece_type(cp)
	else:
		var tp: int = board.get_piece(chosen.to_sq)
		if not ChessBoard.is_empty(tp):
			cap_type = ChessBoard.piece_type(tp)

	MoveGen.apply_move(board, chosen)
	history.append(chosen)
	info.ok = true
	info.move = chosen
	if cap_type != 0:
		info.capture_name = PieceCatalog.display_name(cap_type)

	_eval_end()
	if last_result == Result.CHECKMATE:
		info.result_text = _mate_text()
	elif last_result == Result.STALEMATE:
		info.result_text = "Hòa cờ — không còn nước đi!"
	elif MoveGen.is_in_check(board, board.side_to_move):
		info.check = true
	return info


func _settings():
	# Autoload AppSettings — may be missing in bare --script runs
	var tree = Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	var root = (tree as SceneTree).root
	if root and root.has_node("AppSettings"):
		return root.get_node("AppSettings")
	return null


func _undo_enabled() -> bool:
	var s = _settings()
	return true if s == null else s.undo_enabled


func _max_undos() -> int:
	var s = _settings()
	return 3 if s == null else s.max_undos


func _ai_depth() -> int:
	var s = _settings()
	if s == null:
		return 1
	return 1 if s.ai_difficulty == 0 else 2


func undo() -> bool:
	if history.is_empty():
		return false
	if not _undo_enabled():
		return false
	if undos_used >= _max_undos():
		return false
	# Vs AI: undo AI reply + human move so human turns again
	if vs_ai and history.size() >= 2 and not is_human_turn():
		var m_ai = history.pop_back()
		MoveGen.undo_move(board, m_ai)
	var m = history.pop_back()
	MoveGen.undo_move(board, m)
	# If still AI turn after single undo (edge), pull one more
	if vs_ai and not history.is_empty() and not is_human_turn():
		var m2 = history.pop_back()
		MoveGen.undo_move(board, m2)
	undos_used += 1
	last_result = Result.ONGOING
	winner_side = -1
	return true


func ai_move_if_needed() -> Dictionary:
	var empty := {"ok": false}
	if not vs_ai or last_result != Result.ONGOING:
		return empty
	if is_human_turn():
		return empty
	var m = SimpleAI.choose_move(board, _ai_depth())
	if m == null:
		return empty
	return try_move(m.from_sq, m.to_sq, m.promotion if m.promotion != 0 else PieceCatalog.Type.QUEEN)


func hint_move():
	var moves: Array = get_legal_moves()
	if moves.is_empty():
		return null
	# Prefer captures / checks lightly
	var scored: Array = []
	for m in moves:
		var score: int = randi() % 5
		var target: int = board.get_piece(m.to_sq)
		if not ChessBoard.is_empty(target):
			score += 10 + ChessBoard.piece_type(target)
		var b2 = board.clone()
		MoveGen.apply_move(b2, m.duplicate_move())
		if MoveGen.is_in_check(b2, b2.side_to_move):
			score += 8
		scored.append({"m": m, "s": score})
	scored.sort_custom(func(a, b): return a.s > b.s)
	return scored[0].m


func _eval_end() -> void:
	var moves: Array = MoveGen.legal_moves(board)
	if moves.size() > 0:
		last_result = Result.ONGOING
		return
	if MoveGen.is_in_check(board, board.side_to_move):
		last_result = Result.CHECKMATE
		winner_side = 1 - board.side_to_move
	else:
		last_result = Result.STALEMATE
		winner_side = -1


func _mate_text() -> String:
	var wname: String = PieceCatalog.side_name(winner_side)
	return "Chiếu hết! %s thắng — Doraemon đội chiến thắng!" % wname
