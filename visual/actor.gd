extends Node2D
var phase:=0.0
var lane:=0
var large:=false
var dying:=false
var ratio:=1.0
var trail_ratio:=1.0
var damage_echo:=0.0
var death_tween: Tween
var leg_pivots: Array[Node2D]=[]
var leg_roots: Array[Vector2]=[]
@onready var body: Sprite2D=$Art
func configure(heavy: bool) -> void:
	large=heavy
	var prefix:="armor" if heavy else "runner"
	body.texture=load("res://assets/parts/%s_body.png" % prefix)
	body.scale=Vector2.ONE*(.30 if heavy else .29); body.position.y=-29 if heavy else -27
	for side in range(2):
		for index in range(3):
			var pivot:=Node2D.new(); pivot.position=Vector2(-23+index*20,(-29 if heavy else -27)+side*3); pivot.z_index=-1 if side==0 else 1; add_child(pivot)
			var leg:=Sprite2D.new(); leg.texture=load("res://assets/parts/%s_leg_%s.png" % [prefix,"l" if side==0 else "r"])
			var factor:=.145 if heavy else .135
			leg.scale=Vector2(factor,factor); leg.position.y=108*factor
			pivot.add_child(leg); leg_pivots.append(pivot); leg_roots.append(pivot.position)
func present(e: Dictionary,dt: float) -> void:
	if dying: return
	lane=int(e.lane)
	phase=float(e.x)*(.115 if large else .185)+int(e.id)*1.7
	for i in range(leg_pivots.size()):
		var sign:=-1.0 if i<3 else 1.0
		var stride: float=phase+(i%3)*2.1+(PI if i>=3 else 0)
		leg_pivots[i].rotation=sin(stride)*(.24 if large else .38)+sign*.08
		leg_pivots[i].position=leg_roots[i]+Vector2(0,-maxf(0,cos(stride))*(1.4 if large else 3.0))
	var next:=clampf(float(e.hp)/float(e.max_hp),0,1)
	if next<ratio-.001:
		trail_ratio=maxf(trail_ratio,ratio) if damage_echo>0 else ratio
		damage_echo=.24
	ratio=next; damage_echo=maxf(0,damage_echo-dt)
	body.position.x=-sin((1-damage_echo/.24)*PI)*1.5 if damage_echo>0 else 0
	body.position.y=(-29 if large else -27)+sin(phase*2)*(.8 if large else 1.6)
	body.rotation=sin(phase*2)*(.012 if large else .024)
	body.self_modulate=Color.WHITE.lerp(Color(1,.88,.66),damage_echo/.24*.42)
	queue_redraw()
func die() -> void:
	if dying: return
	dying=true
	death_tween=create_tween().set_parallel(true)
	death_tween.tween_property(self,"modulate:a",0.0,.38)
	death_tween.tween_property(body,"rotation",.14 if large else .30,.3)
	death_tween.tween_property(body,"position:y",body.position.y+5,.3)
	for i in range(leg_pivots.size()):
		death_tween.tween_property(leg_pivots[i],"rotation",(-.34 if i<3 else .34),.22)
		death_tween.tween_property(leg_pivots[i],"position:y",leg_roots[i].y+3,.22)
	death_tween.chain().tween_callback(queue_free)
func set_paused(value: bool) -> void:
	if death_tween!=null and death_tween.is_valid(): death_tween.set_speed_scale(0 if value else 1)
func _draw() -> void:
	draw_set_transform(Vector2(0,4),0,Vector2(1,.28)); draw_circle(Vector2.ZERO,28 if large else 23,Color(.12,.14,.09,.36)); draw_set_transform(Vector2.ZERO)
	if ratio<.999 and not dying:
		draw_rect(Rect2(-20,-58,40,5),Color("292c21"))
		if damage_echo>0: draw_rect(Rect2(-19+38*ratio,-57,38*maxf(0,trail_ratio-ratio),3),Color(1,.94,.74,damage_echo/.24))
		draw_rect(Rect2(-19,-57,38*ratio,3),Color("f1bb65"))
