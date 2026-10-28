extends RefCounted
## Regras sem dependência da interface ou do caminho de save.
var wave := 0
var credits := 0
var upgrade := 0
var upgrade_level := 0
var selected := 0
var transfer := 0.0
var health := 10
var mode := "ready"
var elapsed := 0.0
var spawn_clock := 0.0
var shot_clock := 0.0
var burst_clock := 0.0
var burst_remaining := 0
var spawned := 0
var enemies: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var serial := 0
var kills := 0
var transfers := 0
var message := "Organismos desregulados seguem a seiva. Defenda o coração e faça a estufa respirar."

func start() -> bool:
	if mode != "ready": return false
	mode = "wave"
	elapsed = 0.0
	spawn_clock = 0.0
	shot_clock = 0.0
	burst_clock = 0.0
	burst_remaining = 0
	spawned = 0
	transfer = 0.0
	enemies.clear()
	beams.clear()
	effects.clear()
	message = "Proteja o coração: a cápsula concentra energia; a flor reparte em três pulsos."
	return true

func switch_to(lane: int) -> bool:
	if lane not in [0, 1] or mode not in ["ready", "wave"]: return false
	if lane == selected or transfer > 0.0: return false
	selected = lane
	transfer = (0.18 if upgrade_level == 2 else 0.45) if upgrade == 1 else 0.9
	if mode == "ready": transfer = 0.0
	if mode == "wave": transfers += 1
	message = "Transferindo: aguarde a conexão." if transfer > 0 else "Distribuição preparada."
	return true

func buy(choice: int) -> bool:
	if mode != "ready" or choice not in [1, 2] or (upgrade != 0 and choice != upgrade) or upgrade_level >= 2 or credits < 3: return false
	credits -= 3
	upgrade = choice
	upgrade_level += 1
	message = "Reserva instalada: troca rápida e dano básico preservado na transferência." if choice == 1 else "Rede de raízes: reforço distribuído por %d alvos, com menos dano individual." % (upgrade_level+1)
	return true

func total_enemies() -> int:
	return [14,16,18][mini(wave,2)]

func forecast() -> String:
	return ["I / Irrigação   •   corredores em A, carapaças em B", "II / Leitos   •   carapaças em A, corredores em B", "III / Coração   •   organismos mistos nas duas vias"][mini(wave,2)]

func tick(dt: float) -> void:
	if dt <= 0.0: return
	for fx in effects: fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0.0)
	for b in beams: b.life -= dt
	beams = beams.filter(func(b): return b.life > 0.0)
	if mode != "wave": return
	elapsed += dt
	var was_transferring := transfer > 0.0
	transfer = maxf(0.0, transfer - dt)
	if was_transferring and transfer == 0.0: message = "Conexão estabilizada. Reforço na rota %s." % ("A" if selected == 0 else "B")
	spawn_clock -= dt
	if spawned < total_enemies() and spawn_clock <= 0.0:
		var lane := 0 if spawned % 4 < 2 else 1
		if wave == 1: lane = 1 - lane
		var heavy := lane == (1 if wave != 1 else 0)
		if wave == 2:
			lane = floori(float(spawned) / 3.0) % 2
			heavy = spawned % 3 == 0
		var hp := 20.0 if heavy else 7.0
		serial += 1
		enemies.append({"id":serial,"lane":lane,"x":150.0,"hp":hp,"max_hp":hp,"heavy":heavy,"flash":0.0})
		spawned += 1
		spawn_clock = [1.15,1.03,0.95][mini(wave,2)]
	for e in enemies:
		e.x += dt * (32.0 if e.heavy else 65.0)
		e.flash = maxf(0.0,float(e.get("flash",0.0))-dt)
	shot_clock -= dt
	burst_clock -= dt
	if shot_clock <= 0.0:
		shot_clock = 0.55
		_shoot(0)
		burst_remaining = 3
		burst_clock = 0.0
	while burst_remaining > 0 and burst_clock <= 0.0:
		_shoot(1,1.0/3.0)
		burst_remaining -= 1
		burst_clock += 0.09
	var remaining: Array[Dictionary] = []
	for e in enemies:
		if e.hp <= 0.0:
			kills += 1
			effects.append({"lane":e.lane,"x":e.x,"life":0.5,"max":0.5,"kind":"kill","target_id":e.id})
			continue
		if e.x >= 1030.0:
			health -= 2 if e.heavy else 1
			effects.append({"lane":e.lane,"x":1030.0,"life":0.7,"max":0.7,"kind":"leak"})
		else: remaining.append(e)
	enemies = remaining
	if health <= 0:
		health = 0
		beams.clear()
		mode = "lost"
		message = "Núcleo perdido. Reinicie e experimente outra transferência."
	elif spawned == total_enemies() and enemies.is_empty():
		beams.clear()
		wave += 1
		credits += 3
		mode = "won" if wave == 3 else "ready"
		message = "O coração desperta. A Estação Raiz voltou a respirar!" if mode == "won" else ("Irrigação reativada: +3 brotos. Escolha sua melhoria." if wave==1 else "Os leitos brotaram: +3 brotos. Prepare o despertar do coração.")

func _shoot(lane: int,energy_share: float=1.0) -> void:
	var targets: Array[Dictionary] = []
	for e in enemies:
		if e.lane == lane and e.x >= 420.0 and e.x <= 1000.0 and e.hp > 0: targets.append(e)
	targets.sort_custom(func(a,b): return a.x > b.x)
	var boosted := lane == selected and transfer <= 0.0
	var hits := upgrade_level + 1 if upgrade == 2 and boosted else 1
	for i in range(mini(hits, targets.size())):
		var e := targets[i]
		var damage := 5.0 if boosted else 1.0
		if boosted and upgrade == 2: damage = 3.2 if upgrade_level == 2 else 3.6
		if transfer > 0 and upgrade != 1: damage = 0.4
		if e.heavy: damage *= 0.8 if boosted else 0.5
		damage *= energy_share
		e.hp -= damage
		e.flash = 0.12
		beams.append({"lane":lane,"x":e.x,"life":0.20,"boost":boosted,"target_id":e.id})
		effects.append({"lane":lane,"x":e.x,"life":0.25,"max":0.25,"kind":"hit","target_id":e.id})

func checkpoint() -> Dictionary:
	return {"version":1,"wave":wave,"credits":credits,"upgrade":upgrade,"upgrade_level":upgrade_level,"selected":selected,"health":health}

func restore(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["version","wave","credits","upgrade","selected","health"]:
		if not data.has(key) or not (data[key] is int or data[key] is float): return false
		if not is_finite(float(data[key])) or float(data[key]) != floor(float(data[key])): return false
	if data.version != 1 or data.wave < 0 or data.wave > 3 or data.upgrade < 0 or data.upgrade > 2 or int(data.selected) not in [0,1] or data.health < 1 or data.health > 10: return false
	if data.credits < 0 or data.credits > data.wave * 3: return false
	if data.upgrade != 0 and (data.wave == 0 or data.credits > data.wave * 3 - 3): return false
	var level_value = data.get("upgrade_level",1 if data.upgrade != 0 else 0)
	if not (level_value is int or level_value is float): return false
	if not is_finite(float(level_value)) or float(level_value) != floor(float(level_value)): return false
	var level := int(level_value)
	if level < 0 or level > 2 or (data.upgrade == 0 and level != 0) or (data.upgrade != 0 and level == 0): return false
	if data.credits > data.wave * 3 - level * 3: return false
	wave = int(data.wave)
	credits = int(data.credits)
	upgrade = int(data.upgrade)
	upgrade_level = level
	selected = int(data.selected)
	health = int(data.health)
	mode = "won" if wave == 3 else "ready"
	enemies.clear()
	beams.clear()
	effects.clear()
	transfer = 0.0
	burst_clock = 0.0
	burst_remaining = 0
	message = "Checkpoint carregado: pronto para continuar."
	return true
