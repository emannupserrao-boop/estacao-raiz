extends SceneTree
func _initialize() -> void:
	var core = load("res://defense.gd").new()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://local/reopen-checkpoint.json"))
	var ok: bool = core.restore(data) and core.wave == 1 and core.credits == 0 and core.upgrade == 2 and core.health == 8 and core.mode == "ready"
	var file := FileAccess.open("res://evidence/reopen-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"separate_process":true,"passed":ok,"checkpoint":core.checkpoint()}))
	file.close()
	print("REOPEN ",ok)
	quit(0 if ok else 1)
