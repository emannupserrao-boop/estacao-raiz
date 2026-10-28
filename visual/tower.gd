extends Node2D
var route:=0
var pulse:=0.0
var powered:=false
var shot_boost:=false
var flash_duration:=.14
var sap_phase:=0.0
var transferring:=false
var neck: Node2D
var face: Node2D
var recoil: Node2D
var head: Sprite2D
var muzzle: Marker2D
var player: AnimationPlayer
var module: Sprite2D
var buds: Array[Sprite2D]=[]
var petals: Array[Node2D]=[]
@onready var base: Sprite2D=$Art
func configure(lane: int) -> void:
	route=lane
	var prefix:="seed" if lane==0 else "flower"
	base.texture=load("res://assets/parts/%s_base.png" % prefix)
	base.scale=Vector2.ONE*.42
	base.position.y=-106*.42
	neck=Node2D.new(); neck.name="Neck"; neck.position=Vector2(0,-82); add_child(neck)
	face=Node2D.new(); face.name="Face"; face.scale.x=-1; neck.add_child(face)
	recoil=Node2D.new(); recoil.name="Recoil"; face.add_child(recoil)
	head=Sprite2D.new(); head.texture=load("res://assets/parts/%s_head.png" % prefix)
	head.scale=Vector2.ONE*(.40 if lane==0 else .43); head.position.x=30; recoil.add_child(head)
	muzzle=Marker2D.new(); muzzle.position=Vector2(72,0); recoil.add_child(muzzle)
	if lane==1:
		for i in range(2):
			var hinge:=Node2D.new(); hinge.position=Vector2(38,0); hinge.z_index=-1; recoil.add_child(hinge)
			var petal:=Sprite2D.new(); petal.texture=load("res://assets/parts/petal.png"); petal.scale=Vector2.ONE*.17; petal.position.y=-17; hinge.add_child(petal); petals.append(hinge)
	player=AnimationPlayer.new(); player.name="RecoilAnimation"; player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL; add_child(player)
	var animation:=Animation.new(); animation.length=.19 if lane==0 else .085
	var index:=animation.add_track(Animation.TYPE_VALUE); animation.track_set_path(index,NodePath("Neck/Face/Recoil:position"))
	animation.track_insert_key(index,0,Vector2.ZERO)
	animation.track_insert_key(index,animation.length*.16,Vector2(-6 if lane==0 else -2.8,0))
	animation.track_insert_key(index,animation.length*.64,Vector2(.8 if lane==0 else .35,0))
	animation.track_insert_key(index,animation.length,Vector2.ZERO)
	index=animation.add_track(Animation.TYPE_VALUE); animation.track_set_path(index,NodePath("Neck/Face/Recoil:scale"))
	animation.track_insert_key(index,0,Vector2.ONE); animation.track_insert_key(index,animation.length*.16,Vector2(.96,1.04) if lane==0 else Vector2(.98,1.06)); animation.track_insert_key(index,animation.length,Vector2.ONE)
	var library:=AnimationLibrary.new(); library.add_animation("shot",animation); player.add_animation_library("",library)
	module=Sprite2D.new(); module.texture=load("res://assets/parts/reserve_module.png"); module.position=Vector2(31,-27); module.scale=Vector2.ONE*.18; add_child(module)
	for i in range(2):
		var bud:=Sprite2D.new(); bud.texture=load("res://assets/parts/bud.png"); bud.position=Vector2(-29+i*12,-33-i*7); bud.scale=Vector2.ONE*.12; add_child(bud); buds.append(bud)
	set_upgrade(0,0)
func set_upgrade(choice: int,level: int) -> void:
	module.visible=choice==1
	module.scale=Vector2.ONE*(.16+level*.025)
	for i in range(buds.size()): buds[i].visible=choice==2 and i<level
func present(active: bool,transfer_time: float,dt: float) -> void:
	powered=active; transferring=transfer_time>0; sap_phase+=dt; pulse=maxf(0,pulse-dt); player.advance(dt)
	base.self_modulate=Color.WHITE if active else Color(.84,.86,.78)
	head.self_modulate=Color.WHITE if active else Color(.78,.81,.73)
	var opening:=sin(clampf(pulse/flash_duration,0,1)*PI*.5)
	for i in range(petals.size()):
		petals[i].rotation=(1.05 if i==0 else 2.10)+(-1 if i==0 else 1)*opening*.38
		petals[i].scale=Vector2.ONE*(1+opening*.10)
	queue_redraw()
func shoot(target: Vector2,boosted: bool=false) -> void:
	var direction:=target-neck.global_position
	var left:=direction.x<0
	face.scale.x=-1 if left else 1
	neck.rotation=wrapf(direction.angle()-(PI if left else 0),-PI,PI)
	shot_boost=boosted; flash_duration=.14 if route==0 else .095
	player.stop(); player.play("shot"); player.advance(0); pulse=flash_duration
func muzzle_position() -> Vector2: return muzzle.global_position
func reset_pose() -> void:
	player.stop(); recoil.position=Vector2.ZERO; recoil.scale=Vector2.ONE
	neck.rotation=0; face.scale.x=-1; pulse=0
	shot_boost=false; sap_phase=0; transferring=false
	for i in range(petals.size()):
		petals[i].rotation=1.05 if i==0 else 2.10
		petals[i].scale=Vector2.ONE
func set_paused(_value: bool) -> void: pass
func _draw() -> void:
	draw_line(Vector2(0,-45),Vector2(0,-82),Color("332719"),8,true)
	draw_line(Vector2(0,-45),Vector2(0,-82),Color("a1723e"),4,true)
	draw_circle(Vector2(0,-73),5,Color("cfaa68"))
	if powered:
		draw_set_transform(Vector2(0,-2),0,Vector2(1,.4))
		for i in range(3): draw_arc(Vector2.ZERO,46,TAU*i/3+.12,TAU*(i+1)/3-.12,14,Color(.95,.66,.25,.72),2,true)
		draw_circle(Vector2.from_angle(sap_phase*1.8)*46,3,Color("ffe3a0")); draw_set_transform(Vector2.ZERO)
	elif transferring:
		draw_arc(Vector2(0,-73),8,sap_phase*8,sap_phase*8+PI,12,Color(.95,.66,.25,.8),1.5,true)
	if pulse>0 and muzzle!=null:
		var p:=to_local(muzzle.global_position)
		var axis:=to_local(muzzle.global_position+recoil.global_transform.x.normalized())-p
		var normal:=axis.orthogonal()
		var fade:=pulse/flash_duration
		var reach:=(13.0 if route==0 else 9.0)*(1.0 if shot_boost else .72)
		draw_line(p-axis*3,p+axis*reach,Color(.18,.12,.04,fade),5,true)
		draw_line(p-axis*2,p+axis*reach,Color(1,.88,.56,fade*.9),2.2,true)
		if route==1:
			for side in [-1,1]: draw_line(p+normal*side*3,p+axis*6+normal*side*5,Color(1,.72,.32,fade*.75),1.4,true)
