extends SceneTree
const Rules=preload("res://defense.gd")
var checks:=0
var failures: Array[String]=[]
var played: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func fixture(selected: int,upgrade: int=0,level: int=0):
	var g=Rules.new(); g.selected=selected; g.upgrade=upgrade; g.upgrade_level=level; g.start(); g.spawned=g.total_enemies()
	for lane in range(2): g.enemies.append({"id":lane+1,"lane":lane,"x":500.0,"hp":100.0,"max_hp":100.0,"heavy":false,"flash":0.0})
	return g
func threat_lane(g) -> int:
	var threat:=[0.0,0.0]
	for e in g.enemies:
		if e.x>=420: threat[e.lane]+=float(e.hp)/maxf(1,(1030-e.x)/(32 if e.heavy else 65))
	return 0 if threat[0]>=threat[1] else 1
func settle(arena,frames: int=48) -> void:
	for i in range(frames):
		arena._process(1.0/60.0)
		await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://evidence/"+name+".png")==OK,"capture "+name)
func run() -> void:
	root.size=Vector2i(1200,760)
	var g=fixture(0)
	var births:=[[],[]]
	for i in range(50):
		g.tick(.005)
		for beam in g.beams:
			if beam.life>=.199: births[beam.lane].append(g.elapsed)
	check(births[0].size()==1,"capsule emits one precise pulse per cycle")
	check(births[1].size()==3,"flower emits three pulses per cycle")
	check(absf(float(births[1][1])-float(births[1][0])-.09)<.006,"burst spacing approximately 90ms")
	check(is_equal_approx(g.enemies[0].hp,95.0),"reinforced capsule energy total five")
	check(is_equal_approx(g.enemies[1].hp,99.0),"base flower conserves cycle energy")
	g=fixture(1)
	for i in range(50): g.tick(.005)
	check(is_equal_approx(g.enemies[1].hp,95.0),"reinforced flower energy total five")
	check(is_equal_approx(g.enemies[0].hp,99.0),"base capsule energy one")
	for reserve in [false,true]:
		g=fixture(1,1 if reserve else 0,1 if reserve else 0); g.switch_to(0)
		for i in range(50): g.tick(.005)
		check(is_equal_approx(g.enemies[0].hp,99.0 if reserve else 99.6),"reserve preserves base capsule damage")
		check(is_equal_approx(g.enemies[1].hp,99.0 if reserve else 99.6),"reserve preserves base flower damage")
	for level in [1,2]:
		g=fixture(0,2,level)
		for i in range(2): g.enemies.append({"id":10+i,"lane":0,"x":510.0+i*10,"hp":100.0,"max_hp":100.0,"heavy":false,"flash":0.0})
		g.tick(.005)
		var damaged:=0
		for e in g.enemies:
			if e.lane==0 and e.hp<100: damaged+=1
		check(damaged==level+1,"root network distributes to expected targets")
		check(not g.buy(1),"exclusive upgrade cannot change during combat")
	g=fixture(1); g.tick(.005)
	check(g.burst_remaining==2,"pending burst exists")
	var saved: Dictionary=g.checkpoint(); g.effects.append({"life":1.0})
	check(g.restore(saved) and g.burst_remaining==0 and g.beams.is_empty() and g.effects.is_empty(),"restore discards transient projectiles and pending burst")
	var arena=load("res://main.tscn").instantiate(); root.add_child(arena); arena.set_process(false); arena.save_path="res://local/raiz-qa-game.json"
	for i in range(20): await process_frame
	arena.game=fixture(1); arena._process(.005)
	check(arena.world.actors.size()==2,"articulated actors instantiated")
	for actor in arena.world.actors.values(): check(actor.leg_pivots.size()==6,"six independently articulated legs")
	for lane in range(2):
		var tower=arena.world.towers[lane]
		var point:=Vector2(748,200) if lane==0 else Vector2(600,420)
		tower.shoot(point)
		var axis: Vector2=tower.recoil.global_transform.x.normalized()
		check(axis.dot((point-tower.muzzle_position()).normalized())>.999,"beam axis aligned with articulated muzzle")
	var before:=JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining,"clock":arena.game.burst_clock})
	var rotations:=[]
	for actor in arena.world.actors.values(): rotations.append(actor.leg_pivots[0].rotation)
	arena.paused=true
	for i in range(15): arena._process(.05); await process_frame
	check(before==JSON.stringify({"enemies":arena.game.enemies,"beams":arena.game.beams,"effects":arena.game.effects,"burst":arena.game.burst_remaining,"clock":arena.game.burst_clock}),"pause freezes burst queue and model")
	var index:=0
	for actor in arena.world.actors.values(): check(actor.leg_pivots[0].rotation==rotations[index],"pause freezes gait"); index+=1
	arena.paused=false
	for i in range(4): arena._process(.05)
	check(arena.game.burst_remaining==0,"resume completes remaining burst")
	var victim=arena.world.actors.values()[0]; victim.die(); arena.paused=true; arena._process(0)
	var alpha: float=victim.modulate.a
	for i in range(15): await process_frame
	check(is_equal_approx(alpha,victim.modulate.a),"pause freezes death tween")
	for choice in [1,2]:
		arena.game=Rules.new(); arena.paused=false; arena._refresh()
		for wave in range(3):
			if wave>0: arena._buy(choice)
			arena._start_or_retry()
			var ticks:=0
			while arena.game.mode=="wave" and ticks<3000:
				if ticks%40==0: arena._switch(threat_lane(arena.game))
				arena._process(.05); ticks+=1
			check(arena.game.wave==wave+1 and arena.game.mode in ["ready","won"],"integrated scene completes sector")
			await settle(arena)
			check(arena.world.stage==wave+1,"visual restoration follows earned wave progress")
			var plants_visible:=0
			for plant in arena.world.plant_nodes:
				if plant.visible: plants_visible+=1
			check(plants_visible==(0 if wave==0 else 6),"irrigation then buds then flowers")
			await capture("branch-%d-sector-%d" % [choice,wave+1])
		check(arena.game.credits==3 and arena.game.upgrade_level==2,"earned rewards pay two upgrades and leave three buds")
		played.append({"choice":choice,"health":arena.game.health,"credits":arena.game.credits,"wave":arena.game.wave})
		check(not arena.game.buy(3-choice),"opposite upgrade remains unavailable")
	var final_file:=FileAccess.get_file_as_string(arena.save_path)
	check(JSON.parse_string(final_file).wave==3,"victory checkpoint persisted")
	arena._reset(); check(arena.confirm_reset,"reset requires confirmation")
	arena.confirm_reset=false
	check(arena.game.wave==3,"cancel reset preserves progress")
	arena._reset(); arena._reset(); arena._refresh()
	check(arena.game.wave==0 and arena.game.credits==0 and arena.world.stage==0,"confirmed reset returns dormant greenhouse")
	check(arena.world.actors.is_empty(),"reset removes previous actors")
	var fixture_file=FileAccess.open("res://local/raiz-reopen.json",FileAccess.WRITE); fixture_file.store_string(final_file); fixture_file.close()
	var f=FileAccess.open("res://evidence/raiz-qa-report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"branches":played,"human_playtest":false,"scope":"core burst, exclusive upgrades, articulated scene, pause, earned restoration, save and reset"},"\t")); f.close()
	print(JSON.stringify({"checks":checks,"failures":failures,"branches":played}))
	quit(0 if failures.is_empty() else 1)
