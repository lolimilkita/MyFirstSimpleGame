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
	"walker": {"hp": 1, "speed": 80.0, "score": 10, "scale": 2.6, "radius": 17.0},
	"runner": {"hp": 1, "speed": 132.0, "score": 15, "scale": 2.3, "radius": 14.0},
	"brute": {"hp": 6, "speed": 56.0, "score": 40, "scale": 2.0, "radius": 22.0},
}

const UPGRADES := [
	{"kills": 15, "label": "TEMBAK LEBIH CEPAT"},
	{"kills": 40, "label": "TEMBAKAN GANDA"},
	{"kills": 80, "label": "PELURU TEMBUS"},
	{"kills": 140, "label": "TEMBAK LEBIH CEPAT"},
	{"kills": 220, "label": "TEMBAKAN TRIPEL"},
]

const MAX_ZOMBIES := 55
const MAX_PICKUPS := 14
const HORDE_EVERY := 75.0
const SAVE_PATH := "user://save.cfg"

var START_INTERVAL := 0.35
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
var tier := 0
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
		print("[dbg] t=%.1f score=%d kills=%d z=%d p=%d hp=%d tier=%d run=%s" % [
			elapsed, score, kills, zombies_root.get_child_count(),
			pickups_root.get_child_count(), hp, tier, running])


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
	var margin := 60.0
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
	_check_tiers()
	_maybe_drop(pos)


func _check_tiers() -> void:
	while tier < UPGRADES.size() and kills >= int(UPGRADES[tier]["kills"]):
		tier += 1
		if player != null:
			player.apply_tier(tier)
		hud.toast(str(UPGRADES[tier - 1]["label"]))
		_sfx("upgrade", -3.0)


func add_bonus(points: int) -> void:
	bonus_points += points


func _on_player_died() -> void:
	running = false
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
	tier = 0
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
