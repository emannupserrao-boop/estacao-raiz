extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var arena = load("res://main.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.save_path = "res://local/audio-qa-game.json"
	var sound = arena.sound
	sound.settings_path = "res://local/audio-qa-settings.json"
	for i in range(20): await process_frame
	check(sound.voices.size()==6,"bounded voice pool")
	for name in ["shot","impact","transfer","ui","victory","defeat"]:
		check(sound.streams[name] is AudioStreamWAV,"stream "+name)
	var saved = arena.game.checkpoint().duplicate(true)
	sound.set_volume(0.35)
	sound.toggle_mute()
	sound.volume=1.0
	sound.muted=false
	sound.load_settings()
	check(is_equal_approx(sound.volume,0.35) and sound.muted,"settings roundtrip")
	check(AudioServer.is_bus_mute(sound.bus),"bus mute")
	sound.cue("ui")
	check(not sound.events.has("ui"),"muted cues suppressed")
	sound.toggle_mute()
	sound.set_volume(0)
	sound.cue("shot")
	check(not sound.events.has("shot"),"zero volume suppressed")
	sound.set_volume(2)
	check(sound.volume==1,"upper volume clamp")
	sound.set_volume(-5)
	check(sound.volume==0,"lower volume clamp")
	sound.set_volume(NAN)
	check(sound.volume==0.65,"nonfinite volume fallback")
	var file := FileAccess.open(sound.settings_path,FileAccess.WRITE)
	file.store_string('{"volume":"broken","muted":true}')
	file.close()
	sound.load_settings()
	check(sound.volume==0.65 and sound.muted,"invalid field safe")
	file=FileAccess.open(sound.settings_path,FileAccess.WRITE)
	file.store_string('broken json')
	file.close()
	sound.load_settings()
	check(sound.volume==0.65 and sound.muted,"malformed settings safe")
	sound.toggle_mute()
	sound.observe(arena.game,false,0.05)
	check(arena.game.checkpoint()==saved,"sound never mutates checkpoint")
	arena.game.start()
	arena.game.elapsed=5.0
	arena.game.beams.assign([{"lane":0,"x":500.0,"life":0.2,"boost":true}])
	arena.game.effects.assign([{"lane":0,"x":500.0,"life":0.25,"max":0.25,"kind":"hit"}])
	sound.observe(arena.game,false,0.05)
	check(sound.events.get("shot",0)==1 and sound.events.get("impact",0)==1,"birth cues")
	for i in range(20): sound.observe(arena.game,false,0.001)
	check(sound.events.shot==1 and sound.events.impact==1,"same event no repeats")
	arena.game.selected=1
	arena.game.transfer=0.9
	sound.observe(arena.game,false,0.1)
	check(sound.events.get("transfer",0)==1,"power transfer cue")
	sound.observe(arena.game,true,0.1)
	for voice in sound.voices: check(not voice.playing,"pause stops voices")
	var old = sound.events.duplicate()
	for i in range(10): sound.observe(arena.game,true,0.05)
	check(sound.events==old,"pause no gameplay events")
	sound.observe(arena.game,false,0.05)
	check(sound.events==old,"resume no stale events")
	sound.cue("ui",0.04)
	check(sound.events.get("ui",0)==1,"UI available during pause")
	arena.game.mode="won"
	sound.observe(arena.game,false,0.05)
	for i in range(10): sound.observe(arena.game,false,0.05)
	check(sound.events.get("victory",0)==1,"victory once")
	arena.game.mode="lost"
	sound.observe(arena.game,false,0.05)
	check(sound.events.get("defeat",0)==1,"defeat once")
	for i in range(100): sound.cue("impact",0.06)
	check(sound.events.impact==2,"impact burst throttled")
	arena.game=arena.Rules.new()
	arena.game.start()
	arena.game.elapsed=5.0
	arena.game.beams.assign([{"lane":0,"x":500.0,"life":0.2,"boost":true}])
	sound.observe(arena.game,false,0.1)
	check(sound.events.shot==2,"reset permits new identical event")
	arena.hud.present_audio(0.35,true,"")
	check(arena.buttons.mute.text=="Som: mudo","mute label")
	check(is_equal_approx(arena.hud.volume_slider.value,0.35),"volume UI")
	var top: Rect2 = arena.hud.get_child(0).get_global_rect()
	for id in ["help","mute"]: check(top.encloses(arena.buttons[id].get_global_rect()),"header bounds "+id)
	check(top.encloses(arena.hud.volume_slider.get_global_rect()),"slider bounds")
	sound.set_volume(0.35)
	sound.toggle_mute()
	var report := {"checks":checks,"failures":failures,"events":sound.events,"human_listening":false,"human_playtest":false}
	file=FileAccess.open("res://evidence/audio/qa-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
