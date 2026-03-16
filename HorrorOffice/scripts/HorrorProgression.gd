## HorrorProgression.gd
## Receives advance_to(level) calls from room trigger Areas placed in the level.
## Smoothly transitions WorldEnvironment, flickering lights, and vignette.
extends Node

@export var world_env     : WorldEnvironment
@export var sun_light     : DirectionalLight3D

var current_level   : int   = 0
var flicker_lights  : Array = []
var flicker_timer   : float = 0.0
var flicker_on      : bool  = true

# ── Per-level environment configs ─────────────────────────────────────────────
# Each entry: ambient_energy, ambient_color, fog_enabled, fog_density,
#             fog_color, sun_energy, vignette_intensity
const LEVELS := [
	# 0 – Normal office: warm fluorescent
	{ "ae": 1.0,  "ac": Color(1.00, 0.95, 0.85), "fog": false, "fd": 0.000, "fc": Color(0,0,0),            "se": 0.6, "vig": 0.00 },
	# 1 – Unease: lights start dimming, faint warm fog
	{ "ae": 0.65, "ac": Color(0.90, 0.82, 0.65), "fog": true,  "fd": 0.008, "fc": Color(0.08,0.04,0.01),   "se": 0.3, "vig": 0.10 },
	# 2 – Creepy: much darker, sickly orange tint
	{ "ae": 0.30, "ac": Color(0.55, 0.28, 0.12), "fog": true,  "fd": 0.025, "fc": Color(0.10,0.03,0.00),   "se": 0.1, "vig": 0.30 },
	# 3 – Monster alert: near-black, deep red fog
	{ "ae": 0.10, "ac": Color(0.30, 0.06, 0.04), "fog": true,  "fd": 0.055, "fc": Color(0.08,0.00,0.00),   "se": 0.0, "vig": 0.55 },
	# 4 – Full horror: barely visible
	{ "ae": 0.04, "ac": Color(0.12, 0.00, 0.00), "fog": true,  "fd": 0.090, "fc": Color(0.05,0.00,0.00),   "se": 0.0, "vig": 0.80 },
]

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.horror_level_changed.connect(_on_horror_level_changed)

func _process(delta: float) -> void:
	if current_level >= 1:
		_tick_flicker(delta)

# ── Public ────────────────────────────────────────────────────────────────────
func register_flicker_light(light: Light3D) -> void:
	flicker_lights.append(light)

# ── Internal ──────────────────────────────────────────────────────────────────
func _on_horror_level_changed(level: int) -> void:
	current_level = level
	_apply_environment(level)

func _apply_environment(level: int) -> void:
	if not world_env or not world_env.environment:
		return
	var cfg : Dictionary = LEVELS[level]
	var env : Environment = world_env.environment
	var dur : float = 3.5 if level <= 2 else 2.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(env, "ambient_light_energy", cfg.ae,  dur)
	tw.tween_property(env, "ambient_light_color",  cfg.ac,  dur)
	tw.tween_property(env, "fog_density",          cfg.fd,  dur)
	tw.tween_property(env, "fog_light_color",      cfg.fc,  dur)
	if cfg.fog and not env.fog_enabled:
		env.fog_enabled = true

	if sun_light:
		tw.tween_property(sun_light, "light_energy", cfg.se, dur)

	# Vignette overlay via GameManager
	var tw2 := create_tween()
	tw2.tween_method(
		func(v: float) -> void: GameManager.set_vignette_intensity(v),
		GameManager.horror_level * 0.0,  # start from current
		cfg.vig,
		dur
	)

func _tick_flicker(delta: float) -> void:
	flicker_timer -= delta
	if flicker_timer > 0.0:
		return

	var intensity_min : float
	var intensity_max : float
	var next_delay    : float

	match current_level:
		1:
			intensity_min = 0.6; intensity_max = 1.0; next_delay = randf_range(0.15, 0.6)
		2:
			intensity_min = 0.2; intensity_max = 0.9; next_delay = randf_range(0.05, 0.35)
		3:
			intensity_min = 0.0; intensity_max = 0.7; next_delay = randf_range(0.03, 0.20)
		_: # 4
			intensity_min = 0.0; intensity_max = 0.5; next_delay = randf_range(0.02, 0.12)

	flicker_on   = !flicker_on
	flicker_timer = next_delay

	for light in flicker_lights:
		if is_instance_valid(light):
			light.light_energy = randf_range(intensity_min, intensity_max) if flicker_on else intensity_min
