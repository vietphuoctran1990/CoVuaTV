extends SceneTree

func _init() -> void:
	print("=== load game scene test ===")
	# Wait for autoloads
	await process_frame
	print("autoloads ok, GameBus=", GameBus)
	GameBus.pending_vs_ai = false
	var err = change_scene_to_file("res://scenes/game.tscn")
	print("change_scene err=", err)
	await process_frame
	await process_frame
	await process_frame
	print("frames ok, current=", current_scene)
	if current_scene:
		print("scene name=", current_scene.name)
		var bv = current_scene.get_node_or_null("BoardView")
		print("BoardView=", bv)
		if bv:
			print("built children=", bv.get_child_count())
	await create_timer(1.0).timeout
	print("still alive after 1s")
	quit(0)
