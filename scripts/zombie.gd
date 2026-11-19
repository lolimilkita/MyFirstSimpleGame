extends Area2D
## Zombie dengan 3 tipe: walker, runner, brute.

const TEX := {
	"walker": preload("res://assets/sprites/zombie_walker.png"),
	"runner": preload("res://assets/sprites/zombie_runner.png"),
	"brute": preload("res://assets/sprites/zombie_brute.png"),
}
const SEPARATION_RADIUS := 30.0

var ztype := "walker"
var hp := 1
var speed := 80.0
var score_value := 10
var target: Node2D = null
var game: Node = null
var alive := true
var flash := 0.0
var wobble := 0.0


func _ready() -> void:
	add_to_group("zombies")
	wobble = randf() * TAU


func setup(type_name: String, cfg: Dictionary, speed_mult: float, hp_scale: float, g: Node) -> void:
	ztype = type_name
	hp = int(ceil(float(cfg["hp"]) * hp_scale))
	speed = float(cfg["speed"]) * speed_mult
	score_value = int(cfg["score"])
	game = g
	var sprite: Sprite2D = $Sprite2D
	sprite.texture = TEX[type_name]
	var s := float(cfg["scale"])
	sprite.scale = Vector2(s, s)
	var shape := CircleShape2D.new()
	shape.radius = float(cfg["radius"])
	$CollisionShape2D.shape = shape


func _physics_process(delta: float) -> void:
	if not alive:
		return

	wobble += delta * 7.0
	$Sprite2D.rotation = sin(wobble) * 0.14
	if flash > 0.0:
		flash -= delta
		$Sprite2D.modulate = Color.WHITE if flash > 0.0 else Color(1, 1, 1)

	if target == null or not is_instance_valid(target):
		return

	var to := target.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.ZERO

	var sep := Vector2.ZERO
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self:
			continue
		var zp: Vector2 = (z as Node2D).position
		var d := position - zp
		var l := d.length()
		if l > 0.01 and l < SEPARATION_RADIUS:
			sep += d / l * (SEPARATION_RADIUS - l)

	position += (dir * speed + sep * 6.0) * delta


func set_target(t: Node2D) -> void:
	target = t


func hit(dmg: int) -> void:
	if not alive:
		return
	hp -= dmg
	flash = 0.09
	$Sprite2D.modulate = Color.WHITE
	if game != null:
		game._sfx("hit", -18.0)
	if hp <= 0:
		_die()


func _die() -> void:
	alive = false
	remove_from_group("zombies")
	if game != null:
		game.on_zombie_killed(position, score_value)
	call_deferred("queue_free")
