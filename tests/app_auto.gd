extends "res://ui/app_root.gd"

func _ready() -> void:
	super._ready()
	call_deferred("_auto")

func _auto() -> void:
	await get_tree().create_timer(0.4).timeout
	print("AUTO start")
	_start_game(false)
	await get_tree().process_frame
	cursor = Vector2i(4, 1)
	_play_ok()
	print("AUTO sel=", selected_sq)
	await get_tree().process_frame
	cursor = Vector2i(4, 3)
	_play_ok()
	print("AUTO moved")
	for i in 100:
		await get_tree().process_frame
		if i == 5:
			_key(KEY_LEFT)
			print("AUTO LEFT")
		if i == 15:
			_key(KEY_ENTER)
			print("AUTO ENTER2")
		if i == 25:
			_key(KEY_UP)
			print("AUTO UP")
		if i % 25 == 0:
			print("AUTO f", i)
	print("AUTO OK SURVIVED")
	get_tree().quit(0)
