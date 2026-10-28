extends SceneTree
const Rules = preload("res://defense.gd")
var checks := 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func simulate(g, policy: int) -> void:
	var steps := 0
	while g.mode == "wave" and steps < 3000:
		if policy == 2 and steps % 40 == 0:
			var threat := [0.0,0.0]
			for e in g.enemies:
				if e.x > 420: threat[e.lane] += e.hp / maxf(1.0,(1030.0-e.x)/(32.0 if e.heavy else 65.0))
			if maxf(threat[0],threat[1]) > 0:
				g.switch_to(0 if threat[0] > threat[1] else 1)
		g.tick(0.05)
		steps += 1
	check(steps < 3000,"onda termina sem bloqueio")

func _initialize() -> void:
	call_deferred("run")

func click(button: Button) -> void:
	var p := button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = root.get_stretch_transform() * p
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = root.get_stretch_transform() * p
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame

func run() -> void:
	var outcomes := []
	for policy in range(3):
		var g = Rules.new()
		g.selected = mini(policy,1)
		for i in range(3):
			if not g.start(): break
			simulate(g,policy)
			if g.mode == "ready": g.buy(1)
		outcomes.append({"policy":policy,"mode":g.mode,"health":g.health,"waves":g.wave})
	var g = Rules.new()
	check(not g.buy(1),"compra sem saldo rejeitada")
	check(not g.switch_to(5),"rota inválida rejeitada")
	check(g.start(),"inicia onda")
	check(not g.start(),"início duplicado rejeitado")
	check(g.switch_to(1),"transfere reforço")
	check(g.transfer > 0,"transferência tem custo")
	check(not g.switch_to(0),"bloqueia transferência concorrente")
	check(not g.buy(2),"compra no combate rejeitada")
	check(not g.restore({}),"save incompleto rejeitado")
	check(not g.restore({"version":1,"wave":1,"credits":999,"upgrade":0,"selected":0,"health":10}),"save com crédito impossível rejeitado")
	check(not g.restore({"version":1,"wave":0,"credits":0,"upgrade":1,"selected":0,"health":10}),"melhoria precoce rejeitada")
	check(not g.restore({"version":1,"wave":1,"credits":0,"upgrade":0,"selected":0,"health":NAN}),"NaN rejeitado")
	check(g.restore({"version":1,"wave":1,"credits":3,"upgrade":0,"selected":0,"health":8}),"checkpoint válido")
	check(g.buy(1) and g.credits == 0,"compra debita uma vez")
	check(not g.buy(2) and g.credits == 0,"melhorias exclusivas")
	var restored = Rules.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(g.checkpoint()))),"roundtrip JSON")
	check(restored.wave == 1 and restored.credits == 0 and restored.upgrade == 1,"estado restaurado sem novo prêmio")
	g = Rules.new()
	g.start()
	g.enemies.clear()
	g.enemies.append({"lane":0,"x":1040.0,"hp":20.0,"max_hp":20.0,"heavy":true})
	g.health = 1
	g.tick(0.01)
	check(g.mode == "lost" and g.health == 0,"derrota e piso de vida")
	for choice in [1,2]:
		g = Rules.new()
		g.restore({"version":1,"wave":2,"credits":3,"upgrade":0,"selected":0,"health":10})
		g.buy(choice)
		g.start()
		simulate(g,2)
		check(g.mode == "won","final alcançável com melhoria %d" % choice)
	var arena = load("res://main.tscn").instantiate()
	root.size = Vector2i(1200,760)
	root.add_child(arena)
	arena.save_path = "res://local/qa-save.json"
	for i in range(20): await process_frame
	check(arena.game.wave == 0,"QA começa isolado do jogador")
	await click(arena.buttons.bottom)
	check(arena.game.selected == 1,"clique real muda distribuição")
	await click(arena.buttons.start)
	check(arena.game.mode == "wave","clique real inicia onda")
	await click(arena.buttons.pause)
	var t: float = arena.game.elapsed
	await process_frame
	check(arena.paused and arena.game.elapsed == t,"pausa impede simulação")
	await click(arena.buttons.pause)
	check(not arena.paused,"retoma simulação")
	for i in range(230): arena.game.tick(0.05)
	arena._refresh()
	arena.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/01-combate.png")
	# Interromper combate deve carregar o checkpoint, sem simulação serializada.
	arena.game = Rules.new()
	arena._load_checkpoint()
	check(arena.game.mode == "ready" and arena.game.wave == 0 and arena.game.selected == 1,"reabertura volta ao intervalo")
	arena.game.restore({"version":1,"wave":1,"credits":3,"upgrade":0,"selected":0,"health":8})
	arena._refresh()
	await click(arena.buttons.upgrade2)
	check(arena.game.upgrade == 2 and arena.game.credits == 0,"UI compra e grava")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(arena.save_path))
	check(saved.upgrade == 2 and saved.credits == 0,"save contém compra real")
	var fixture := FileAccess.open("res://local/reopen-checkpoint.json",FileAccess.WRITE)
	fixture.store_string(JSON.stringify(saved))
	fixture.close()
	await click(arena.buttons.reset)
	check(arena.game.wave == 1,"reset exige confirmação")
	await click(arena.buttons.reset)
	check(arena.game.wave == 0 and arena.game.credits == 0 and arena.game.upgrade == 0,"reset limpa estado")
	arena.game = Rules.new()
	arena._load_checkpoint()
	check(arena.game.wave == 0 and arena.game.upgrade == 0,"reset persistido")
	arena._refresh()
	arena.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/02-reset.png")
	# Ciclo de integração: callbacks da arena detectam fins e persistem checkpoints.
	for round_index in range(3):
		await click(arena.buttons.start)
		var steps := 0
		while arena.game.mode == "wave" and steps < 3000:
			if steps % 40 == 0:
				var threat := [0.0,0.0]
				for e in arena.game.enemies:
					if e.x > 420: threat[e.lane] += e.hp / maxf(1.0,(1030-e.x)/(32.0 if e.heavy else 65.0))
				if maxf(threat[0],threat[1]) > 0: arena.game.switch_to(0 if threat[0] > threat[1] else 1)
			arena._process(0.05)
			steps += 1
		check(arena.game.wave == round_index + 1,"integração completa onda %d" % (round_index+1))
		if round_index == 0:
			await click(arena.buttons.upgrade1)
			check(arena.game.upgrade == 1,"integração escolhe melhoria")
	check(arena.game.mode == "won" and arena.game.credits == 6,"vitória integrada e economia")
	saved = JSON.parse_string(FileAccess.get_file_as_string(arena.save_path))
	check(saved.wave == 3 and saved.credits == 6,"checkpoint final integrado")
	arena._refresh()
	arena.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/03-vitoria.png")
	var report := {"checks":checks,"failures":failures,"policies":outcomes,"human_playtest":false}
	var file := FileAccess.open("res://evidence/qa-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
