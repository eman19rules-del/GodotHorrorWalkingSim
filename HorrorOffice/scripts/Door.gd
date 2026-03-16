## Door.gd
## Attach to the root Node3D of a Door scene.
## The scene must have a child Node3D named "Pivot" — rotating that
## swings the door. A StaticBody3D lives inside Pivot so the door
## physically blocks CharacterBody3D monsters when closed.
##
## interact_hint is read by Player._update_interact_hint().
extends Node3D

@export var open_angle_deg : float = -85.0   # negative = opens inward/CCW
@export var swing_duration : float = 0.45
@export var locked         : bool  = false   # exit door starts locked

var is_open      : bool  = false
var is_animating : bool  = false
var player_nearby: bool  = false
var interact_hint: String = "[E] Open door"

@onready var pivot : Node3D = $Pivot

func _ready() -> void:
	# Make sure prompt area signals are connected
	var area := get_node_or_null("PromptArea")
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

# ── Called by Player ──────────────────────────────────────────────────────────
func interact() -> void:
	if is_animating:
		return
	if locked:
		if GameManager.has_exit_key:
			locked = false
			# Fall through to open
		else:
			GameManager.set_interact_hint("It's locked. Find the key.")
			await get_tree().create_timer(1.8).timeout
			GameManager.clear_interact_hint()
			return
	_toggle()

func _toggle() -> void:
	is_open      = !is_open
	is_animating = true
	interact_hint = "[E] Close door" if is_open else "[E] Open door"

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	var target_y := deg_to_rad(open_angle_deg) if is_open else 0.0
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
