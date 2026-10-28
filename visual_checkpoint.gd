extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1200,760)
	var arena=load("res://main.tscn").instantiate(); root.add_child(arena)
	arena.save_path="res://local/visual-checkpoint-only.json"
	for i in range(20): await process_frame
	arena.set_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/first-overview.png")
	arena.game.start()
	for i in range(230): arena.game.tick(.05)
	for i in range(10):
		arena._process(1.0/24.0)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/first-combat.png")
	print("First identity checkpoint captured from Godot viewport; functional QA not yet completed.")
	quit()
