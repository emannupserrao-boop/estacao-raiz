extends Control
const Rules = preload("res://defense.gd")
var game = Rules.new()
var paused := false
var confirm_reset := false
var save_path := "res://local/save.json"
var buttons: Dictionary = {}
var status: Label
var caption: Label
var failure := ""
var reset_timer := 0.0
var show_help := false
var help_was_paused := false
var world
var hud
var sound

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://local"))
	if "--qa" not in OS.get_cmdline_user_args(): _load_checkpoint()
	sound = preload("res://audio/director.gd").new()
	add_child(sound)
	world = preload("res://visual/world.tscn").instantiate()
	add_child(world)
	var layer := CanvasLayer.new()
	layer.name = "InterfaceLayer"
	add_child(layer)
	hud = preload("res://visual/hud.tscn").instantiate()
	layer.add_child(hud)
	buttons = hud.buttons
	status = hud.status
	caption = hud.caption
	hud.intent.connect(_on_intent)
	hud.volume_changed.connect(func(value: float): sound.set_volume(value))
	_refresh()

func _on_intent(action: String,value: int) -> void:
	if action != "mute": sound.cue("ui",0.04)
	match action:
		"mute": sound.toggle_mute()
		"route": _switch(value)
		"buy": _buy(value)
		"start": _start_or_retry()
		"pause": _toggle_pause()
		"reset": _reset()
		"help": _toggle_help()
	_refresh()

func _toggle_help() -> void:
	show_help = not show_help
	if show_help:
		help_was_paused = paused
		if game.mode == "wave": paused = true
	else: paused = help_was_paused

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode not in [KEY_1,KEY_2,KEY_SPACE,KEY_ESCAPE]: return
	sound.cue("ui",0.04)
	match event.keycode:
		KEY_1: _switch(0)
		KEY_2: _switch(1)
		KEY_SPACE:
			if show_help: _toggle_help()
			elif game.mode == "wave": _toggle_pause()
			else: _start_or_retry()
		KEY_ESCAPE:
			if confirm_reset: confirm_reset = false
			elif show_help: _toggle_help()
			else: _toggle_pause()
	get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(110,178,900,350).has_point(event.position):
			sound.cue("ui",0.04)
			_switch(0 if event.position.y < 350 else 1)
			accept_event()

func _process(dt: float) -> void:
	reset_timer = maxf(0.0,reset_timer-dt)
	if reset_timer == 0.0: confirm_reset = false
	var before: String = game.mode
	if not paused: game.tick(minf(dt,0.05))
	sound.observe(game,paused,dt)
	if before == "wave" and game.mode in ["ready","won"]:
		_save_checkpoint()
	_refresh()
	world.present(game,0.0 if paused else dt,paused)

func _start_or_retry() -> void:
	confirm_reset = false
	show_help = false
	if game.mode == "lost":
		game = Rules.new()
		_load_checkpoint()
		paused = false
		return
	if game.mode == "won": return
	if game.mode == "ready":
		_save_checkpoint()
		game.start()
		paused = false

func _toggle_pause() -> void:
	confirm_reset = false
	if show_help:
		_toggle_help()
		return
	if game.mode == "wave": paused = not paused

func _switch(lane: int) -> void:
	confirm_reset = false
	if paused or show_help: return
	if game.switch_to(lane) and game.mode == "ready": _save_checkpoint()

func _buy(choice: int) -> void:
	confirm_reset = false
	if game.buy(choice): _save_checkpoint()

func _reset() -> void:
	if not confirm_reset:
		confirm_reset = true
		reset_timer = 5.0
		return
	game = Rules.new()
	paused = false
	confirm_reset = false
	show_help = false
	_save_checkpoint()

func _save_checkpoint() -> void:
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		failure = "Checkpoint não salvo. Pasta local indisponível."
		return
	file.store_string(JSON.stringify(game.checkpoint()))
	file.close()
	var err := DirAccess.rename_absolute(save_path+".tmp",save_path)
	failure = "Falha ao substituir o save." if err != OK else ""

func _load_checkpoint() -> void:
	if not FileAccess.file_exists(save_path): return
	var parser := JSON.new()
	var err := parser.parse(FileAccess.get_file_as_string(save_path))
	if err != OK or not game.restore(parser.data): failure = "Save inválido: início seguro. Arquivo preservado até próximo checkpoint."


func _refresh() -> void:
	if hud == null: return
	hud.present(game,paused,show_help,confirm_reset,failure if failure != "" else game.message)
	hud.present_audio(sound.volume,sound.muted,sound.settings_error)
	world.present(game,0.0,paused)
