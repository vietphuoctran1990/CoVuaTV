extends SceneTree
const ChessBoard = preload("res://core/board.gd")
const GameState = preload("res://core/game_state.gd")
const SimpleAI = preload("res://core/ai_simple.gd")
const MoveGen = preload("res://core/move_gen.gd")

func _init() -> void:
	print("=== AI path test ===")
	var gs = GameState.new()
	gs.new_game(true) # vs AI
	var info = gs.try_move(ChessBoard.sq_of(4, 1), ChessBoard.sq_of(4, 3))
	print("human e4 ok=", info.ok)
	var ai = gs.ai_move_if_needed()
	print("ai ok=", ai.get("ok", false), " result=", ai.get("result_text",""), " last=", gs.last_result)
	# 5 more plies
	for i in 5:
		var moves = gs.get_legal_moves()
		if moves.is_empty():
			print("no moves at ", i)
			break
		var m = moves[0]
		info = gs.try_move(m.from_sq, m.to_sq, m.promotion if m.promotion != 0 else 5)
		print("auto ", i, " ok=", info.ok, " res=", info.result_text)
		if gs.vs_ai and not gs.is_human_turn():
			ai = gs.ai_move_if_needed()
			print("  ai reply ok=", ai.get("ok", false))
	print("done")
	quit(0)
