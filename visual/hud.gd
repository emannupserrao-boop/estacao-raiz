extends Control
signal intent(action: String,value: int)
signal volume_changed(value: float)
var volume_slider: HSlider
var buttons := {}
var status: Label
var caption: Label
var stats: Label
var forecast: Label
var power: Label
var combat_tip: Label
var upgrade_row: HBoxContainer
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Trebuchet MS","Segoe UI"])
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 16
	theme.set_color("font_color","Label",Color("f4eedb"))
	theme.set_color("font_color","Button",Color("f4eedb"))
	theme.set_color("font_disabled_color","Button",Color("91a08d"))
	for mode in ["normal","hover","pressed","disabled","focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color("333f35") if mode != "hover" else Color("50684f")
		if mode == "disabled": s.bg_color = Color("252e29")
		s.border_color = Color("b8a675") if mode in ["hover","focus"] else Color("687660")
		s.set_border_width_all(2 if mode == "focus" else 1)
		s.set_corner_radius_all(7)
		s.content_margin_left = 10
		s.content_margin_right = 10
		s.content_margin_top = 7
		s.content_margin_bottom = 7
		theme.set_stylebox(mode,"Button",s)
	self.theme = theme
	var top := _panel(Rect2(20,14,1160,58))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	top.add_child(row)
	var title := _label("ESTAÇÃO RAIZ",21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	stats = _label("",17)
	row.add_child(stats)
	row.add_child(_button("help","Como jogar",110,func(): intent.emit("help",0)))
	row.add_child(_button("mute","Som: ligado",112,func(): intent.emit("mute",0)))
	volume_slider = HSlider.new()
	volume_slider.name = "Volume"
	volume_slider.custom_minimum_size = Vector2(85,30)
	volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.05
	volume_slider.tooltip_text = "Volume dos efeitos sonoros"
	volume_slider.value_changed.connect(func(value: float): volume_changed.emit(value))
	row.add_child(volume_slider)
	forecast = _label("",17)
	forecast.position = Vector2(30,86)
	forecast.add_theme_color_override("font_shadow_color",Color("111c12"))
	forecast.add_theme_constant_override("shadow_offset_x",1)
	forecast.add_theme_constant_override("shadow_offset_y",2)
	add_child(forecast)
	caption = _label("",15)
	caption.position = Vector2(30,612)
	caption.add_theme_color_override("font_shadow_color",Color("101b11"))
	caption.add_theme_constant_override("shadow_offset_y",2)
	add_child(caption)
	var dock := _panel(Rect2(20,646,1160,100))
	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation",16)
	dock.add_child(dock_row)
	var power_box := VBoxContainer.new()
	power_box.custom_minimum_size.x = 225
	dock_row.add_child(power_box)
	power = _label("",16)
	power_box.add_child(power)
	var controls := HBoxContainer.new()
	power_box.add_child(controls)
	controls.add_child(_button("top","A  [1]",105,func(): intent.emit("route",0)))
	controls.add_child(_button("bottom","B  [2]",105,func(): intent.emit("route",1)))
	var middle := VBoxContainer.new()
	middle.custom_minimum_size.x = 570
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock_row.add_child(middle)
	upgrade_row = HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation",10)
	middle.add_child(upgrade_row)
	upgrade_row.add_child(_button("upgrade1","",270,func(): intent.emit("buy",1)))
	upgrade_row.add_child(_button("upgrade2","",270,func(): intent.emit("buy",2)))
	combat_tip = _label("",16)
	combat_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_tip.custom_minimum_size = Vector2(540,64)
	middle.add_child(combat_tip)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 265
	dock_row.add_child(actions)
	actions.add_child(_button("start","",260,func(): intent.emit("start",0)))
	var small := HBoxContainer.new()
	actions.add_child(small)
	small.add_child(_button("pause","Pausa",125,func(): intent.emit("pause",0)))
	small.add_child(_button("reset","Novo ciclo",125,func(): intent.emit("reset",0)))
	status = _label("",14)
	status.visible = false
	add_child(status)
	overlay = _panel(Rect2(260,205,680,230))
	var message_box := VBoxContainer.new()
	message_box.add_theme_constant_override("separation",16)
	overlay.add_child(message_box)
	overlay_title = _label("",29)
	message_box.add_child(overlay_title)
	overlay_text = _label("",18)
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_box.add_child(overlay_text)
	overlay.visible = false

func _panel(rect: Rect2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1,0.15,0.12,0.94)
	s.border_color = Color("887e57")
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel",s)
	add_child(p)
	return p

func present_audio(value: float,muted: bool,error: String) -> void:
	buttons.mute.text = "Som: mudo" if muted or value <= 0 else "Som: ligado"
	buttons.mute.tooltip_text = "Ativar ou silenciar efeitos. " + error
	volume_slider.set_value_no_signal(value)
	volume_slider.tooltip_text = "Volume dos efeitos: %d%%" % roundi(value*100)

func _label(text: String,size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(id: String,text: String,width: int,callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width,34)
	b.clip_text = true
	b.pressed.connect(callback)
	buttons[id] = b
	return b

func present(game,paused: bool,help: bool,confirm_reset: bool,message: String) -> void:
	stats.text = "Coração %02d / 10   •   %02d brotos   •   Estufa %d / 3" % [game.health,game.credits,game.wave]
	forecast.text = game.forecast() if game.mode in ["ready","wave"] else "Operação encerrada"
	power.text = "Fluxo em " + ("A · Cápsula" if game.selected == 0 else "B · Flor")
	if game.transfer > 0: power.text = "Transferindo  %.1fs" % game.transfer
	power.modulate = Color("f5cd7e") if game.transfer > 0 else Color("e9bd77")
	caption.text = message
	for lane in range(2): buttons["top" if lane==0 else "bottom"].disabled = help or paused or game.selected == lane or game.transfer>0 or game.mode not in ["ready","wave"]
	upgrade_row.visible = game.mode == "ready"
	combat_tip.visible = not upgrade_row.visible
	combat_tip.text = "A: cápsula precisa · B: flor em 3 pulsos.\n1 / 2 move a seiva. Trocar reduz o dano por 0,9s."
	for choice in [1,2]:
		var b: Button = buttons["upgrade%d" % choice]
		var name := "Reserva de seiva" if choice==1 else "Rede de raízes"
		var desc := "Troca rápida · guarda dano base" if choice==1 else "Mais alvos · menos energia por alvo"
		var next_level: int=mini(2,game.upgrade_level+1) if game.upgrade==choice else 1
		if choice==1: desc="Troca "+("0,45s" if next_level==1 else "0,18s")+" · guarda dano base"
		else: desc="%d alvos · menos dano individual" % (next_level+1)
		b.tooltip_text="Reserva preserva dano básico durante a troca. Reconecta em 0,45s no nível I e 0,18s no II." if choice==1 else "Rede divide o reforço entre 2 ou 3 alvos. Cada alvo recebe menos energia; a flor reparte essa energia em três pulsos."
		var price := "3 brotos" if game.upgrade!=choice else ("II instalada" if game.upgrade_level==2 else "I → II · 3 brotos")
		if game.upgrade!=0 and game.upgrade!=choice: price="outra linha escolhida"
		b.text = name+" / "+price+"\n"+desc
		b.disabled = help or game.mode!="ready" or (game.upgrade!=0 and game.upgrade!=choice) or game.upgrade_level>=2 or game.credits<3
	buttons.start.text = "Restaurar setor %d  [Espaço]" % (game.wave+1)
	if game.mode=="wave": buttons.start.text="Defendendo a estufa"
	if game.mode=="lost": buttons.start.text="Retomar checkpoint"
	if game.mode=="won": buttons.start.text="Estufa restaurada"
	buttons.start.disabled = help or game.mode in ["wave","won"]
	buttons.pause.text="Retomar" if paused else "Pausa [Espaço]"
	buttons.pause.disabled=game.mode!="wave"
	buttons.reset.text="Confirmar?" if confirm_reset else "Novo ciclo"
	overlay.visible = help or paused or game.mode in ["lost","won"]
	overlay.position=Vector2(30,118) if game.mode=="won" and not help else Vector2(260,205)
	overlay.size=Vector2(470,175) if game.mode=="won" and not help else Vector2(680,230)
	overlay_title.text = "Faça a estação respirar"
	overlay_text.text = "Um coração alimenta duas defesas: a cápsula concentra um pulso; a flor dispara três pulsos curtos. Use 1 / 2 ou clique na via para mover a seiva. A troca leva 0,9s e reduz o dano.\n\nReserva acelera a troca e guarda dano básico. Rede atinge mais alvos com menos dano individual. Três defesas restauram a estufa. Espaço pausa; sair no combate retoma o setor salvo."
	if not help:
		if paused:
			overlay_title.text="Operação pausada"
			overlay_text.text="Espaço ou Retomar para continuar. Nenhuma rota avança durante a pausa."
		elif game.mode=="won":
			overlay_title.text="A Estação Raiz respira"
			overlay_text.text="Três setores reativados. Coração: %d / 10.\nNovo ciclo: experimente a outra melhoria." % game.health
		elif game.mode=="lost":
			overlay_title.text="Coração adormecido"
			overlay_text.text="As criaturas alcançaram o coração. Retome o checkpoint para defender este setor sem perder sua melhoria."
