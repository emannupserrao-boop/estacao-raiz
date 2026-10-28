extends SceneTree
func _initialize() -> void:
	var core = load("res://defense.gd").new()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://local/polish-reopen.json"))
	var ok: bool = core.restore(data) and core.wave == 3 and core.credits == 3 and core.upgrade == 2 and core.upgrade_level == 2 and core.health > 0 and core.mode == "won"
	var file := FileAccess.open("res://evidence/polish/reopen-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"separate_process":true,"passed":ok,"checkpoint":core.checkpoint()}))
	file.close()
	print("POLISH REOPEN ",ok)
	quit(0 if ok else 1)
