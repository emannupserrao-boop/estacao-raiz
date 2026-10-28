extends Node2D
# Small botanical marks above bodies; no full-screen flashes or pooled particles.
var markers: Array[Dictionary] = []
func leaf(p: Vector2,axis: Vector2,length: float,width: float,color: Color) -> void:
	var side:=axis.orthogonal()*width
	var shape:=PackedVector2Array([p-axis*length*.5,p+side,p+axis*length*.5,p-side])
	draw_colored_polygon(shape,color)
	draw_polyline(PackedVector2Array([shape[0],shape[1],shape[2],shape[3],shape[0]]),Color(.15,.12,.06,color.a*.8),1.2,true)
func _draw() -> void:
	for fx in markers:
		var p: Vector2 = fx.point
		var t: float = clampf(1.0-fx.life/fx.max,0,1)
		var fade: float=(1-t)*(1-t)
		var c:=Color("ffe4a0") if fx.lane==0 else Color("eab85d")
		if fx.kind=="leak":
			draw_arc(p,7+t*18,0,TAU,24,Color(.9,.36,.22,fade*.8),2,true)
			continue
		if fx.kind=="kill":
			for i in range(4):
				var direction:=Vector2.from_angle(TAU*i/4+.4)
				leaf(p+direction*(7+t*18)+Vector2(0,t*t*8),direction.rotated(t*.5),7,2.1,Color(.78,.61,.29,fade*.85))
			continue
		draw_circle(p,2.8*(1-t)+.5,Color(.15,.12,.05,fade*.9))
		draw_circle(p,1.6*(1-t)+.5,Color(1,.92,.67,fade))
		if fx.lane==0:
			for i in range(4):
				var direction:=Vector2.from_angle(TAU*i/4+PI/4)
				var start:=p+direction*(4+t*9)
				draw_line(start,start+direction*(5*(1-t)+1),Color(.15,.12,.05,fade),3.4,true)
				draw_line(start,start+direction*(5*(1-t)+1),Color(c,fade*.95),1.6,true)
		else:
			for i in range(3):
				var direction:=Vector2.from_angle(TAU*i/3-.35)
				leaf(p+direction*(4+t*11),direction.rotated(.35),5.5,1.8,Color(c,fade*.9))
