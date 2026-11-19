extends Area2D
## Peluru lurus, bisa menembus (pierce) beberapa zombie.

const SPEED := 675.0
const MAX_RANGE := 240.0

var direction := Vector2.RIGHT
var pierce := 0
var damage := 1
var traveled := 0.0
var _hit_ids := {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	rotation = direction.angle() + PI * 0.5


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	position += direction * step
	traveled += step
	if traveled >= MAX_RANGE:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("zombies"):
		return
	var id := area.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	area.hit(damage)
	if pierce > 0:
		pierce -= 1
	else:
		call_deferred("queue_free")
