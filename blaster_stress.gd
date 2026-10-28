extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(320,180)
	var sound=load("res://audio/director.gd").new()
	root.add_child(sound)
	sound.volume=1.0
	sound.apply_settings()
	for frame in range(48):
		if frame%8==0:
			for i in range(3):
				sound.cue("shot",0,0)
				sound.cue("shot",0,1)
		if frame%8==1:
			sound.cue("impact")
			sound.cue("impact")
		await process_frame
	sound.stop_all()
	sound.queue_free()
	await process_frame
	quit()
