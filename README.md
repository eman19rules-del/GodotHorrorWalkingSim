# Godot Horror Walking Simulator

A first-person horror walking simulator built in Godot 4. The player explores a procedurally furnished multi-room office complex, with the environment growing progressively darker and more threatening as they venture deeper. The goal is to find a key in the storage room and escape through the locked exit door without being caught by the monster.

---

## Project Structure

```
GodotHorrorWalkingSim/
├── README.md
├── .gitignore
└── HorrorOffice/                      ← Godot project root (open this in the editor)
    ├── project.godot                  ← Project config, input bindings, autoloads
    ├── scenes/
    │   ├── Main.tscn                  ← Root scene (wire everything together)
    │   ├── Player.tscn                ← First-person CharacterBody3D
    │   ├── Monster.tscn               ← Enemy AI CharacterBody3D
    │   └── Door.tscn                  ← Interactive door with pivot animation
    └── scripts/
        ├── Main.gd                    ← Entry point; wires all systems at startup
        ├── Player.gd                  ← Movement, stamina, flashlight, interaction
        ├── Monster.gd                 ← State-machine AI (patrol/chase/blocked)
        ├── Door.gd                    ← Toggle open/close with tween animation
        ├── GameManager.gd             ← Autoloaded singleton; global state + signals
        ├── LevelGenerator.gd          ← Procedural CSGBox3D level builder
        └── HorrorProgression.gd       ← Environment tween + light flicker system
```

---

## Engine & Configuration

- **Engine:** Godot 4.6, Forward Plus renderer
- **Window:** 1920×1080, stretch mode `canvas_items`
- **Main Scene:** `res://scenes/Main.tscn`
- **Autoload:** `GameManager` → `res://scripts/GameManager.gd` (global singleton)

### Input Bindings (defined in project.godot)

| Action | Key |
|---|---|
| move_forward | W |
| move_backward | S |
| move_left | A |
| move_right | D |
| sprint | Shift |
| interact | E |
| toggle_flashlight | F |
| pause | Esc |

---

## Architecture Overview

### Communication Pattern

Systems communicate through Godot signals and direct `GameManager` calls. The dependency graph is:

```
Main.gd
  ├── registers HUD nodes with GameManager
  ├── connects HorrorProgression → WorldEnvironment + DirectionalLight3D
  ├── injects door_scene + monster_scene into LevelGenerator
  └── connects GameManager.horror_level_changed → LevelGenerator.on_horror_changed

GameManager (autoload singleton)
  ├── signals: horror_level_changed(level), game_over_triggered, game_won_triggered
  └── updates HUD labels/bars directly (interact hint, stamina, vignette)

Player.gd  →  GameManager.update_stamina(), .set_interact_hint(), .player_died()
Monster.gd →  GameManager.set_horror_level() for speed/detection scaling
LevelGenerator.gd → spawns monsters + registers lights + places key pickup
HorrorProgression.gd → tweens WorldEnvironment + flickering ceiling lights
```

### Design Patterns

| Pattern | Where Used |
|---|---|
| Singleton | `GameManager` autoload |
| State Machine | `Monster.gd` — enum states: DORMANT, IDLE, WANDER, CHASE, BLOCKED |
| Observer / Signals | `horror_level_changed` broadcasts to monsters + progression system |
| Procedural Generation | `LevelGenerator.gd` builds the entire level at `_ready()` |
| Lazy Instantiation | Monsters instantiated only when horror level threshold is reached |

---

## Systems Reference

### GameManager.gd

Global state container. All scripts can reference it via the autoload name `GameManager`.

**State Variables:**

| Variable | Type | Description |
|---|---|---|
| `horror_level` | int | Current dread level (0–4) |
| `is_game_over` | bool | Blocks gameplay when true |
| `has_exit_key` | bool | Required to unlock the exit door |

**Key Methods:**

| Method | Description |
|---|---|
| `set_horror_level(level: int)` | Clamps to 0–4, emits `horror_level_changed` |
| `player_died()` | Sets game over, shows death screen, releases mouse |
| `trigger_win()` | Shows win screen |
| `pickup_key()` | Sets `has_exit_key = true`, shows hint for 2s |
| `set_interact_hint(text: String)` | Updates center-bottom interaction label |
| `update_stamina(pct: float)` | Updates stamina bar (0.0–1.0) |
| `set_vignette_intensity(t: float)` | Red vignette overlay (0.0–1.0) |

---

### Player.gd

Attached to `Player.tscn` (CharacterBody3D, collision layer 1).

**Key Constants:**

| Constant | Value | Notes |
|---|---|---|
| `WALK_SPEED` | 4.5 | units/s |
| `SPRINT_SPEED` | 8.5 | units/s |
| `STAMINA_MAX` | 100 | Drains 28/s sprinting, regens 16/s |
| `MOUSE_SENS` | 0.0022 | Radians per pixel |
| `GRAVITY` | 18.0 | Applied each physics frame |

**Features:**
- Head bob: vertical camera oscillation, 1.6× amplitude when sprinting
- Stamina: cannot begin sprinting below 25; recovers only when not holding sprint
- Flashlight: `SpotLight3D` on Camera3D, 18-unit range, warm color
- Interaction: `RayCast3D` detects objects within 2.8 units; calls `interact()` on hit node if it exists

**Important Nodes (inside Player.tscn):**

| Node | Path | Purpose |
|---|---|---|
| Head | `Head` | Camera pivot at eye level (y=1.62) |
| Camera | `Head/Camera3D` | FOV 80°, first-person view |
| Flashlight | `Head/Camera3D/Flashlight` | SpotLight3D, toggled with F |
| InteractRay | `Head/Camera3D/InteractRay` | RayCast3D for interaction detection |

---

### Monster.gd

Attached to `Monster.tscn` (CharacterBody3D, collision layer 4).

**State Machine:**

| State | Behavior |
|---|---|
| DORMANT | Invisible; activated by `activate()` call |
| IDLE | Stationary; timer counts down before wandering |
| WANDER | Moves to random point within 7 units of spawn |
| CHASE | Steers directly toward player at chase speed |
| BLOCKED | Stuck against obstacle; "pounds" for 2.8s then retries |

**Key Constants:**

| Constant | Value | Notes |
|---|---|---|
| `BASE_WALK_SPEED` | 2.2 | units/s when wandering |
| `BASE_CHASE_SPEED` | 4.8 | units/s when chasing |
| `BASE_DETECT_DIST` | 11.0 | units for line-of-sight detection |
| `LOSE_DIST_MULT` | 1.6 | Multiplier on detect dist to lose target |
| `ATTACK_RADIUS` | 1.1 | Kill player within this distance |

**Horror Level Scaling:**
- Chase speed increases by 0.6 units/s per horror level
- Detection distance increases with horror level
- Monsters are spawned inactive; `activate()` is called by LevelGenerator when horror threshold triggers

**Stuck Detection:** If monster position hasn't changed by 0.08 units in 0.6s during CHASE, enters BLOCKED state and wiggles before retrying.

---

### LevelGenerator.gd

Builds the entire level procedurally using `CSGBox3D` nodes at `_ready()`.

**Room Layout (top-down, approximate coordinates):**

```
[Room D: Storage]──HAD──[Room A: Your Office]──HAB──[Room B: Break Room]
  X:-5..5, Z:-17..-27    X:-5..5, Z:-5..5          X:17..27, Z:-5..5
                                                              │
                                                            HBC
                                                              │
                                                     [Room C: Exit]
                                                    X:17..27, Z:-17..-27
```

**Room Heights:** 3 units. Wall thickness: 0.22 units.

**Key Pickup:** Yellow glowing box at world position `(2.0, 0.9, -24.0)` inside Room D (Storage). Auto-picked up on contact via `Area3D`.

**Horror Trigger Zones (invisible Area3D regions):**

| Zone | Horror Level Set | Location |
|---|---|---|
| Hallway AB east | 1 | Between Room A and Room B |
| Break room entry | 2 | Entering Room B |
| North corridor / Storage north | 3 | Entering hallway to D or Room D |
| Exit room entry | 4 | Entering Room C |

**Monster Spawn Positions:**

| Horror Level | Count | Position |
|---|---|---|
| 3 | 1 | Break room (Room B) |
| 4 | 1 | Storage (Room D) |
| 4 | 1 | Exit room (Room C) |

**External Dependencies (injected by Main.gd):**

| Export Variable | Type | Set From |
|---|---|---|
| `door_scene` | PackedScene | `res://scenes/Door.tscn` |
| `monster_scene` | PackedScene | `res://scenes/Monster.tscn` |

---

### Door.gd

Attached to `Door.tscn` (Node3D root with `StaticBody3D` child).

**Exported Variables:**

| Variable | Default | Description |
|---|---|---|
| `is_locked` | false | Requires `GameManager.has_exit_key` to open |
| `open_angle` | -85.0 | Degrees door rotates (Y axis) to open |
| `swing_duration` | 0.45 | Seconds for open/close animation |

**Key Nodes:**
- `Pivot` (Node3D): Rotated by tween to swing door
- `DoorBody` (StaticBody3D): Wooden door mesh + brass handle
- `PromptArea` (Area3D): Triggers interaction hint when player is near

**Method:** `interact()` — toggled by player raycast hit. Checks lock state, then tweens `Pivot` rotation.

---

### HorrorProgression.gd

Listens to `GameManager.horror_level_changed` and tweens environment properties.

**Environment States by Horror Level:**

| Level | Ambient Energy | Ambient Color | Fog Density | Sun Energy | Vignette |
|---|---|---|---|---|---|
| 0 | 1.00 | Warm white | 0.000 | 0.6 | 0.00 |
| 1 | 0.65 | Warm amber | 0.008 | 0.3 | 0.10 |
| 2 | 0.30 | Orange-brown | 0.025 | 0.1 | 0.30 |
| 3 | 0.10 | Dark red | 0.055 | 0.0 | 0.55 |
| 4 | 0.04 | Deep red-black | 0.090 | 0.0 | 0.80 |

**Transition Durations:** 3.5s for levels 0–2; 2.0s for levels 3–4 (faster escalation).

**Light Flickering** (starts at horror level 1, registered lights come from LevelGenerator):

| Level | Intensity Range | Interval Range |
|---|---|---|
| 1 | 60–100% | 0.15–0.60s |
| 2 | 20–90% | 0.05–0.35s |
| 3 | 0–70% | 0.03–0.20s |
| 4 | 0–50% | 0.02–0.12s |

---

## Gameplay Loop

```
1. Player spawns in Room A (position: 0, 1, 3.5)
2. Explores office — entering zones triggers horror level increases
3. Horror level 3 → monster(s) spawn and begin hunting
4. Player must reach Room D (Storage) to find the yellow key
5. Player must reach Room C (Exit) with the key to unlock the exit door
6. Open exit door → GameManager.trigger_win() → "YOU ESCAPED"

Caught by monster → GameManager.player_died() → "YOU WERE CAUGHT"
Press R or Enter to restart in either end state.
```

---

## HUD / UI Nodes (inside Main.tscn → HUD CanvasLayer)

| Node | Purpose | Updated By |
|---|---|---|
| `InteractLabel` | "[E] Open door" prompts | `GameManager.set_interact_hint()` |
| `StaminaBar` | Bottom-left progress bar | `GameManager.update_stamina()` |
| `Vignette` | Red overlay, `modulate.a` | `GameManager.set_vignette_intensity()` |
| `DeathScreen` | "YOU WERE CAUGHT" overlay | `GameManager.player_died()` |
| `WinScreen` | "YOU ESCAPED" overlay | `GameManager.trigger_win()` |
| `Crosshair` | Center dot | Static |
| `ControlsPanel` | Tutorial hint | Fades after 6s in `Main.gd` |
| `PauseScreen` | Esc menu with controls | `Main.gd` pause toggle |

---

## Physics & Collision Layers

| Layer | Used By |
|---|---|
| 1 | Player |
| 4 | Monster |
| Default | Level geometry (CSGBox3D), door bodies |

---

## Adding Features — Common Tasks

**Add a new room:** Extend `LevelGenerator.gd`. Create wall/floor CSGBox3D nodes in `_build_room_x()` style methods. Register a new `Area3D` horror trigger and call `GameManager.set_horror_level()` in its `body_entered` signal.

**Add a new monster behavior/state:** Add an entry to the `State` enum in `Monster.gd` and handle it in `_physics_process()`. Call `set_horror_level()` on the monster from outside to scale it.

**Add ambient audio:** Connect to `GameManager.horror_level_changed` in a new `AudioManager.gd` autoload. Use `AudioStreamPlayer` nodes with `AudioStreamRandomizer` for variation.

**Add new interactive objects:** Give the node a method named `interact()`. The player's `InteractRay` calls `interact()` on any object it hits that has that method.

**Adjust difficulty:** Tune `BASE_DETECT_DIST`, `BASE_CHASE_SPEED`, and `ATTACK_RADIUS` in `Monster.gd`. Adjust stamina drain/regen in `Player.gd`.

---

## Known Constraints

- Level geometry uses `CSGBox3D` — good for prototyping, not ideal for large scenes. Consider converting to `MeshInstance3D` + `CollisionShape3D` for performance-critical work.
- No audio system is currently implemented. Horror atmosphere is visual only.
- No save system or persistent state between sessions.
- Restart reloads the current scene (`get_tree().reload_current_scene()`), which re-runs `LevelGenerator._ready()`.
