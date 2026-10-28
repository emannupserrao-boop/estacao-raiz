extends Node
# Presentation observer only. Never writes to Rules or its checkpoint.
var settings_path := "res://local/audio-settings.json"
var volume := 0.65
var muted := false
var settings_error := ""
var events := {}
var voices: Array[AudioStreamPlayer] = []
var streams := {}
var cooldown := {}
var seen := {}
var clock := 0.0
var last_mode := ""
var last_selected := -1
var last_game := 0
var was_paused := false
var bus := -1
var serial := 0
var shot_sets := [[],[]]
var shot_serials := [0,0]
var shot_history: Array[Dictionary] = []

func _ready() -> void:
	bus = AudioServer.get_bus_index("GameSFX")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,"GameSFX")
	# Peaks <= .25 and <= 6 voices: no gain boost. Hard limiter is a safety net.
	AudioServer.add_bus_effect(bus,AudioEffectHardLimiter.new())
	for name in ["shot","impact","transfer","ui","victory","defeat"]:
		streams[name] = load("res://audio/%s.wav" % name)
	for lane in range(2):
		for variant in range(3):
			shot_sets[lane].append(load("res://audio/blaster_%s_%d.wav" % ["a" if lane==0 else "b",variant]))
	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.bus = "GameSFX"
		add_child(player)
		voices.append(player)
	if "--qa" not in OS.get_cmdline_user_args(): load_settings()
	apply_settings()

func apply_settings() -> void:
	if bus < 0: return
	AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(volume,0.0001)))
	AudioServer.set_bus_mute(bus,muted or volume <= 0.0)
	if muted or volume <= 0.0: stop_all()

func set_volume(value: float) -> void:
	volume = clampf(value,0.0,1.0) if is_finite(value) else 0.65
	apply_settings()
	save_settings()

func toggle_mute() -> void:
	muted = not muted
	apply_settings()
	save_settings()

func save_settings() -> void:
	var file := FileAccess.open(settings_path+".tmp",FileAccess.WRITE)
	if file == null:
		settings_error = "Preferências de som não salvas."
		return
	file.store_string(JSON.stringify({"version":1,"volume":volume,"muted":muted}))
	file.close()
	var err := DirAccess.rename_absolute(settings_path+".tmp",settings_path)
	settings_error = "" if err == OK else "Preferências de som não salvas."

func load_settings() -> void:
	if not FileAccess.file_exists(settings_path): return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(settings_path)) != OK: return
	var data = parser.data
	if not data is Dictionary: return
	var value = data.get("volume",0.65)
	if (value is float or value is int) and is_finite(float(value)): volume = clampf(float(value),0.0,1.0)
	if data.get("muted") is bool: muted = data.muted
	apply_settings()

func stop_all() -> void:
	for voice in voices: voice.stop()

func cue(name: String,spacing: float = 0.0,lane: int = -1) -> void:
	var key := name+str(clampi(lane,0,1)) if name=="shot" else name
	if muted or volume <= 0 or clock < float(cooldown.get(key,-1.0)): return
	cooldown[key] = clock+spacing
	events[name] = int(events.get(name,0))+1
	var stream = streams[name]
	var pitch := 1.0
	if name == "shot":
		var route := clampi(lane,0,1)
		var index: int = int(shot_serials[route])%3
		stream = shot_sets[route][index]
		pitch = [0.985,1.0,1.015][int(shot_serials[route]/3)%3]
		shot_serials[route] += 1
		shot_history.append({"lane":route,"variant":index,"pitch":pitch,"path":stream.resource_path})
		if shot_history.size()>24: shot_history.pop_front()
	# Test runs observe events without making sound, except explicit movie capture.
	if "--qa" in OS.get_cmdline_user_args() and "--capture-audio" not in OS.get_cmdline_user_args(): return
	var voice: AudioStreamPlayer = voices[serial%voices.size()]
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	voice.stop()
	voice.stream = stream
	voice.pitch_scale = pitch
	# Keep impacts behind the blaster transient during simultaneous bursts.
	voice.volume_db = -5.0 if name=="impact" else 0.0
	voice.mix_target = AudioStreamPlayer.MIX_TARGET_STEREO
	voice.play()
	serial += 1

func observe(game,paused: bool,dt: float) -> void:
	clock += maxf(dt,0.0)
	var identity: int = game.get_instance_id()
	if last_game != 0 and identity != last_game: stop_all()
	if identity != last_game or (game.mode == "wave" and last_mode != "wave"):
		seen.clear()
		cooldown.clear()
	if paused or was_paused:
		if paused and not was_paused: stop_all()
		_prime(game)
		was_paused = paused
		return
	if game.mode in ["won","lost"] and game.mode != last_mode:
		stop_all()
		cue("victory" if game.mode == "won" else "defeat")
	if game.mode == "wave":
		if last_selected >= 0 and last_selected != game.selected and game.transfer > 0: cue("transfer",0.15)
		for beam in game.beams:
			var key := "b:%d:%.3f:%.3f" % [beam.lane,beam.x,game.elapsed+beam.life]
			if beam.life >= 0.199 and not seen.has(key):
				seen[key] = clock
				cue("shot",0.075,int(beam.lane))
		for fx in game.effects:
			var key := "f:%s:%d:%.3f:%.3f" % [fx.kind,fx.lane,fx.x,game.elapsed+fx.life]
			if fx.life >= fx.max-0.001 and not seen.has(key):
				seen[key] = clock
				cue("impact",0.06)
	for key in seen.keys():
		if clock-float(seen[key]) > 3.0: seen.erase(key)
	_prime(game)

func _prime(game) -> void:
	last_game = game.get_instance_id()
	last_mode = game.mode
	last_selected = game.selected
