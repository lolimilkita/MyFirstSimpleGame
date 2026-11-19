extends Control
## HUD: skor/rekor/kill/hati, toast, panah horde, kartu upgrade, layar game over.

var game: Node = null
var game_over := false
var best := 0
var _toast_text := ""
var _toast_t := 0.0
var _arrow_side := -1
var _arrow_t := 0.0
var _cards: Array = []


func setup(g: Node) -> void:
	game = g


func set_best(v: int) -> void:
	best = v


func toast(text: String) -> void:
	_toast_text = text
	_toast_t = 1.9


func telegraph(side: int) -> void:
	_arrow_side = side
	_arrow_t = 1.5


func show_upgrades(opts: Array) -> void:
	_cards = opts.duplicate()
	queue_redraw()


func hide_upgrades() -> void:
	_cards = []


func show_game_over() -> void:
	game_over = true


func hide_game_over() -> void:
	game_over = false


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
	if _arrow_t > 0.0:
		_arrow_t -= delta
	queue_redraw()


func _card_rect(i: int) -> Rect2:
	var h := 150.0
	var gap := 26.0
	var n := _cards.size()
	var total := float(n) * h + float(n - 1) * gap
	var top := size.y * 0.5 - total * 0.5 + 30.0
	return Rect2(42.0, top + float(i) * (h + gap), size.x - 84.0, h)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if not _cards.is_empty():
			var pos: Vector2 = (event as InputEventScreenTouch).position
			for i in _cards.size():
				if _card_rect(i).has_point(pos):
					game.choose_upgrade(i)
					get_viewport().set_input_as_handled()
					return
			return
		if game_over and game != null:
			game.restart()


func _draw() -> void:
	if game == null:
		return
	var font := ThemeDB.fallback_font
	var white := Color("eceff1")
	var grey := Color("90a4ae")

	draw_string(font, Vector2(30.0, 74.0), "SKOR %d" % game.score, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, white)
	draw_string(font, Vector2(30.0, 106.0), "REKOR %d" % best, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, grey)
	draw_string(font, Vector2(196.0, 106.0), "LV %d" % game.level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("ffd54f"))
	draw_string(font, Vector2(30.0, 138.0), "KILL %d" % game.kills, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, grey)

	var hp := 3
	var max_hp := 3
	if game.player != null:
		hp = game.player.hp
		max_hp = game.player.max_hp
	for i in max_hp:
		var c := Color("ef5350") if i < hp else Color("37474f")
		draw_rect(Rect2(30.0 + float(i) * 42.0, 154.0, 30.0, 30.0), c, true)

	if _arrow_t > 0.0 and _arrow_side >= 0:
		_draw_arrow()

	if _toast_t > 0.0 and _toast_text != "":
		var a := clampf(_toast_t / 0.6, 0.0, 1.0)
		draw_string(font, Vector2(0.0, size.y * 0.26), _toast_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color(1.0, 0.85, 0.3, a))

	if not _cards.is_empty():
		_draw_cards(font)
		return

	if game_over:
		draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.0, 0.0, 0.0, 0.6), true)
		draw_string(font, Vector2(0.0, size.y * 0.40), "GAME OVER",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 62, Color("ef5350"))
		draw_string(font, Vector2(0.0, size.y * 0.48), "Skor: %d" % game.score,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 44, white)
		if game.score >= best and game.score > 0:
			draw_string(font, Vector2(0.0, size.y * 0.535), "REKOR BARU!",
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color("ffd54f"))
		else:
			draw_string(font, Vector2(0.0, size.y * 0.535), "Rekor: %d" % best,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, grey)
		draw_string(font, Vector2(0.0, size.y * 0.62), "Ketuk untuk coba lagi",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, grey)


func _draw_cards(font: Font) -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.0, 0.0, 0.0, 0.72), true)
	var n := _cards.size()
	var total := float(n) * 150.0 + float(n - 1) * 26.0
	var top := size.y * 0.5 - total * 0.5 + 30.0
	draw_string(font, Vector2(0.0, top - 26.0), "NAIK LEVEL %d — PILIH 1" % game.level,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color("ffd54f"))

	for i in _cards.size():
		var u: Dictionary = _cards[i]
		var r := _card_rect(i)
		var accent: Color = u.get("color", Color("ffd54f"))
		draw_rect(r, Color(0.10, 0.13, 0.16, 0.98), true)
		draw_rect(r, accent, false, 3.0)
		draw_rect(Rect2(r.position.x, r.position.y, 10.0, r.size.y), accent, true)
		draw_string(font, r.position + Vector2(34.0, 58.0), String(u["title"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34, Color("ffffff"))
		draw_string(font, r.position + Vector2(34.0, 104.0), String(u["desc"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("b0bec5"))
		var stacks := int(game._stacks.get(u["id"], 0))
		draw_string(font, r.position + Vector2(r.size.x - 130.0, 58.0),
			"Lv %d/%d" % [stacks + 1, int(u["max"])],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, accent)


func _draw_arrow() -> void:
	var pulse := 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) * 0.008))
	var col := Color(0.9, 0.2, 0.2, pulse)
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var pts := PackedVector2Array()
	match _arrow_side:
		0:
			pts = PackedVector2Array([Vector2(cx - 48.0, 110.0), Vector2(cx + 48.0, 110.0), Vector2(cx, 176.0)])
		1:
			pts = PackedVector2Array([Vector2(size.x - 110.0, cy - 48.0), Vector2(size.x - 110.0, cy + 48.0), Vector2(size.x - 44.0, cy)])
		2:
			pts = PackedVector2Array([Vector2(cx - 48.0, size.y - 176.0), Vector2(cx + 48.0, size.y - 176.0), Vector2(cx, size.y - 110.0)])
		_:
			pts = PackedVector2Array([Vector2(110.0, cy - 48.0), Vector2(110.0, cy + 48.0), Vector2(44.0, cy)])
	draw_colored_polygon(pts, col)
