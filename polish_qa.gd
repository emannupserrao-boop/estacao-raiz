extends SceneTree
const Rules = preload("res://defense.gd")
var checks := 0
var failures: Array[String] = []
var samples: Array[float] = []
var cases := []

func check(value: bool,label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run")

func key(code: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventKey.new()
	up.keycode = code
	Input.parse_input_event(up)
	await process_frame

func click_at(p: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=root.get_stretch_transform()*p
	Input.parse_input_event(motion)
	await process_frame
	var down := InputEventMouseButton.new()
	down.position = root.get_stretch_transform() * p
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.position = root.get_stretch_transform() * p
	up.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(up)
	await process_frame

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png("res://evidence/polish/"+name+".png")
	check(err == OK,"captura "+name)

func play(g,choice: int,cadence: int) -> void:
	var transfers := 0
	var duration := 0.0
	for wave in range(3):
		check(g.start(),"início ramo %d onda %d" % [choice,wave])
		var count := 0
		while g.mode == "wave" and count < 3000:
			if count % cadence == 0:
				var threat := [0.0,0.0]
				for e in g.enemies:
					if e.x >= 420: threat[e.lane] += e.hp/maxf(1.0,(1030-e.x)/(32.0 if e.heavy else 65.0))
				if maxf(threat[0],threat[1]) > 0:
					if g.switch_to(0 if threat[0]>threat[1] else 1): transfers += 1
			g.tick(0.05)
			count += 1
			duration += 0.05
		if g.mode == "lost": break
		if g.mode == "ready": check(g.buy(choice),"melhoria ramo %d etapa %d" % [choice,wave+1])
	cases.append({"branch":choice,"decision_every_seconds":cadence*0.05,"mode":g.mode,"wave":g.wave,"health":g.health,"credits":g.credits,"upgrade_level":g.upgrade_level,"transfers":transfers,"simulation_seconds":duration})
	check(g.mode == "won","campanha completa ramo %d" % choice)
	check(g.upgrade_level == 2 and g.credits == 3,"duas compras exclusivas e saldo final")
	var final_balance: int = g.credits
	for i in range(100): g.tick(0.05)
	check(g.credits == final_balance,"recompensa final não duplica")
	var fixture := FileAccess.open("res://local/polish-reopen.json",FileAccess.WRITE)
	fixture.store_string(JSON.stringify(g.checkpoint()))
	fixture.close()
	var copy = Rules.new()
	check(copy.restore(JSON.parse_string(JSON.stringify(g.checkpoint()))),"save nível II válido")
	check(copy.upgrade_level == 2 and copy.mode == "won","nível II restaurado")
	check(not copy.buy(3),"tipo de upgrade inválido")

func run() -> void:
	var encounter_times := {}
	for targets in [1,3]:
		for branch in [1,2]:
			var duel = Rules.new()
			duel.upgrade = branch
			duel.upgrade_level = 2
			duel.start()
			duel.spawned = duel.total_enemies()
			for i in range(targets): duel.enemies.append({"id":i,"lane":0,"x":600.0-i*25,"hp":20.0,"max_hp":20.0,"heavy":true,"flash":0.0})
			var seconds := 0.0
			while duel.mode == "wave" and seconds < 15:
				duel.tick(0.05)
				seconds += 0.05
			encounter_times["%d-alvos-ramo-%d" % [targets,branch]] = seconds
	check(encounter_times["1-alvos-ramo-1"] < encounter_times["1-alvos-ramo-2"],"Capacitor preserva vantagem contra alvo único")
	check(encounter_times["3-alvos-ramo-2"] < encounter_times["3-alvos-ramo-1"],"Divisor tem vantagem contra grupo")
	for choice in [1,2]:
		var g = Rules.new()
		play(g,choice,40)
		g = Rules.new()
		play(g,choice,80)
	var g = Rules.new()
	var legacy := {"version":1,"wave":1,"credits":0,"upgrade":2,"selected":1,"health":8}
	check(g.restore(legacy) and g.upgrade_level == 1,"compatibilidade com save da primeira fatia")
	var invalid := legacy.duplicate()
	invalid.upgrade_level = "dois"
	check(not g.restore(invalid),"nível textual rejeitado")
	invalid.upgrade_level = 1.5
	check(not g.restore(invalid),"nível fracionário rejeitado")
	invalid.upgrade_level = 2
	check(not g.restore(invalid),"nível comprado sem recurso rejeitado")
	g = Rules.new()
	g.start()
	g.switch_to(1)
	for i in range(20): g.tick(0.05)
	check(g.transfer == 0.0 and "estabilizada" in g.message,"fim de transferência comunicado")
	var arena = load("res://main.tscn").instantiate()
	root.size = Vector2i(1200,760)
	root.add_child(arena)
	arena.save_path = "res://local/polish-save.json"
	await process_frame
	await key(KEY_2)
	check(arena.game.selected == 1,"tecla 2 distribui")
	await click_at(Vector2(750,215))
	check(arena.game.selected == 0,"clique no emissor A")
	await click_at(arena.buttons.start.get_global_rect().get_center())
	check(arena.game.mode == "wave","início pelo botão")
	# Espaço deve funcionar mesmo com o foco no botão recém-clicado.
	await key(KEY_SPACE)
	check(arena.paused,"espaço pausa com foco em botão")
	var elapsed: float = arena.game.elapsed
	await key(KEY_2)
	check(arena.game.selected == 0 and arena.game.elapsed == elapsed,"sem transferência ou avanço na pausa")
	await click_at(arena.buttons.help.get_global_rect().get_center())
	await key(KEY_ESCAPE)
	check(arena.paused and not arena.show_help,"ajuda preserva pausa anterior")
	await key(KEY_SPACE)
	check(not arena.paused,"espaço retoma")
	await key(KEY_2)
	check(arena.game.transfer > 0,"atalho em combate inicia transferência")
	# Estado equivalente ao antes: primeira onda, B reforçada, aproximadamente 11,5s.
	arena.game = Rules.new()
	arena.game.selected = 1
	arena.game.start()
	for i in range(230): arena._process(0.05)
	await capture("depois-combate")
	arena.game.switch_to(0)
	arena._process(0.05)
	await capture("depois-transferencia")
	check(arena.buttons.top.disabled and arena.buttons.bottom.disabled,"transferência bloqueia clique concorrente")
	for i in range(20): arena._process(0.05)
	# Mede quadro real durante combate, com desenho procedural, sem carga paralela.
	for i in range(120): await process_frame
	for i in range(180):
		await process_frame
		samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS))*1000.0)
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	root.size = Vector2i(960,608)
	for i in range(20): await process_frame
	await capture("depois-960x608")
	var small_size: Vector2i = Image.load_from_file("res://evidence/polish/depois-960x608.png").get_size()
	check(small_size.x == 960,"captura resolução menor real")
	for b in arena.buttons.values():
		check(b.get_rect().end.x <= 1200 and b.get_rect().end.y <= 760,"controle cabe no canvas lógico")
	arena.game = Rules.new()
	arena._refresh()
	await click_at(arena.buttons.bottom.get_global_rect().get_center())
	check(arena.game.selected == 1,"clique real em janela menor")
	await key(KEY_SPACE)
	check(arena.game.mode == "wave","atalho inicia em janela menor")
	root.size = Vector2i(1200,760)
	for i in range(20): await process_frame
	# Retomada após derrota precisa preservar a melhoria e o ponto de onda.
	arena.game = Rules.new()
	arena.game.restore({"version":1,"wave":1,"credits":0,"upgrade":2,"selected":1,"health":8})
	arena._save_checkpoint()
	arena.game.mode = "lost"
	arena.game.health = 0
	arena._refresh()
	await capture("depois-derrota")
	await click_at(arena.buttons.start.get_global_rect().get_center())
	check(arena.game.mode == "ready" and arena.game.health == 8 and arena.game.upgrade == 2,"retry preserva checkpoint")
	await capture("depois-melhorias")
	arena._reset()
	await key(KEY_ESCAPE)
	check(not arena.confirm_reset and arena.game.wave == 1,"Esc cancela reset sem perda")
	arena._reset()
	arena._reset()
	check(arena.game.wave == 0 and arena.game.upgrade_level == 0,"reset limpa níveis novos")
	arena.game = Rules.new()
	arena._load_checkpoint()
	check(arena.game.wave == 0,"reset persiste na reabertura")
	# Arquivo truncado não deve quebrar a cena ou remover o arquivo na leitura.
	var file := FileAccess.open(arena.save_path,FileAccess.WRITE)
	file.store_string("{truncado")
	file.close()
	arena.game = Rules.new()
	arena._load_checkpoint()
	check(arena.failure != "" and arena.game.wave == 0,"arquivo truncado dá aviso e estado seguro")
	check(FileAccess.get_file_as_string(arena.save_path) == "{truncado","leitura preserva arquivo inválido")
	arena.failure = ""
	arena._save_checkpoint()
	samples.sort()
	var report := {"checks":checks,"failures":failures,"branches":cases,"isolated_encounter_seconds":encounter_times,"performance":{"warmup_frames":120,"frames":samples.size(),"fps_monitor":fps,"process_ms_median":samples[samples.size()/2],"process_ms_p95":samples[int(samples.size()*0.95)],"max_process_ms":samples[-1],"small_capture_size":small_size,"viewport":"1200x760 then requested 960x608","renderer":"Compatibility / OpenGL"},"human_playtest":false}
	file = FileAccess.open("res://evidence/polish/qa-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
