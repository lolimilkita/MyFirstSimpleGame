extends Node2D
## I2 — BERTAHAN. Director: spawn, tipe zombie, horde, upgrade, pickup, best score.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const GROUND := preload("res://assets/sprites/ground.png")

const SFX := {
	"shoot": preload("res://assets/sfx/shoot.wav"),
	"hit": preload("res://assets/sfx/hit.wav"),
	"dead": preload("res://assets/sfx/dead.wav"),
	"hurt": preload("res://assets/sfx/hurt.wav"),
	"pickup": preload("res://assets/sfx/pickup.wav"),
	"upgrade": preload("res://assets/sfx/upgrade.wav"),
}

const Z_TYPES := {
	"walker": {"hp": 1, "speed": 45.0, "score": 10, "scale": 2.0, "radius": 22.0},
	"runner": {"hp": 1, "speed": 73.0, "score": 15, "scale": 1.75, "radius": 19.0},
	"brute": {"hp": 6, "speed": 31.0, "score": 40, "scale": 1.5, "radius": 33.0},
}

const UPGRADE_POOL := [
	{"id": "fire_rate", "title": "TEMBAK CEPAT", "desc": "-18% jeda tembak", "max": 5, "weight": 3, "color": Color("ffb74d")},
	{"id": "multishot", "title": "PELURU GANDA", "desc": "+1 peluru setiap tembakan", "max": 2, "weight": 2, "color": Color("4fc3f7")},
	{"id": "pierce", "title": "PELURU TEMBUS", "desc": "Peluru menembus +1 zombie", "max": 3, "weight": 2, "color": Color("ba68c8")},
	{"id": "speed", "title": "KAKI RINGAN", "desc": "+12% kecepatan gerak", "max": 3, "weight": 3, "color": Color("81c784")},
	{"id": "max_hp", "title": "DARAH TEBAL", "desc": "+1 nyawa maksimal & pulihkan 1", "max": 2, "weight": 2, "color": Color("e57373")},
	{"id": "magnet", "title": "MAGNET", "desc": "Tarik koin +60% lebih jauh", "max": 2, "weight": 2, "color": Color("ffd54f")},
	{"id": "damage", "title": "PELURU BESAR", "desc": "+1 damage per peluru", "max": 3, "weight": 2, "color": Color("ff8a65")},
	{"id": "range", "title": "BIDIK JAUH", "desc": "+18% jangkauan tembak", "max": 3, "weight": 1, "color": Color("90caf9")},
]

const MAX_ZOMBIES := 30
const MAX_PICKUPS := 14
const HORDE_EVERY := 75.0
const SAVE_PATH := "user://save.cfg"

var START_INTERVAL := 0.45
var MIN_INTERVAL := 0.10
var INTERVAL_DECAY := 0.90
const SPEED_GROWTH := 1.03
const SPEED_CAP := 1.9

var arena := Rect2(0.0, 0.0, 720.0, 1280.0)
var zombies_root: Node2D
var bullets_root: Node2D
var pickups_root: Node2D
var hud: Control
var player: Node2D

var running := true
var elapsed := 0.0
var spawn_timer := 0.0
var horde_timer := HORDE_EVERY
var kills := 0
var kill_points := 0
var bonus_points := 0
var score := 0
var best := 0
var _stacks := {}
var choosing := false
var options: Array = []
var level := 1
var next_level := 8
var _horde_busy := false
var _dbg := false
var _maxt := 0.0
var _sfx_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	var vp := get_viewport_rect().size
	if vp.x > 1.0 and vp.y > 1.0:
		arena = Rect2(Vector2.ZERO, vp)
	if OS.is_debug_build():
		_dbg = OS.get_environment("BT_DEBUG") == "1"
		if OS.get_environment("BT_SPEED") != "":
			Engine.time_scale = float(OS.get_environment("BT_SPEED"))
		if OS.get_environment("BT_MAXT") != "":
			_maxt = float(OS.get_environment("BT_MAXT"))
		if OS.get_environment("BT_START") != "":
			START_INTERVAL = float(OS.get_environment("BT_START"))
		if OS.get_environment("BT_DECAY") != "":
			INTERVAL_DECAY = float(OS.get_environment("BT_DECAY"))
	pickups_root = $Pickups
	zombies_root = $Zombies
	bullets_root = $Bullets
	hud = $HUD/Overlay
	best = _load_best()
	_spawn_player()
	hud.setup(self)
	hud.set_best(best)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.game = self
	player.set_arena(arena)
	player.position = Vector2(arena.size.x * 0.5, arena.size.y * 0.7)
	player.died.connect(_on_player_died)
	add_child(player)


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	score = kill_points + bonus_points + int(elapsed)
	if _maxt > 0.0 and elapsed >= _maxt:
		print("[dbg] STOP t=%.1f score=%d kills=%d best=%d" % [elapsed, score, kills, best])
		get_tree().quit()

	spawn_timer -= delta
	if spawn_timer <= 0.0 and zombies_root.get_child_count() < MAX_ZOMBIES:
		spawn_timer = current_interval()
		_spawn_zombie()

	horde_timer -= delta
	if horde_timer <= 0.0:
		horde_timer = HORDE_EVERY
		_horde()

	if _dbg and Engine.get_process_frames() % 90 == 0:
		var hp := -1
		if player != null:
			hp = player.hp
		print("[dbg] t=%.1f score=%d kills=%d z=%d p=%d hp=%d lv=%d run=%s" % [
			elapsed, score, kills, zombies_root.get_child_count(),
			pickups_root.get_child_count(), hp, level, running])


func current_interval() -> float:
	var stage := elapsed / 10.0
	return maxf(MIN_INTERVAL, START_INTERVAL * pow(INTERVAL_DECAY, stage))


func hp_mult() -> float:
	return 1.0 + maxf(0.0, elapsed - 45.0) / 90.0


func current_speed_mult() -> float:
	var stage := elapsed / 10.0
	return minf(SPEED_CAP, pow(SPEED_GROWTH, stage))


func _pick_type() -> String:
	if elapsed < 45.0:
		return "walker"
	if elapsed < 90.0:
		return "runner" if randf() < 0.28 else "walker"
	var r := randf()
	if r < 0.18:
		return "brute"
	if r < 0.50:
		return "runner"
	return "walker"


func _spawn_zombie() -> void:
	_spawn_zombie_at(randi() % 4, _pick_type())


func _spawn_zombie_at(side: int, type_name: String) -> void:
	if zombies_root.get_child_count() >= MAX_ZOMBIES:
		return
	var margin := 34.0
	var p := Vector2.ZERO
	match side:
		0:
			p = Vector2(randf_range(0.0, arena.size.x), -margin)
		1:
			p = Vector2(arena.size.x + margin, randf_range(0.0, arena.size.y))
		2:
			p = Vector2(randf_range(0.0, arena.size.x), arena.size.y + margin)
		_:
			p = Vector2(-margin, randf_range(0.0, arena.size.y))
	var z := ZOMBIE_SCENE.instantiate()
	z.position = p
	z.setup(type_name, Z_TYPES[type_name], current_speed_mult(), hp_mult(), self)
	z.set_target(player)
	zombies_root.add_child(z)


func _horde() -> void:
	if _horde_busy or not running:
		return
	_horde_busy = true
	var side := randi() % 4
	hud.telegraph(side)
	await get_tree().create_timer(1.5).timeout
	if not running:
		_horde_busy = false
		return
	for i in 10:
		if not running:
			break
		_spawn_zombie_at(side, "runner" if i % 3 == 0 else "walker")
		await get_tree().create_timer(0.05).timeout
	_horde_busy = false


func _maybe_drop(pos: Vector2) -> void:
	if pickups_root.get_child_count() >= MAX_PICKUPS:
		return
	var r := randf()
	if r < 0.03 and player != null and player.hp < 3:
		call_deferred("_spawn_pickup", pos, "health")
	elif r < 0.32:
		call_deferred("_spawn_pickup", pos, "coin")


func _spawn_pickup(pos: Vector2, kind: String) -> void:
	if not running:
		return
	var p := PICKUP_SCENE.instantiate()
	p.position = pos
	p.kind = kind
	p.game = self
	pickups_root.add_child(p)


func on_zombie_killed(pos: Vector2, value: int) -> void:
	kills += 1
	kill_points += value
	_sfx("dead", -8.0)
	_maybe_drop(pos)
	if kills >= next_level and not choosing:
		_level_up()


func _level_up() -> void:
	options = _roll_upgrades(3)
	if options.is_empty():
		return
	choosing = true
	hud.show_upgrades(options)
	get_tree().paused = true
	if OS.is_debug_build() and OS.get_environment("BT_AUTOPICK") == "1":
		await get_tree().create_timer(0.2, true).timeout
		if choosing:
			choose_upgrade(randi() % options.size())


func _roll_upgrades(n: int) -> Array:
	var pool: Array = []
	for u in UPGRADE_POOL:
		if int(_stacks.get(u["id"], 0)) < int(u["max"]):
			pool.append(u)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var total := 0
		for u in pool:
			total += int(u["weight"])
		var r := randi() % total
		var acc := 0
		var pick := 0
		for i in pool.size():
			acc += int(pool[i]["weight"])
			if r < acc:
				pick = i
				break
		out.append(pool[pick])
		pool.remove_at(pick)
	return out


func choose_upgrade(index: int) -> void:
	if not choosing or index < 0 or index >= options.size():
		return
	var u: Dictionary = options[index]
	var id := String(u["id"])
	_stacks[id] = int(_stacks.get(id, 0)) + 1
	player.apply_upgrade(id, int(_stacks[id]))
	_sfx("upgrade", -3.0)
	hud.toast("+" + String(u["title"]))
	level += 1
	next_level = kills + 6 + level * 2
	if _dbg:
		print("[dbg] PICK %s (lv %d) fire=%.2f shots=%d pierce=%d dmg=%d spd=%.2f hp=%d/%d" % [
			id, level, player.fire_interval, player.shots, player.pierce,
			player.damage, player.move_mult, player.hp, player.max_hp])
	choosing = false
	options = []
	hud.hide_upgrades()
	get_tree().paused = false


func add_bonus(points: int) -> void:
	bonus_points += points


func _on_player_died() -> void:
	running = false
	choosing = false
	options = []
	hud.hide_upgrades()
	get_tree().paused = false
	if score > best:
		best = score
		_save_best(best)
	hud.set_best(best)
	hud.show_game_over()
	if OS.is_debug_build() and OS.get_environment("BT_AUTORESTART") == "1":
		await get_tree().create_timer(1.0).timeout
		restart()
		if _dbg:
			print("[dbg] RESTART ok")


func restart() -> void:
	for n in [zombies_root, bullets_root, pickups_root]:
		for c in n.get_children():
			c.queue_free()
	elapsed = 0.0
	spawn_timer = 0.0
	horde_timer = HORDE_EVERY
	kills = 0
	kill_points = 0
	bonus_points = 0
	score = 0
	_stacks.clear()
	level = 1
	next_level = 8
	choosing = false
	options = []
	get_tree().paused = false
	hud.hide_upgrades()
	_horde_busy = false
	running = true
	player.reset()
	hud.hide_game_over()


func _sfx(name: String, db := 0.0) -> void:
	var p: AudioStreamPlayer = null
	for q in _sfx_pool:
		if not q.playing:
			p = q
			break
	if p == null and _sfx_pool.size() < 8:
		p = AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	if p == null:
		p = _sfx_pool[0]
	p.stream = SFX[name]
	p.volume_db = db
	p.play()


func _load_best() -> int:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		return int(cf.get_value("score", "best", 0))
	return 0


func _save_best(v: int) -> void:
	var cf := ConfigFile.new()
	cf.set_value("score", "best", v)
	cf.save(SAVE_PATH)


func _draw() -> void:
	draw_texture_rect(GROUND, Rect2(Vector2.ZERO, arena.size), true)
	draw_rect(arena, Color("37474f"), false, 3.0)
