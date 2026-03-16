## GameManager.gd
## Autoloaded singleton. Holds global game state, emits signals for
## horror level changes, player death, and win condition.
extends Node

signal horror_level_changed(level: int)
signal game_over_triggered
signal game_won_triggered

var horror_level: int = 0
var is_game_over: bool = false
var has_exit_key: bool = false

var _interact_label: Label = null
var _stamina_bar: ProgressBar = null
var _death_screen: Control = null
var _win_screen: Control = null
var _vignette: ColorRect = null

# ── Public API ────────────────────────────────────────────────────────────────

func register_hud(hud: CanvasLayer) -> void:
	_interact_label = hud.get_node_or_null("InteractLabel")
	_stamina_bar    = hud.get_node_or_null("StaminaBar")
	_death_screen   = hud.get_node_or_null("DeathScreen")
	_win_screen     = hud.get_node_or_null("WinScreen")
	_vignette       = hud.get_node_or_null("Vignette")

func set_horror_level(level: int) -> void:
	level = clamp(level, 0, 4)
	if level <= horror_level:
		return
	horror_level = level
	horror_level_changed.emit(horror_level)
	# Propagate speed/aggression to all monsters
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.has_method("set_horror_level"):
			monster.set_horror_level(horror_level)

func set_interact_hint(text: String) -> void:
	if _interact_label:
		_interact_label.text = text

func clear_interact_hint() -> void:
	if _interact_label:
		_interact_label.text = ""

func update_stamina(pct: float) -> void:
	if _stamina_bar:
		_stamina_bar.value = pct * 100.0

func set_vignette_intensity(t: float) -> void:
	# t: 0.0 = invisible, 1.0 = full red/dark vignette
	if _vignette:
		var alpha = clamp(t * 0.75, 0.0, 0.75)
		_vignette.modulate = Color(1.0, 0.0, 0.0, alpha)

func player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _death_screen:
		_death_screen.visible = true

func trigger_win() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_won_triggered.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _win_screen:
		_win_screen.visible = true

func pickup_key() -> void:
	has_exit_key = true
	set_interact_hint("You found the exit key!")
	await get_tree().create_timer(2.0).timeout
	clear_interact_hint()
