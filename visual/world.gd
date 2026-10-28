extends Node2D
const Enemy=preload("res://visual/actor.tscn")
const Tower=preload("res://visual/tower.tscn")
const BudTexture=preload("res://assets/parts/bud.png")
const PlantTexture=preload("res://assets/parts/restored_plant.png")
var actors:={}
var known_nodes:={}
var last_points:={}
var towers: Array[Node2D]=[]
var beams: Array=[]
var effects: Array=[]
var seen:={}
var beam_geometry:={}
var paused:=false
var power_lane:=0
var transfer:=0.0
var elapsed:=0.0
var last_game:=0
var stage:=0
var growth:=1.0
var heart: Node2D
var heart_core: Sprite2D
var plant_nodes: Array[Sprite2D]=[]
var planter_nodes: Array[Sprite2D]=[]
var impact_layer: Node2D
func _ready() -> void:
	var bg:=Sprite2D.new(); bg.name="IllustratedGreenhouse"; bg.texture=load("res://assets/original/greenhouse.png"); bg.centered=false; bg.scale=Vector2(1200.0/bg.texture.get_width(),760.0/bg.texture.get_height()); bg.z_index=-10; add_child(bg)
	for lane in range(2):
		var tower=Tower.instantiate(); add_child(tower); tower.configure(lane); tower.position=Vector2(748,184+lane*180); tower.z_index=2; towers.append(tower)
	heart=Node2D.new(); heart.name="SapHeart"; heart.position=Vector2(1053,356); heart.z_index=7; add_child(heart)
	var cradle:=Sprite2D.new(); cradle.texture=load("res://assets/parts/heart_base.png"); cradle.scale=Vector2.ONE*.62; cradle.position.y=-106*.62; heart.add_child(cradle)
	heart_core=Sprite2D.new(); heart_core.texture=load("res://assets/parts/heart_core.png"); heart_core.scale=Vector2.ONE*.38; heart_core.position.y=-65; heart.add_child(heart_core)
	for point in [Vector2(250,300),Vector2(475,315),Vector2(660,548),Vector2(860,528),Vector2(950,150),Vector2(395,550)]:
		var pot:=Sprite2D.new(); pot.texture=load("res://assets/parts/flower_base.png"); pot.scale=Vector2.ONE*.16; pot.position=point+Vector2(0,25-106*.16); pot.z_index=1; add_child(pot); planter_nodes.append(pot)
		var plant:=Sprite2D.new(); plant.texture=PlantTexture; plant.position=point+Vector2(0,-26); plant.z_index=1; add_child(plant); plant_nodes.append(plant)
	impact_layer=preload("res://visual/impact_layer.gd").new(); impact_layer.z_index=10; add_child(impact_layer)
func path_position(x: float,lane: int) -> Vector2:
	var xs:=[150.0,350.0,600.0,800.0,950.0,1030.0]
	var ys:=[201.0,208.0,208.0,245.0,282.0,311.0] if lane==0 else [407.0,410.0,423.0,430.0,411.0,369.0]
	for i in range(xs.size()-1):
		if x<=xs[i+1]: return Vector2(x,lerpf(ys[i],ys[i+1],clampf((x-xs[i])/(xs[i+1]-xs[i]),0,1)))
	return Vector2(x,ys[-1])
func present(game,dt: float,is_paused: bool) -> void:
	if last_game!=game.get_instance_id():
		for node in known_nodes.values():
			if is_instance_valid(node): node.queue_free()
		actors.clear(); known_nodes.clear(); last_points.clear(); seen.clear(); beam_geometry.clear(); last_game=game.get_instance_id()
		for tower in towers: tower.reset_pose()
	paused=is_paused
	for child in get_children():
		if child.has_method("set_paused"): child.set_paused(paused)
	var step:=0.0 if paused else dt
	elapsed+=step; power_lane=game.selected; transfer=game.transfer
	if stage!=game.wave: stage=game.wave; growth=0
	growth=minf(1,growth+step*1.5)
	heart_core.position.y=-65+sin(elapsed*2.1)*1.5
	heart_core.self_modulate=Color(1,1,.9) if game.health>3 else Color(1,.72,.55)
	for i in range(plant_nodes.size()):
		planter_nodes[i].self_modulate=Color.WHITE if stage>=1 else Color(.42,.46,.38)
		plant_nodes[i].visible=stage>=2
		plant_nodes[i].texture=BudTexture if stage<3 else PlantTexture
		plant_nodes[i].scale=Vector2.ONE*(.23 if stage<3 else .36)*growth
		plant_nodes[i].modulate.a=.9 if stage<3 else 1.0
	var alive:={}
	for e in game.enemies:
		alive[e.id]=true
		if not actors.has(e.id):
			var actor=Enemy.instantiate(); add_child(actor); actor.configure(e.heavy); actors[e.id]=actor; known_nodes[e.id]=actor
		var node=actors[e.id]
		node.position=path_position(e.x,e.lane)+Vector2(0,2+int(e.id)%2*20 if e.heavy else 12+int(e.id)%2*3)
		node.z_index=3+int(e.lane)*2+int(e.id)%2; node.present(e,step); last_points[e.id]=node.position+node.body.position
	for id in actors.keys():
		if not alive.has(id): actors[id].die(); actors.erase(id)
	for id in known_nodes.keys():
		if not is_instance_valid(known_nodes[id]): known_nodes.erase(id)
	for lane in range(2):
		towers[lane].present(lane==game.selected and game.transfer<=0,game.transfer,step); towers[lane].set_upgrade(game.upgrade,game.upgrade_level)
	beams=game.beams.duplicate(true); effects=game.effects.duplicate(); impact_layer.markers.clear()
	for fx in effects:
		var marker: Dictionary=fx.duplicate(); marker.point=hit_position(fx.x,fx.lane,int(fx.get("target_id",-1))); impact_layer.markers.append(marker)
	impact_layer.queue_redraw()
	for beam in beams:
		var key: String="%d:%.3f:%.3f" % [beam.lane,beam.x,game.elapsed+beam.life]
		if not seen.has(key):
			var point:=hit_position(beam.x,beam.lane,int(beam.get("target_id",-1)))
			towers[beam.lane].shoot(point,beam.boost)
			beam_geometry[key]={"from":towers[beam.lane].muzzle_position(),"to":point}
			seen[key]=elapsed
		beam.geometry=beam_geometry[key]
	for key in seen.keys():
		if elapsed-float(seen[key])>1: seen.erase(key); beam_geometry.erase(key)
	queue_redraw()
func hit_position(x: float,lane: int,id: int=-1) -> Vector2:
	if last_points.has(id): return last_points[id]
	var point:=path_position(x,lane)+Vector2(0,-16)
	var distance:=26.0
	for actor in actors.values():
		if actor.lane!=lane: continue
		var dx: float=absf(actor.position.x-x)
		if dx<distance: distance=dx; point=actor.position+actor.body.position
	return point
func _draw() -> void:
	for lane in range(2):
		var p:=path_position(150,lane)+Vector2(-62,0)
		draw_circle(p,16,Color("27362e")); draw_arc(p,16,0,TAU,24,Color("eab76b"),3 if lane==power_lane else 1,true)
		draw_string(ThemeDB.fallback_font,p+Vector2(-6,6),"A" if lane==0 else "B",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0cc"))
	for beam in beams:
		var from: Vector2=beam.geometry.from
		var to: Vector2=beam.geometry.to
		var age: float=.2-beam.life
		var a: float=clampf(1-age/(.14 if beam.lane==0 else .11),0,1)
		var c:=Color("ffe8ad") if beam.lane==0 else Color("e6ad50")
		var width:=1.8 if beam.boost else 1.1
		if beam.lane==0:
			draw_line(from,to,Color(.18,.14,.06,a*.85),width+2.2,true)
			draw_line(from,to,Color(c,a*.9),width,true)
			var tip:=from.lerp(to,clampf(age/.045,0,1))
			draw_line(tip-(to-from).normalized()*11,tip,Color(1,.94,.74,a),width+.6,true)
		else:
			var direction: Vector2=(to-from).normalized()
			var tip:=from.lerp(to,clampf(age/.055,0,1))
			var tail:=tip-direction*minf(from.distance_to(tip),24.0)
			draw_line(from,to,Color(.8,.55,.22,a*.16),1,true)
			draw_line(tail,tip,Color(.18,.14,.06,a*.9),width+2.5,true)
			draw_line(tail,tip,Color(c,a),width+1,true)
	if transfer>0:
		var end: Vector2=towers[power_lane].position+Vector2(0,-55)
		draw_dashed_line(Vector2(1053,291),end,Color(.95,.64,.22,.55),2,8,true)
	for lane in range(2):
		var points:=PackedVector2Array()
		for x in range(150,1000,20): points.append(path_position(x,lane)+Vector2(0,30))
		draw_polyline(points,Color(.20,.16,.10,.55),5,true)
		draw_polyline(points,Color(.65,.45,.23,.45) if stage==0 else Color(.98,.66,.24,.85),2,true)
		if stage>=1:
			for i in range(8):
				var x:=150+fmod(elapsed*38+i*110,840)
				var point:=path_position(x,lane)+Vector2(0,30)
				draw_circle(point,2.5,Color(1,.84,.44,.9))
	if stage>=3:
		draw_set_transform(Vector2(1053,347),0,Vector2(1,.45))
		draw_arc(Vector2.ZERO,79,0,TAU,48,Color(1,.68,.25,.55),2,true)
		draw_set_transform(Vector2.ZERO)
