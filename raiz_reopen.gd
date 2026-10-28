extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena=load("res://main.tscn").instantiate(); root.add_child(arena); arena.save_path="res://local/raiz-reopen.json"; arena._load_checkpoint(); arena._refresh()
	for i in range(60): await process_frame
	var ok: bool=arena.game.mode=="won" and arena.game.wave==3 and arena.game.credits==3 and arena.game.upgrade==2 and arena.game.upgrade_level==2 and arena.game.burst_remaining==0 and arena.world.stage==3 and arena.world.actors.is_empty()
	var f=FileAccess.open("res://evidence/raiz-reopen-report.json",FileAccess.WRITE); f.store_string(JSON.stringify({"separate_process":true,"passed":ok,"checkpoint":arena.game.checkpoint(),"restoration_stage":arena.world.stage})); f.close()
	print("RAIZ_REOPEN ",ok); quit(0 if ok else 1)
