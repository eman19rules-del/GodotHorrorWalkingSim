## Monster.gd
## Simple horror chase AI. No navigation mesh needed — uses direct steering
## with CharacterBody3D.move_and_slide() for natural wall-sliding behaviour.
##
## States:
##   DORMANT  – not yet spawned in, invisible
##   IDLE     – standing still, counting down to wander
##   WANDER   – moving to a random nearby point
##   CHASE    – sprinting toward the player
##   BLOCKED  – door is in the way; pounds on it
extends CharacterBody3D

enum State { DORMANT, IDLE, WANDER, CHASE, BLOCKED }

# ── Tuning ─────────────────────────────────────────────────────────────────────
const GRAVITY          := 18.0
const BASE_WALK_SPEED  := 2.2
const BASE_CHASE_SPEED := 4.8
const ATTACK_RADIUS    := 1.1
const BASE_DETECT_DIST := 11.0
const LOSE_DIST_MULT   := 1.6   # stop chasing past this × detect distance

# ── Runtime vars ──────────────────────────────────────────────────────────────
var walk_speed    : float = BASE_WALK_SPEED
var chase_speed   : float = BASE_CHASE_SPEED
var detect_dist   : float = BASE_DETECT_DIST

var state         : State = State.DORMANT
var player        : Node3D = null

var wander_target : Vector3 = Vector3.ZERO
var wander_timer  : float   = 0.0

# Stuck detection
var stuck_timer   : float   = 0.0
var last_check_pos: Vector3 = Vector3.ZERO
const STUCK_CHECK  := 0.6
const STUCK_THRESH := 0.08

var blocked_timer : float = 0.0
const BLOCKED_DUR  := 2.8

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var mesh : MeshInstance3D = $MeshInstance3D

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("monsters")
	player = get_tree().get_first_node_in_group("player")
	last_check_pos = global_position
	visible = false   # hidden until activate() is called

func activate() -> void:
	visible = true
	state   = State.IDLE
	wander_timer = randf_range(1.5, 4.0)

# ── Per-frame ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if state == State.DORMANT or GameManager.is_game_over:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_run_state(delta)
	_check_player_detection()
	_check_attack()
	move_and_slide()
	_animate(delta)

func _run_state(delta: float) -> void:
	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			wander_timer -= delta
			if wander_timer <= 0.0:
				_pick_wander_target()
				state = State.WANDER
				wander_timer = randf_range(3.0, 7.0)

		State.WANDER:
			wander_timer -= delta
			var to_target := wander_target - global_position
			to_target.y = 0.0
			if to_target.length() < 0.8 or wander_timer <= 0.0:
				state = State.IDLE
				wander_timer = randf_range(1.5, 4.0)
				velocity.x = 0.0
				velocity.z = 0.0
			else:
				_move_toward(to_target.normalized(), walk_speed)

		State.CHASE:
			if not player or GameManager.is_game_over:
				state = State.WANDER
				return
			var to_player := player.global_position - global_position
			to_player.y = 0.0
			_move_toward(to_player.normalized(), chase_speed)
			# Stuck detection (door blocking)
			stuck_timer += delta
			if stuck_timer >= STUCK_CHECK:
				stuck_timer = 0.0
				var moved := global_position.distance_to(last_check_pos)
				last_check_pos = global_position
				if moved < STUCK_THRESH:
					state = State.BLOCKED
					blocked_timer = BLOCKED_DUR

		State.BLOCKED:
			velocity.x = 0.0
			velocity.z = 0.0
			blocked_timer -= delta
			# Wiggle to sell the "pounding" effect
			var t := Time.get_ticks_msec() * 0.008
			position += Vector3(sin(t) * 0.015, 0.0, 0.0)
			if blocked_timer <= 0.0:
				state = State.CHASE
				last_check_pos = global_position

func _move_toward(dir: Vector3, speed: float) -> void:
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() > 0.05:
		var look_pos := global_position + dir
		look_at(look_pos, Vector3.UP)
		rotation.x = 0.0
		rotation.z = 0.0

func _check_player_detection() -> void:
	if not player or state == State.BLOCKED:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < detect_dist and state != State.CHASE:
		state = State.CHASE
		last_check_pos = global_position
	elif dist > detect_dist * LOSE_DIST_MULT and state == State.CHASE:
		state = State.WANDER
		_pick_wander_target()

func _check_attack() -> void:
	if not player or GameManager.is_game_over:
		return
	if global_position.distance_to(player.global_position) < ATTACK_RADIUS:
		player.die()

func _pick_wander_target() -> void:
	wander_target = global_position + Vector3(
		randf_range(-7.0, 7.0), 0.0, randf_range(-7.0, 7.0)
	)

func _animate(_delta: float) -> void:
	# Simple body bob to feel alive
	if state == State.CHASE or state == State.WANDER:
		var t := Time.get_ticks_msec() * 0.005
		mesh.position.y = abs(sin(t * 2.0)) * 0.06

# ── Called by GameManager when horror level advances ─────────────────────────
func set_horror_level(level: int) -> void:
	detect_dist  = BASE_DETECT_DIST + level * 2.5
	chase_speed  = BASE_CHASE_SPEED + level * 0.6
