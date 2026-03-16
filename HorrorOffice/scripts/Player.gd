## Player.gd
## First-person controller. WASD move, mouse look, E to interact with doors,
## Shift to sprint (limited stamina). Calls GameManager.player_died() on catch.
extends CharacterBody3D

# ── Constants ─────────────────────────────────────────────────────────────────
const WALK_SPEED     := 4.5
const SPRINT_SPEED   := 8.5
const GRAVITY        := 18.0
const MOUSE_SENS     := 0.0022
const BOB_FREQ       := 2.2
const BOB_AMP        := 0.055
const STAMINA_MAX    := 100.0
const STAMINA_DRAIN  := 28.0
const STAMINA_REGEN  := 16.0
const INTERACT_DIST  := 2.8

# ── State ─────────────────────────────────────────────────────────────────────
var stamina       : float = STAMINA_MAX
var can_sprint    : bool  = true
var is_dead       : bool  = false
var bob_time      : float = 0.0
var cam_default_y : float = 0.0

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var head        : Node3D   = $Head
@onready var camera      : Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var flashlight  : SpotLight3D = $Head/Camera3D/Flashlight

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_default_y = camera.position.y

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -deg_to_rad(80), deg_to_rad(80))
	if event.is_action_pressed("toggle_flashlight"):
		flashlight.visible = !flashlight.visible

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# ── Gravity ──────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# ── Stamina & sprint ─────────────────────────────────────────────────────
	var sprinting := Input.is_action_pressed("sprint") and can_sprint and stamina > 0.0
	if sprinting and is_on_floor():
		stamina = max(0.0, stamina - STAMINA_DRAIN * delta)
		if stamina <= 0.0:
			can_sprint = false
	else:
		stamina = min(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
		if stamina > 25.0:
			can_sprint = true
	GameManager.update_stamina(stamina / STAMINA_MAX)

	# ── Movement ─────────────────────────────────────────────────────────────
	var speed    := SPRINT_SPEED if sprinting else WALK_SPEED
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish_dir := (transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	if wish_dir.length() > 0.0:
		velocity.x = wish_dir.x * speed
		velocity.z = wish_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)

	# ── Head bob ─────────────────────────────────────────────────────────────
	var moving := wish_dir.length() > 0.1 and is_on_floor()
	if moving:
		bob_time += delta * BOB_FREQ * (1.6 if sprinting else 1.0)
		camera.position.y = cam_default_y + sin(bob_time * TAU) * BOB_AMP
	else:
		camera.position.y = lerp(camera.position.y, cam_default_y, delta * 12.0)

	move_and_slide()

	# ── Interact ─────────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	_update_interact_hint()

# ── Interaction ───────────────────────────────────────────────────────────────
func _try_interact() -> void:
	if not interact_ray.is_colliding():
		return
	var hit := interact_ray.get_collider()
	if hit == null:
		return
	# Check the collider itself, then its parent chain
	for node in [hit, hit.get_parent(), hit.get_parent().get_parent() if hit.get_parent() else null]:
		if node and node.has_method("interact"):
			node.interact()
			return

func _update_interact_hint() -> void:
	if interact_ray.is_colliding():
		var hit := interact_ray.get_collider()
		var found := false
		for node in [hit, hit.get_parent() if hit else null]:
			if node and node.has_method("interact"):
				var hint: String = node.get("interact_hint") if node.get("interact_hint") != null else "[E] Interact"
				GameManager.set_interact_hint(hint)
				found = true
				break
		if not found:
			GameManager.clear_interact_hint()
	else:
		GameManager.clear_interact_hint()

# ── Called by Monster when caught ────────────────────────────────────────────
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO
	GameManager.player_died()
