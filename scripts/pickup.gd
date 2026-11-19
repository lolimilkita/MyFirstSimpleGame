extends Area2D
## Pickup: koin (bonus skor) dan medkit (pulihkan 1 HP). Menempel ke pemain bila dekat.

const MEDKIT := preload("res://assets/sprites/medkit.png")
const LIFE := 14.0
const MAGNET := 120.0

var kind := "coin"
var game: Node = null
var _t := 0.0
var _life := LIFE


func _ready() -> void:
	add_to_group("pickups")
	_t = randf() * TAU
	if kind == "health":
		$Sprite2D.texture = MEDKIT
		var shape := CircleShape2D.new()
		shape.radius = 20.0
		$CollisionShape2D.shape = shape


func _physics_process(delta: float) -> void:
	_t += delta
	_life -= delta
	$Sprite2D.position.y = sin(_t * 3.2) * 3.0
	if _life <= 0.0:
		_despawn()
		return
	if game == null or game.player == null or not is_instance_valid(game.player):
		return
	var d: Vector2 = game.player.position - position
	var reach: float = game.player.magnet
	if d.length() < reach and d.length() > 1.0:
		position += d.normalized() * (240.0 * delta)


func collect() -> void:
	if game == null:
		_despawn()
		return
	if kind == "coin":
		game.add_bonus(25)
		game._sfx("pickup", -8.0)
	else:
		game.player.heal(1)
		game._sfx("pickup", -2.0)
	_despawn()


func _despawn() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	visible = false
	await get_tree().process_frame
	queue_free()
