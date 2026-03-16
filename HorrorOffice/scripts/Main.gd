## Main.gd
## Wires up all node references that can't be set via @export in the scene
## (HUD → GameManager, Level → HorrorProgression, etc.) and handles restart.
extends Node3D

@onready var hud               : CanvasLayer = $HUD
@onready var world_env         : WorldEnvironment = $WorldEnvironment
@onready var sun               : DirectionalLight3D = $Sun
@onready var horror_prog       : Node = $HorrorProgression
@onready var level             : Node3D = $Level
@onready var monsters_root     : Node3D = $Monsters
@onready var player            : CharacterBody3D = $Player
@onready var controls_panel    : Control = $HUD/ControlsPanel
@onready var pause_screen      : Control = $HUD/PauseScreen

var _is_paused : bool = false

func _ready() -> void:
	# Register HUD with GameManager
	GameManager.register_hud(hud)

	# Wire HorrorProgression with environment nodes
	horror_prog.world_env = world_env
	horror_prog.sun_light = sun

	# Wire LevelGenerator with its dependencies
	level.horror_prog   = horror_prog
	level.door_scene    = preload("res://scenes/Door.tscn")
	level.monster_scene = preload("res://scenes/Monster.tscn")

	# Wire spawn callback: horror triggers call GameManager.set_horror_level,
	# which the LevelGenerator also listens to for spawning monsters.
	GameManager.horror_level_changed.connect(_on_horror_level_changed)

	# Fade the corner controls hint out after 6 s
	await get_tree().create_timer(6.0).timeout
	var tween := create_tween()
	tween.tween_property(controls_panel, "modulate:a", 0.0, 2.0)

func _on_horror_level_changed(level_num: int) -> void:
	level.spawn_monster(level_num)

func _toggle_pause() -> void:
	# Don't pause over a game-over / win screen
	if GameManager.is_game_over:
		return
	_is_paused = !_is_paused
	pause_screen.visible = _is_paused
	# Stop/resume player movement and input
	player.set_physics_process(!_is_paused)
	player.set_process_input(!_is_paused)
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if _is_paused else Input.MOUSE_MODE_CAPTURED
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		return
	# Restart shortcuts — work from game-over screen regardless of pause state
	if event.is_action_pressed("ui_accept") or \
			(event is InputEventKey and event.pressed and event.physical_keycode == KEY_R):
		if GameManager.is_game_over:
			_is_paused = false
			get_tree().reload_current_scene()
