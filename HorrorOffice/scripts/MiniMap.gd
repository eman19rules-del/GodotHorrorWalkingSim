## MiniMap.gd
## Draws a top-down schematic of the level in a small HUD panel.
##
## Rooms are hardcoded to match LevelGenerator's layout.
## Player is shown as a white dot with a direction arrow.
## Active monsters are shown as red dots.
## Uncollected keys are shown as coloured diamonds.
## Locked doors are red marks; unlocked/open doors are green.
extends Control

# ── Panel dimensions ──────────────────────────────────────────────────────────
const MAP_W : float = 130.0
const MAP_H : float = 200.0
const PAD   : float = 6.0

# ── World bounds to map ───────────────────────────────────────────────────────
# Level spans roughly X: -17..17 (34 u), Z: 6..-82 (88 u)
const WX_MIN  : float = -17.0
const WX_MAX  : float =  17.0
const WZ_MIN  : float = -83.0
const WZ_MAX  : float =   6.0
const WX_SPAN : float = WX_MAX - WX_MIN   # 34
const WZ_SPAN : float = WZ_MAX - WZ_MIN   # 89

# Inner drawable area
const INNER_W : float = MAP_W - PAD * 2.0
const INNER_H : float = MAP_H - PAD * 2.0

# ── Cached refs ───────────────────────────────────────────────────────────────
var _player : Node3D = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	custom_minimum_size = Vector2(MAP_W, MAP_H)

func _process(_delta: float) -> void:
	queue_redraw()

# ── World → map conversion ────────────────────────────────────────────────────
func _w2m(wx: float, wz: float) -> Vector2:
	var mx := (wx - WX_MIN) / WX_SPAN * INNER_W + PAD
	var my := (WZ_MAX - wz) / WZ_SPAN * INNER_H + PAD
	return Vector2(mx, my)

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Background panel
	draw_rect(Rect2(0.0, 0.0, MAP_W, MAP_H), Color(0.04, 0.04, 0.04, 0.82))
	draw_rect(Rect2(1.0, 1.0, MAP_W - 2.0, MAP_H - 2.0),
		Color(0.35, 0.33, 0.28, 1.0), false, 1.0)

	# ── Room fills ────────────────────────────────────────────────────────────
	# Main corridor
	_fill_room(-2.0, 5.0,  2.0, -81.0, Color(0.24, 0.22, 0.20))
	# Room A (east)
	_fill_room( 2.0, -8.0, 16.0, -22.0, Color(0.28, 0.26, 0.34))
	# Room B (west)
	_fill_room(-16.0, -29.0, -2.0, -47.0, Color(0.22, 0.24, 0.20))
	# Room C (dark)
	_fill_room( 2.0, -50.0, 16.0, -69.0, Color(0.14, 0.14, 0.13))

	# ── Room outlines ─────────────────────────────────────────────────────────
	_outline_room(-2.0, 5.0,  2.0, -81.0,  Color(0.55, 0.52, 0.46))
	_outline_room( 2.0, -8.0, 16.0, -22.0, Color(0.55, 0.52, 0.60))
	_outline_room(-16.0,-29.0,-2.0, -47.0, Color(0.48, 0.52, 0.44))
	_outline_room( 2.0,-50.0, 16.0, -69.0, Color(0.40, 0.40, 0.38))

	# ── Door marks ────────────────────────────────────────────────────────────
	# Side-room doors (always unlocked — show as neutral white)
	_door_mark( 2.0, -15.0,  false)
	_door_mark(-2.0, -38.0,  false)
	_door_mark( 2.0, -59.5,  false)
	# Corridor locked doors (red until key collected)
	_door_mark( 0.0, -25.0,  not GameManager.has_key("key_a"))
	_door_mark( 0.0, -52.0,  not GameManager.has_key("key_b"))
	_door_mark( 0.0, -79.0,  not GameManager.has_key("key_exit"))

	# ── Key diamonds ─────────────────────────────────────────────────────────
	if not GameManager.has_key("key_a"):
		_key_diamond(12.5, -19.5, Color(0.55, 1.0, 0.20))
	if not GameManager.has_key("key_b"):
		_key_diamond(-12.5, -43.5, Color(0.25, 0.80, 1.0))
	if not GameManager.has_key("key_exit"):
		_key_diamond(13.0, -65.0,  Color(1.0,  0.85, 0.0))

	# ── Monster dots ─────────────────────────────────────────────────────────
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.visible:
			var mp := _w2m(m.global_position.x, m.global_position.z)
			draw_circle(mp, 3.2, Color(0.92, 0.10, 0.10, 0.95))

	# ── Player dot + direction arrow ─────────────────────────────────────────
	if _player:
		var pp := _w2m(_player.global_position.x, _player.global_position.z)
		draw_circle(pp, 3.6, Color(1.0, 1.0, 1.0, 1.0))
		var fwd := -_player.global_transform.basis.z.normalized()
		var tip := pp + Vector2(fwd.x, fwd.z) * 7.0
		draw_line(pp, tip, Color(1.0, 1.0, 0.55, 1.0), 1.5)

	# ── "MAP" label ───────────────────────────────────────────────────────────
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(PAD + 2.0, PAD + 9.0), "MAP",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.65, 0.62, 0.55, 0.90))

# ── Drawing helpers ───────────────────────────────────────────────────────────
func _fill_room(x1: float, z1: float, x2: float, z2: float, color: Color) -> void:
	var tl := _w2m(x1, z1)
	var br := _w2m(x2, z2)
	draw_rect(Rect2(tl, br - tl), color)

func _outline_room(x1: float, z1: float, x2: float, z2: float, color: Color) -> void:
	var tl := _w2m(x1, z1)
	var br := _w2m(x2, z2)
	draw_rect(Rect2(tl, br - tl), color, false, 1.0)

func _door_mark(wx: float, wz: float, is_locked: bool) -> void:
	var p := _w2m(wx, wz)
	var c := Color(1.0, 0.20, 0.10) if is_locked else Color(0.35, 0.90, 0.35)
	draw_circle(p, 2.8, c)

func _key_diamond(wx: float, wz: float, color: Color) -> void:
	var p := _w2m(wx, wz)
	var s := 3.8
	draw_line(p + Vector2( 0, -s), p + Vector2( s,  0), color, 1.5)
	draw_line(p + Vector2( s,  0), p + Vector2( 0,  s), color, 1.5)
	draw_line(p + Vector2( 0,  s), p + Vector2(-s,  0), color, 1.5)
	draw_line(p + Vector2(-s,  0), p + Vector2( 0, -s), color, 1.5)
