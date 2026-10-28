extends SceneTree
const Rules=preload("res://defense.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func run() -> void:
	var small: bool="--small" in OS.get_cmdline_user_args()
	var slow: bool="--slow" in OS.get_cmdline_user_args()
	var rate:=.25 if slow else 1.0
	var tag:="small" if small else ("slow" if slow else "normal")
	Engine.max_fps=24; Engine.time_scale=rate
	root.size=Vector2i(1200,760)
	var arena=load("res://main.tscn").instantiate(); root.add_child(arena); arena.set_process(false)
	arena.save_path="res://local/record-%s-game.json" % tag
	arena.sound.settings_path="res://local/record-%s-audio.json" % tag
	for i in range(20): await process_frame
	if small:
		root.size=Vector2i(960,608)
		for i in range(20): await process_frame
	arena.game=Rules.new(); arena.game.wave=2; arena.game.upgrade=2; arena.game.upgrade_level=2; arena.game.selected=1; arena.game.start(); arena.game.spawned=arena.game.total_enemies()
	for lane in range(2):
		for i in range(6):
			var hp:=20.0 if i%3!=0 else 7.0
			arena.game.enemies.append({"id":lane*10+i+1,"lane":lane,"x":500.0+i*34,"hp":hp,"max_hp":hp,"heavy":i%3!=0,"flash":0.0})
	var frozen_model:=""
	var frozen_visual:={}
	var max_enemies:=0
	var max_beams:=0
	var shots_at_pause:=0
	var frame_count:=192 if slow else 144
	var capture_started:=Time.get_ticks_usec()
	for frame in range(frame_count):
		if frame==24: arena._on_intent("route",0)
		if frame==48: arena._on_intent("pause",0)
		if frame==51:
			frozen_model=JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining,"transfer":arena.game.transfer})
			shots_at_pause=int(arena.sound.events.get("shot",0))
			for id in arena.world.actors:
				var actor=arena.world.actors[id]
				frozen_visual[id]={"body":actor.body.position,"leg":actor.leg_pivots[0].rotation}
		if frame==69:
			check(frozen_model==JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining,"transfer":arena.game.transfer}),"pause freezes queue and all model effects")
			check(shots_at_pause==int(arena.sound.events.get("shot",0)),"pause emits no new shots")
			for id in frozen_visual:
				var actor=arena.world.actors[id]
				check(actor.body.position.is_equal_approx(frozen_visual[id].body) and actor.leg_pivots[0].rotation==frozen_visual[id].leg,"pause freezes articulated anatomy")
		if frame==72: arena._on_intent("pause",0)
		if frame==96: arena._on_intent("route",1)
		if not slow and frame==120: arena._on_intent("mute",0)
		arena._process(1.0/24.0*rate)
		max_enemies=maxi(max_enemies,arena.game.enemies.size()); max_beams=maxi(max_beams,arena.game.beams.size())
		await process_frame
		await RenderingServer.frame_post_draw
		if small: root.get_texture().get_image().save_jpg("res://evidence/motion/small-frames/frame_%04d.jpg" % frame,.94)
		if frame in [0,1,5,14,54,68,110,130]: root.get_texture().get_image().save_png("res://evidence/motion/%s-%03d.png" % [tag,frame])
	var captured:=Image.load_from_file("res://evidence/motion/%s-000.png" % tag).get_size()
	check(captured==(Vector2i(960,608) if small else Vector2i(1200,760)),"saved pixels have requested native resolution")
	check(max_enemies==12,"twelve enemies exercised")
	check(max_beams>=4,"simultaneous projectiles exercised")
	var f=FileAccess.open("res://evidence/motion/%s-report.json" % tag,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rate":rate,"frames":frame_count,"fps":24,"setup_frames":40 if small else 20,"native_size":captured,"max_enemies":max_enemies,"max_beams":max_beams,"events":arena.sound.events,"fixture":true,"pause_frames":[48,72],"mute_frame":120 if not slow else -1,"capture_elapsed_seconds":(Time.get_ticks_usec()-capture_started)/1000000.0,"source":"Godot viewport and mixer, automated inputs; offline Movie Maker for normal/slow; normal window for small","human_playtest":false,"human_listening":false},"\t")); f.close()
	print(JSON.stringify({"tag":tag,"checks":checks,"failures":failures,"events":arena.sound.events}))
	arena.sound.stop_all(); quit(0 if failures.is_empty() else 1)
