extends Area2D
## Pemain: drag 1:1, auto-fire ke zombie terdekat, 3 HP, upgrade per tier.

signal died
signal hp_changed

const MAX_HP := 3
const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var BOUNDS := Rect2(40.0, 150.0, 640.0, 1080.0)
var _reset_pos := Vector2(360.0, 870.0)
var game: Node = null
var hp := MAX_HP
var alive := true
var invuln := 0.0
var fire_cd := 0.0
var knock := Vector2.ZERO
var dragging := false
var aim := Vector2.RIGHT
var fire_interval := 0.35
var range_px := 260.0
var shots := 1
var pierce := 0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_sprite.scale = Vector2(2.6, 2.6)


func set_arena(a: Rect2) -> void:
	BOUNDS = Rect2(a.position, a.size).grow(-40.0)
	_reset_pos = Vector2(a.size.x * 0.5, a.size.y * 0.7)


func apply_tier(new_tier: int) -> void:
	match new_tier:
		1:
			fire_interval = 0.28
		2:
			shots = 2
		3:
			pierce = 1
		4:
			fire_interval = 0.24
		5:
			shots = 3


func reset() -> void:
	hp = MAX_HP
	alive = true
	invuln = 0.0
	fire_cd = 0.0
	knock = Vector2.ZERO
	dragging = false
	visible = true
	fire_interval = 0.35
	shots = 1
	pierce = 0
	position = _reset_pos
	hp_changed.emit(hp)


func heal(n: int) -> void:
	hp = mini(MAX_HP, hp + n)
	hp_changed.emit(hp)


func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag:
		if dragging:
			_move(event.relative)


func _move(d: Vector2) -> void:
	position += d
	position.x = clampf(position.x, BOUNDS.position.x, BOUNDS.end.x)
	position.y = clampf(position.y, BOUNDS.position.y, BOUNDS.end.y)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	if invuln > 0.0:
		invuln -= delta
		visible = fmod(invuln, 0.16) > 0.08
		if invuln <= 0.0:
			visible = true

	if knock.length_squared() > 1.0:
		position += knock * delta
		knock = knock.move_toward(Vector2.ZERO, 2200.0 * delta)
		_move(Vector2.ZERO)

	if game != null and game.running:
		fire_cd -= delta
		if fire_cd <= 0.0:
			fire_cd = fire_interval
			_fire()

	_sprite.rotation = lerp_angle(_sprite.rotation, aim.angle(), 12.0 * delta)


func _fire() -> void:
	var target := _nearest()
	if target == null:
		return
	var dir: Vector2 = (target.position - position).normalized()
	aim = dir
	var base := dir.angle()
	for i in shots:
		var off := 0.0
		if shots > 1:
			off = (float(i) - float(shots - 1) * 0.5) * 0.16
		var d := Vector2.from_angle(base + off)
		var b := BULLET_SCENE.instantiate()
		b.position = position + d * 22.0
		b.direction = d
		b.pierce = pierce
		game.bullets_root.add_child(b)
	game._sfx("shoot", -12.0)


func _nearest() -> Node2D:
	var best: Node2D = null
	var best_d := range_px * range_px
	for z in get_tree().get_nodes_in_group("zombies"):
		var zp: Vector2 = (z as Node2D).position
		var d := position.distance_squared_to(zp)
		if d < best_d:
			best_d = d
			best = z
	return best


func _on_area_entered(area: Area2D) -> void:
	if not alive:
		return
	if area.is_in_group("pickups"):
		area.collect()
		return
	if invuln > 0.0:
		return
	if area.is_in_group("zombies"):
		_take_hit(area)


func _take_hit(area: Node2D) -> void:
	hp -= 1
	invuln = 1.0
	var d := position - area.position
	if d.length() > 0.01:
		knock = d.normalized() * 260.0
	hp_changed.emit(hp)
	if game != null:
		game._sfx("hurt", -4.0)
	if hp <= 0:
		hp = 0
		alive = false
		visible = false
		died.emit()
