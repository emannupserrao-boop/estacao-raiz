extends SceneTree
const Rules=preload("res://defense.gd")
const FOLDER="res://evidence/polimento-20261017-0935/"
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func run() -> void:
	var tag:="before"
	var small:=false
	var rate:=1.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="): tag=arg.trim_prefix("--tag=")
		if arg=="--small": small=true
		if arg=="--slow": rate=.25
	assert(tag in ["before","after","small","slow"])
	var folder:=FOLDER+tag+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	Engine.max_fps=24
	root.size=Vector2i(1200,760)
	var arena=load("res://main.tscn").instantiate(); root.add_child(arena); arena.set_process(false)
	arena.save_path="res://local/vfx-round-"+tag+".json"
	arena.sound.settings_path="res://local/vfx-round-audio-"+tag+".json"
	for i in range(12): await process_frame
	if small:
		root.size=Vector2i(960,608)
		for i in range(12): await process_frame
	Engine.time_scale=rate
	arena.game=Rules.new(); arena.game.wave=2; arena.game.upgrade=1; arena.game.upgrade_level=2; arena.game.start(); arena.game.spawned=arena.game.total_enemies(); arena.game.serial=100
	for lane in range(2):
		for i in range(4):
			var heavy:=i%2==0
			var hp:=20.0 if heavy else 7.0
			arena.game.enemies.append({"id":lane*10+i+1,"lane":lane,"x":480.0+i*65,"hp":hp,"max_hp":hp,"heavy":heavy,"flash":0.0})
	var frozen_model:=""
	var frozen_poses:={}
	var max_beams:=0
	var model_unpolluted:=true
	var endpoints_stable:=true
	var captured_geometry:={}
	var poses:=[]
	for frame in range(96):
		if frame==12: arena._on_intent("route",1)
		if frame==36: arena._on_intent("pause",0)
		if frame==40:
			frozen_model=JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining})
			for id in arena.world.actors:
				var actor=arena.world.actors[id]
				frozen_poses[id]=[actor.body.position,actor.body.rotation,actor.leg_pivots[0].rotation]
			for tower in arena.world.towers: frozen_poses[tower.get_instance_id()]=[tower.recoil.position,tower.recoil.scale,tower.neck.rotation]
		if frame==48:
			check(frozen_model==JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining}),"pause freezes gameplay")
			for id in arena.world.actors:
				if frozen_poses.has(id):
					var actor=arena.world.actors[id]
					check(frozen_poses[id]==[actor.body.position,actor.body.rotation,actor.leg_pivots[0].rotation],"pause freezes body and legs")
			for tower in arena.world.towers: check(frozen_poses[tower.get_instance_id()]==[tower.recoil.position,tower.recoil.scale,tower.neck.rotation],"pause freezes tower recoil and aim")
		if frame==54: arena._on_intent("pause",0)
		if frame==66: arena._on_intent("route",0)
		arena._process(rate/24.0)
		if tag!="before":
			for beam in arena.game.beams: model_unpolluted=model_unpolluted and not beam.has("geometry")
			for key in arena.world.beam_geometry:
				if captured_geometry.has(key): endpoints_stable=endpoints_stable and captured_geometry[key]==arena.world.beam_geometry[key]
				else: captured_geometry[key]=arena.world.beam_geometry[key].duplicate(true)
		max_beams=maxi(max_beams,arena.game.beams.size())
		await process_frame
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		check(image.save_jpg(folder+"frame_%04d.jpg"%frame,.95)==OK,"frame write")
		if frame in [0,1,2,4,8,14,27,40,48,60,70,95]: image.save_png(folder+"frame_%04d.png"%frame)
		if frame in [0,8,27,70]:
			var towers:=[]
			for tower in arena.world.towers: towers.append({"lane":tower.route,"recoil":tower.recoil.position,"neck":tower.neck.rotation,"petals":tower.petals[0].rotation if tower.petals.size()>0 else 0})
			poses.append({"frame":frame,"towers":towers})
	var size:=Image.load_from_file(folder+"frame_0000.png").get_size()
	check(size==(Vector2i(960,608) if small else Vector2i(1200,760)),"native image resolution")
	check(max_beams>=2,"both weapon visual activity exercised")
	if tag!="before":
		check(model_unpolluted,"presentation never adds geometry to rule dictionaries")
		check(endpoints_stable,"shot endpoints remain fixed after emission and new aiming")
	var f=FileAccess.open(folder+"report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"tag":tag,"checks":checks,"failures":failures,"native_size":size,"frames":96,"fps":24,"simulation_rate":rate,"pause_frames":[36,54],"poses":poses,"max_beams":max_beams,"state":{"health":arena.game.health,"kills":arena.game.kills,"enemies":arena.game.enemies,"mode":arena.game.mode},"human_playtest":false,"source":"actual native Godot viewport; same scripted fixture and simulation steps"},"\t")); f.close()
	print(JSON.stringify({"tag":tag,"checks":checks,"failures":failures,"size":size,"kills":arena.game.kills}))
	arena.sound.stop_all(); quit(0 if failures.is_empty() else 1)
