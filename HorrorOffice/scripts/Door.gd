## Door.gd
## Attach to the root Node3D of a Door scene.
## The scene must have a child Node3D named "Pivot" — rotating that
## swings the door. A StaticBody3D lives inside Pivot so the door
## physically blocks CharacterBody3D monsters when closed.
##
## Smart swing: the door always opens AWAY from the player. If the player
## is on the +local-Z side the door swings toward -85°; from the -Z side
## it swings to +85°.
##
## key_id: if non-empty, the player must have collected that key to unlock.
## interact_hint is read by Player._update_interact_hint().
extends Node3D

@export var swing_duration : float  = 0.45
@export var locked         : bool   = false
@export var key_id         : String = ""   # "" = never locked; "key_a", "key_b", "key_exit" …

var is_open      : bool   = false
var is_animating : bool   = false
var player_nearby: bool   = false
var interact_hint: String = "[E] Open door"

@onready var pivot : Node3D = $Pivot

func _ready() -> void:
	var area := get_node_or_null("PromptArea")
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

# ── Called by Player ──────────────────────────────────────────────────────────
func interact() -> void:
	if is_animating:
		return
	if locked:
		if key_id == "" or GameManager.has_key(key_id):
			locked = false
			# fall through to open
		else:
			GameManager.set_interact_hint("It's locked. Find the key.")
			await get_tree().create_timer(1.8).timeout
			GameManager.clear_interact_hint()
			return

	# Determine which side the player is on so we can swing away from them.
	var player_node : Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var ppos : Vector3 = player_node.global_position if player_node else global_position + global_transform.basis.z
	_toggle(ppos)

func _toggle(player_world_pos: Vector3) -> void:
	is_open      = !is_open
	is_animating = true
	interact_hint = "[E] Close door" if is_open else "[E] Open door"

	var target_y : float
	if is_open:
		# Convert player to this door's local space to detect which side they're on.
		# Positive local-Z = in front of door → swing the door backward (−85°).
		# Negative local-Z = behind the door  → swing forward (+85°).
		var local_p := to_local(player_world_pos)
		target_y = deg_to_rad(-85.0) if local_p.z >= 0.0 else deg_to_rad(85.0)
	else:
		target_y = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(pivot, "rotation:y", target_y, swing_duration)
	tween.tween_callback(func() -> void: is_animating = false)

# ── Proximity detection ───────────────────────────────────────────────────────
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		GameManager.clear_interact_hint()
