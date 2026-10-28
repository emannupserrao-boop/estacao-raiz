extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var sound = load("res://audio/director.gd").new()
	root.add_child(sound)
	sound.settings_path="res://local/audio-qa-settings.json"
	sound.load_settings()
	var ok: bool = sound.muted and is_equal_approx(sound.volume,0.35) and AudioServer.is_bus_mute(sound.bus)
	var file=FileAccess.open("res://evidence/audio/reopen-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"separate_process":true,"volume":sound.volume,"muted":sound.muted,"bus_muted":AudioServer.is_bus_mute(sound.bus),"passed":ok}))
	file.close()
	print("Audio preference reopen: ",ok)
	quit(0 if ok else 1)
