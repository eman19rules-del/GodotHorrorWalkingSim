## LevelGenerator.gd
## Builds "The Long Corridor" — an abandoned office floor.
##
## Layout (top-down, X east, Z south/into-screen):
##
##   [SPAWN Z≈3] ──────────────────────────────────────────────── [EXIT Z≈-79]
##   │                Main Corridor  X:-2..2                             │
##   │  Room A (office)           Room C (dark utility)                  │
##   │  X:2..16  Z:-8..-22 ─►    X:2..16  Z:-50..-69                   │
##   │  Key A (unlocks Door 1)    Exit Key                               │
##   │                                                                    │
##   │           Room B (storage)                                         │
##   │           X:-16..-2  Z:-29..-47  ◄─                              │
##   │           Key B (unlocks Door 2)                                  │
##   │                                                                    │
##   DOOR 1 @ Z=-25 (key_a)   DOOR 2 @ Z=-52 (key_b)
##
## Keys must be collected to open the locked cross-corridor doors.
## Three unlocked side-room doors can be opened freely at any time.
## Exit door (key_exit) is at Z=-79; walking past it triggers the win.

extends Node3D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var door_scene    : PackedScene
@export var monster_scene : PackedScene
@export var horror_prog   : Node

# ── Geometry constants ────────────────────────────────────────────────────────
const H   := 3.0    # room height
const WT  := 0.22   # wall thickness
const DW  := 1.15   # door opening width
const DH  := 2.25   # door opening height

# ── Colour palette ────────────────────────────────────────────────────────────
const C_CORR_WALL  := Color(0.68, 0.65, 0.60)   # dingy corridor plaster
const C_CORR_FLOOR := Color(0.22, 0.20, 0.19)   # dark concrete
const C_CEIL       := Color(0.88, 0.86, 0.82)
const C_ROOM_A_W   := Color(0.80, 0.76, 0.72)   # office cream
const C_ROOM_A_F   := Color(0.35, 0.32, 0.42)   # carpet
const C_ROOM_B_W   := Color(0.52, 0.55, 0.50)   # industrial green-grey
const C_ROOM_B_F   := Color(0.28, 0.26, 0.23)   # concrete
const C_ROOM_C_W   := Color(0.28, 0.30, 0.28)   # dark server room
const C_ROOM_C_F   := Color(0.13, 0.13, 0.12)   # near-black floor
const C_TRIM       := Color(0.45, 0.42, 0.38)
const C_WOOD       := Color(0.52, 0.36, 0.20)
const C_METAL      := Color(0.40, 0.42, 0.44)

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass  # build() called by Main.gd after dependencies are injected

func build() -> void:
	_build_main_corridor()
	_build_room_a()
	_build_room_b()
	_build_room_c()
	_place_all_doors()
	_add_props()
	_add_horror_triggers()

# ─────────────────────────────────────────────────────────────────────────────
# MAIN CORRIDOR   X:-2..2   Z: 5..-81
# ─────────────────────────────────────────────────────────────────────────────
func _build_main_corridor() -> void:
	# Floor & ceiling  (center Z = (5-81)/2 = -38, length = 86)
	_floor(0.0,  0.0, -38.0, 4.0, 86.0, C_CORR_FLOOR)
	_ceil( 0.0,  H,   -38.0, 4.0, 86.0)

	# North end cap
	_wall_solid_z(0.0, -81.0, 4.0, C_CORR_WALL)

	# ── East wall (X=2) ──────────────────────────────────────────────────────
	# Segment 1: Z 5 → -8   (solid, before Room A)
	_wall_solid_x( 2.0,  -1.5,  13.0, C_CORR_WALL)
	# Segment 2: Z -8 → -22  (door opening at Z=-15 for Room A)
	_wall_door_x(  2.0, -15.0,  14.0, -15.0, C_CORR_WALL)
	# Segment 3: Z -22 → -50 (solid between rooms A and C)
	_wall_solid_x( 2.0, -36.0,  28.0, C_CORR_WALL)
	# Segment 4: Z -50 → -69 (door opening at Z=-59.5 for Room C)
	_wall_door_x(  2.0, -59.5,  19.0, -59.5, C_CORR_WALL)
	# Segment 5: Z -69 → -81 (solid after Room C)
	_wall_solid_x( 2.0, -75.0,  12.0, C_CORR_WALL)

	# ── West wall (X=-2) ─────────────────────────────────────────────────────
	# Segment 1: Z 5 → -29  (solid before Room B)
	_wall_solid_x(-2.0, -12.0,  34.0, C_CORR_WALL)
	# Segment 2: Z -29 → -47 (door opening at Z=-38 for Room B)
	_wall_door_x( -2.0, -38.0,  18.0, -38.0, C_CORR_WALL)
	# Segment 3: Z -47 → -81 (solid after Room B)
	_wall_solid_x(-2.0, -64.0,  34.0, C_CORR_WALL)

	# ── Cross-walls with door openings (locked doors placed separately) ───────
	_wall_door_z(0.0, -25.0, 4.0, 0.0, C_CORR_WALL)   # Door 1
	_wall_door_z(0.0, -52.0, 4.0, 0.0, C_CORR_WALL)   # Door 2
	_wall_door_z(0.0, -79.0, 4.0, 0.0, C_CORR_WALL)   # Exit door

	# ── Ceiling lights down the corridor ─────────────────────────────────────
	for z in [-4.0, -15.0, -25.0, -38.0, -52.0, -65.0, -76.0]:
		_ceiling_light(0.0, H - 0.05, z, C_CORR_WALL)

# ─────────────────────────────────────────────────────────────────────────────
# ROOM A – Office side room (east)   X:2..16   Z:-8..-22
# Contains Key A → unlocks Door 1
# ─────────────────────────────────────────────────────────────────────────────
func _build_room_a() -> void:
	_floor(9.0, 0.0, -15.0, 14.0, 14.0, C_ROOM_A_F)
	_ceil( 9.0, H,  -15.0, 14.0, 14.0)
	# East wall (far)
	_wall_solid_x(16.0, -15.0, 14.0, C_ROOM_A_W)
	# South wall
	_wall_solid_z( 9.0,  -8.0, 14.0, C_ROOM_A_W)
	# North wall
	_wall_solid_z( 9.0, -22.0, 14.0, C_ROOM_A_W)
	# West wall shared with corridor (already built with opening at Z=-15)
	_trim_z(9.0,  -8.0, 14.0)
	_trim_z(9.0, -22.0, 14.0)
	_trim_x(16.0, -15.0, 14.0)
	_ceiling_light(9.0, H - 0.05, -15.0, C_ROOM_A_W)
	_place_key(Vector3(12.5, 0.9, -19.5), "key_a", Color(0.5, 1.0, 0.15))

# ─────────────────────────────────────────────────────────────────────────────
# ROOM B – Storage side room (west)   X:-16..-2   Z:-29..-47
# Contains Key B → unlocks Door 2
# ─────────────────────────────────────────────────────────────────────────────
func _build_room_b() -> void:
	_floor(-9.0, 0.0, -38.0, 14.0, 18.0, C_ROOM_B_F)
	_ceil( -9.0, H,  -38.0, 14.0, 18.0)
	# West wall (far)
	_wall_solid_x(-16.0, -38.0, 18.0, C_ROOM_B_W)
	# South wall
	_wall_solid_z( -9.0, -29.0, 14.0, C_ROOM_B_W)
	# North wall
	_wall_solid_z( -9.0, -47.0, 14.0, C_ROOM_B_W)
	# East wall shared with corridor (already built with opening at Z=-38)
	_ceiling_light(-9.0, H - 0.05, -38.0, C_ROOM_B_W)
	_place_key(Vector3(-12.5, 0.9, -43.5), "key_b", Color(0.2, 0.75, 1.0))

# ─────────────────────────────────────────────────────────────────────────────
# ROOM C – Dark utility room (east)   X:2..16   Z:-50..-69
# Contains Exit Key
# ─────────────────────────────────────────────────────────────────────────────
func _build_room_c() -> void:
	_floor(9.0, 0.0, -59.5, 14.0, 19.0, C_ROOM_C_F)
	_ceil( 9.0, H,  -59.5, 14.0, 19.0)
	# East wall (far)
	_wall_solid_x(16.0, -59.5, 19.0, C_ROOM_C_W)
	# South wall
	_wall_solid_z( 9.0, -50.0, 14.0, C_ROOM_C_W)
	# North wall
	_wall_solid_z( 9.0, -69.0, 14.0, C_ROOM_C_W)
	# West wall shared with corridor (built with opening at Z=-59.5)
	# Single dim light — this room should feel oppressive
	_ceiling_light(9.0, H - 0.05, -59.5, C_ROOM_C_W)
	# Exit key glows gold
	_place_key(Vector3(13.0, 0.9, -65.0), "key_exit", Color(1.0, 0.85, 0.0))
	# Green exit sign above exit door
	var sign := _add_box(Vector3(0.0, H - 0.55, -79.15), Vector3(1.8, 0.35, 0.08),
		Color(0.1, 0.8, 0.1))
	sign.use_collision = false

# ─────────────────────────────────────────────────────────────────────────────
# DOOR PLACEMENT
# ─────────────────────────────────────────────────────────────────────────────
func _place_all_doors() -> void:
	if not door_scene:
		push_warning("LevelGenerator: door_scene not assigned!")
		return

	# Door panel (width 1.1) extends from the pivot:
	#   rot = 90°  → panel extends in world +Z; hinge at opening_z − DW/2
	#   rot = 0°   → panel extends in world −X; hinge at opening_x + DW/2

	var door_specs := [
		# ── Side-room doors (unlocked, X-perp walls) ──────────────────────────
		# Room A (east wall at X=2, opening Z=-15): rot=90°
		{ "pos": Vector3( 2.0, 0.0, -15.0 - DW/2), "rot": deg_to_rad(90), "locked": false, "key_id": "" },
		# Room B (west wall at X=-2, opening Z=-38): rot=90°
		{ "pos": Vector3(-2.0, 0.0, -38.0 - DW/2), "rot": deg_to_rad(90), "locked": false, "key_id": "" },
		# Room C (east wall at X=2, opening Z=-59.5): rot=90°
		{ "pos": Vector3( 2.0, 0.0, -59.5 - DW/2), "rot": deg_to_rad(90), "locked": false, "key_id": "" },

		# ── Corridor cross-doors (Z-perp walls, opening at X=0) ───────────────
		# Door 1 @ Z=-25 (key_a)
		{ "pos": Vector3(DW/2, 0.0, -25.0), "rot": 0.0, "locked": true, "key_id": "key_a" },
		# Door 2 @ Z=-52 (key_b)
		{ "pos": Vector3(DW/2, 0.0, -52.0), "rot": 0.0, "locked": true, "key_id": "key_b" },
		# Exit door @ Z=-79 (key_exit)
		{ "pos": Vector3(DW/2, 0.0, -79.0), "rot": 0.0, "locked": true, "key_id": "key_exit" },
	]

	for spec in door_specs:
		var door := door_scene.instantiate()
		door.position  = spec["pos"]
		door.rotation.y = spec["rot"]
		door.locked    = spec["locked"]
		door.key_id    = spec["key_id"]
		add_child(door)

# ─────────────────────────────────────────────────────────────────────────────
# PROPS
# ─────────────────────────────────────────────────────────────────────────────
func _add_props() -> void:
	# ── Main corridor – sparse, oppressive ────────────────────────────────────
	# A few overturned chairs and papers scattered along the hall
	_filing_cabinet(Vector3( 1.2, 0.0, -8.5))
	_filing_cabinet(Vector3(-1.2, 0.0, -44.0))

	# ── Room A – office hiding room ───────────────────────────────────────────
	_desk(Vector3(5.5,  0.0, -11.0))
	_desk(Vector3(10.0, 0.0, -11.0))
	_desk(Vector3(5.5,  0.0, -18.5), deg_to_rad(180))
	_desk(Vector3(10.0, 0.0, -18.5), deg_to_rad(180))
	_bookshelf(Vector3(15.3, 0.0, -12.0))
	_bookshelf(Vector3(15.3, 0.0, -17.0))
	_filing_cabinet(Vector3(15.3, 0.0, -20.0))
	_potted_plant(Vector3( 3.5, 0.0,  -9.5))

	# ── Room B – storage hiding room ──────────────────────────────────────────
	_shelf_unit(Vector3(-15.2, 0.0, -31.0))
	_shelf_unit(Vector3(-15.2, 0.0, -35.5))
	_shelf_unit(Vector3(-15.2, 0.0, -40.0))
	_shelf_unit(Vector3(-15.2, 0.0, -44.5))
	_boxes_pile(Vector3(-5.5,  0.0, -31.5))
	_boxes_pile(Vector3(-8.0,  0.0, -44.0))
	_boxes_pile(Vector3(-12.0, 0.0, -33.0))

	# ── Room C – dark utility room (minimal) ──────────────────────────────────
	_shelf_unit(Vector3(15.2, 0.0, -52.5))
	_shelf_unit(Vector3(15.2, 0.0, -57.0))
	_shelf_unit(Vector3(15.2, 0.0, -61.5))
	_shelf_unit(Vector3(15.2, 0.0, -66.0))
	_boxes_pile(Vector3( 4.5, 0.0, -52.0))
	_boxes_pile(Vector3( 4.5, 0.0, -67.5))

# ─────────────────────────────────────────────────────────────────────────────
# HORROR TRIGGERS
# ─────────────────────────────────────────────────────────────────────────────
func _add_horror_triggers() -> void:
	# Level 1 – entering the corridor proper (first light starts to flicker)
	_horror_trigger(Vector3(0.0, 1.5, -8.0),  Vector3(4.0, 3.0, 4.0), 1)
	# Level 2 – approaching Door 1 (monster wakes far away)
	_horror_trigger(Vector3(0.0, 1.5, -22.0), Vector3(4.0, 3.0, 4.0), 2)
	# Level 3 – passing Door 1 into second section
	_horror_trigger(Vector3(0.0, 1.5, -30.0), Vector3(4.0, 3.0, 6.0), 3)
	# Level 4 – reaching Door 2 zone
	_horror_trigger(Vector3(0.0, 1.5, -56.0), Vector3(4.0, 3.0, 4.0), 4)

	# Win trigger – player walks through exit door
	var win_area := Area3D.new()
	win_area.position = Vector3(0.0, 1.5, -81.5)
	var win_col   := CollisionShape3D.new()
	var win_shape := BoxShape3D.new()
	win_shape.size = Vector3(4.0, 3.0, 2.0)
	win_col.shape  = win_shape
	win_area.add_child(win_col)
	win_area.collision_layer = 0
	win_area.collision_mask  = 1
	win_area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			GameManager.trigger_win()
	)
	add_child(win_area)

func _horror_trigger(pos: Vector3, size: Vector3, target_level: int) -> void:
	var area := Area3D.new()
	area.position = pos
	var col   := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape  = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask  = 1
	area.body_entered.connect(
		func(body: Node3D) -> void:
			if body.is_in_group("player"):
				GameManager.set_horror_level(target_level)
				if horror_prog and horror_prog.has_method("advance_horror"):
					horror_prog.advance_horror(target_level)
	)
	add_child(area)

# ─────────────────────────────────────────────────────────────────────────────
# MONSTER SPAWNING
# ─────────────────────────────────────────────────────────────────────────────
func spawn_monster(horror_level: int) -> void:
	if not monster_scene:
		return
	var spawn_positions := {
		2: [Vector3( 0.0, 0.0, -72.0)],              # far end of corridor – gives time to react
		3: [Vector3(-8.0, 0.0, -40.0)],              # inside Room B
		4: [Vector3( 0.0, 0.0, -40.0),               # middle of corridor
		    Vector3( 9.0, 0.0, -59.0)],              # inside Room C
	}
	if not spawn_positions.has(horror_level):
		return
	for pos in spawn_positions[horror_level]:
		var m := monster_scene.instantiate()
		m.position = pos
		get_parent().get_node("Monsters").add_child(m)
		m.activate()

# ─────────────────────────────────────────────────────────────────────────────
# PROP HELPERS (unchanged from previous version)
# ─────────────────────────────────────────────────────────────────────────────
func _desk(pos: Vector3, rot_y: float = 0.0) -> void:
	var g := Node3D.new(); g.position = pos; g.rotation.y = rot_y; add_child(g)
	_add_box_to(g, Vector3(0, 0.75, 0),          Vector3(1.5, 0.06, 0.8),   C_WOOD)
	_add_box_to(g, Vector3(-0.65, 0.375, -0.35), Vector3(0.06, 0.75, 0.06), C_METAL)
	_add_box_to(g, Vector3( 0.65, 0.375, -0.35), Vector3(0.06, 0.75, 0.06), C_METAL)
	_add_box_to(g, Vector3(-0.65, 0.375,  0.35), Vector3(0.06, 0.75, 0.06), C_METAL)
	_add_box_to(g, Vector3( 0.65, 0.375,  0.35), Vector3(0.06, 0.75, 0.06), C_METAL)
	_add_box_to(g, Vector3(0, 1.25, -0.1),       Vector3(0.7, 0.42, 0.04),  Color(0.05,0.05,0.05))
	_add_box_to(g, Vector3(0, 0.82, -0.1),       Vector3(0.05,0.42,0.05),   C_METAL)
	_add_box_to(g, Vector3(0, 0.78,  0.2),       Vector3(0.35,0.015,0.12),  Color(0.15,0.15,0.15))

func _bookshelf(pos: Vector3) -> void:
	var g := Node3D.new(); g.position = pos; add_child(g)
	_add_box_to(g, Vector3(0, 1.0, 0), Vector3(0.3, 2.0, 0.8), C_WOOD)
	for y in [0.35, 0.85, 1.35, 1.7]:
		_add_box_to(g, Vector3(0.02, y, 0), Vector3(0.04, 0.08, 0.7), Color(0.5,0.3,0.1))

func _filing_cabinet(pos: Vector3) -> void:
	_add_box(pos + Vector3(0, 0.55, 0), Vector3(0.5, 1.1, 0.6), C_METAL)

func _potted_plant(pos: Vector3) -> void:
	_add_box(pos + Vector3(0, 0.25, 0), Vector3(0.28,0.5,0.28),  Color(0.5,0.3,0.1))
	_add_box(pos + Vector3(0, 0.7,  0), Vector3(0.4, 0.6, 0.4),  Color(0.15,0.5,0.1))

func _shelf_unit(pos: Vector3) -> void:
	var g := Node3D.new(); g.position = pos; add_child(g)
	_add_box_to(g, Vector3(0, 1.2, 0), Vector3(0.3, 2.4, 0.9), C_METAL * Color(0.7,0.7,0.7,1))
	for y in [0.4, 0.95, 1.5, 2.05]:
		_add_box_to(g, Vector3(0.02, y, 0), Vector3(0.04, 0.06, 0.85), C_METAL)

func _boxes_pile(pos: Vector3) -> void:
	for i in 3:
		_add_box(pos + Vector3(0, 0.2 + i*0.42, 0),
			Vector3(randf_range(0.3,0.5), 0.38, randf_range(0.3,0.5)),
			Color(0.6,0.52,0.38))

func _ceiling_light(cx: float, y: float, cz: float, _room_color: Color) -> void:
	var fixture := _add_box(Vector3(cx, y, cz), Vector3(1.1, 0.07, 0.28), Color(0.9,0.9,0.9))
	fixture.use_collision = false
	var light := OmniLight3D.new()
	light.position             = Vector3(cx, y - 0.12, cz)
	light.light_energy         = 1.5
	light.light_color          = Color(1.0, 0.97, 0.88)
	light.omni_range           = 9.0
	light.shadow_enabled       = false
	add_child(light)
	if horror_prog and horror_prog.has_method("register_flicker_light"):
		horror_prog.register_flicker_light(light)

func _place_key(pos: Vector3, key_id: String, glow_color: Color) -> void:
	var body := Area3D.new()
	body.position        = pos
	body.collision_layer = 0
	body.collision_mask  = 1
	var col := CollisionShape3D.new()
	var sh  := BoxShape3D.new()
	sh.size  = Vector3(0.45, 0.45, 0.45)
	col.shape = sh
	body.add_child(col)
	var vis := _make_box_mesh(Vector3(0.22, 0.10, 0.05), glow_color)
	body.add_child(vis)
	body.body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("player"):
			GameManager.pickup_key(key_id)
			body.queue_free()
	)
	add_child(body)

# ─────────────────────────────────────────────────────────────────────────────
# WALL / FLOOR / CEILING HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _floor(cx: float, cy: float, cz: float, w: float, d: float,
		color: Color = Color(0.4,0.38,0.35)) -> void:
	_add_box(Vector3(cx, cy, cz), Vector3(w, WT, d), color)

func _ceil(cx: float, cy: float, cz: float, w: float, d: float) -> void:
	_add_box(Vector3(cx, cy, cz), Vector3(w, WT, d), C_CEIL)

func _wall_solid_z(cx: float, z: float, len_x: float,
		color: Color = C_CORR_WALL) -> void:
	_add_box(Vector3(cx, H/2, z), Vector3(len_x, H, WT), color)

func _wall_solid_x(x: float, cz: float, len_z: float,
		color: Color = C_CORR_WALL) -> void:
	_add_box(Vector3(x, H/2, cz), Vector3(WT, H, len_z), color)

## Z-perpendicular wall with a door-width opening centred at door_x.
func _wall_door_z(cx: float, z: float, len_x: float, door_x: float,
		color: Color = C_CORR_WALL) -> void:
	var half     := len_x / 2.0
	var lx_start := cx - half
	var lx_end   := door_x - DW / 2.0
	var rx_start := door_x + DW / 2.0
	var rx_end   := cx + half
	if lx_end > lx_start:
		var w := lx_end - lx_start
		_add_box(Vector3(lx_start + w/2, H/2, z), Vector3(w, H, WT), color)
	if rx_end > rx_start:
		var w := rx_end - rx_start
		_add_box(Vector3(rx_start + w/2, H/2, z), Vector3(w, H, WT), color)
	var header_h := H - DH
	if header_h > 0.02:
		_add_box(Vector3(door_x, DH + header_h/2, z), Vector3(DW, header_h, WT), color)

## X-perpendicular wall with a door-width opening centred at door_z.
func _wall_door_x(x: float, cz: float, len_z: float, door_z: float,
		color: Color = C_CORR_WALL) -> void:
	var half     := len_z / 2.0
	var lz_start := cz - half
	var lz_end   := door_z - DW / 2.0
	var rz_start := door_z + DW / 2.0
	var rz_end   := cz + half
	if lz_end > lz_start:
		var d := lz_end - lz_start
		_add_box(Vector3(x, H/2, lz_start + d/2), Vector3(WT, H, d), color)
	if rz_end > rz_start:
		var d := rz_end - rz_start
		_add_box(Vector3(x, H/2, rz_start + d/2), Vector3(WT, H, d), color)
	var header_h := H - DH
	if header_h > 0.02:
		_add_box(Vector3(x, DH + header_h/2, door_z), Vector3(WT, header_h, DW), color)

func _trim_z(cx: float, z: float, len_x: float) -> void:
	_add_box(Vector3(cx, 0.06, z), Vector3(len_x, 0.12, 0.04), C_TRIM)

func _trim_x(x: float, cz: float, len_z: float) -> void:
	_add_box(Vector3(x, 0.06, cz), Vector3(0.04, 0.12, len_z), C_TRIM)

# ─────────────────────────────────────────────────────────────────────────────
# PRIMITIVE FACTORIES
# ─────────────────────────────────────────────────────────────────────────────
func _add_box(pos: Vector3, size: Vector3, color: Color) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size          = size
	b.position      = pos
	b.use_collision = true
	b.material      = _mat(color)
	add_child(b)
	return b

func _add_box_to(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size          = size
	b.position      = pos
	b.use_collision = true
	b.material      = _mat(color)
	parent.add_child(b)
	return b

func _make_box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mi  := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color               = color
	mat.emission_enabled           = true
	mat.emission                   = color * 1.5
	mat.emission_energy_multiplier = 2.0
	mi.material_override           = mat
	return mi

func _mat(color: Color) -> StandardMaterial3D:
	var m          := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = 0.88
	m.metallic     = 0.0
	return m
