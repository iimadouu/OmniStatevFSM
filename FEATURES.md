# OmniState Visual FSM — Features

## Persistence & Recovery

OmniState Visual FSM keeps your work with multiple recovery layers:

- Auto-save on exit
- Auto-load on startup
- Auto-recovery from generated `.gd` code when graph JSON is missing
- Two-way sync between visual editor and code files
- Smart merge preserves custom functions, exported properties, and helper code

## Visual Editor

- Node-based GraphEdit canvas
- Drag-and-drop state placement
- Visual transition connections
- Minimap and zoom controls
- Auto-arrange graph layout
- Context menus and keyboard shortcuts
- Resizable state nodes with color customization

## State Nodes

Each state includes:
- Basic tab: name, animation, initial state, behavior settings
- Enter tab: code that runs on state entry
- Update tab: frame-by-frame logic
- Exit tab: code that runs on state exit
- Animation dropdown if AnimationPlayer is available
- Syntax highlighted GDScript editor

## Transition System

### Four-tab transition editor
- Conditions
- Priority & Timing
- Advanced settings
- Debug

### Condition Modes
- **Simple Expression**: write any GDScript expression such as `distance_to_player < 10.0 and can_see_player`
- **Multiple Conditions (AND)**: require all conditions to be true before transition fires
- **Multiple Conditions (OR)**: require any condition to be true before transition fires
- **Custom Script**: write a full condition script that returns `true` or `false`

### Quick Presets
One-click conditions for fast setup:
- `blackboard.get("player_detected", false)`
- `blackboard.get("distance_to_player", 999) < 10.0`
- `blackboard.get("health", 100) < 30`
- `blackboard.get("can_see_player", false)`
- `blackboard.get("ammo", 0) == 0`
- `blackboard.get("state_timer", 0) > 5.0`
- `blackboard.get("in_cover", false)`
- `blackboard.get("enemies_nearby", 0) > 0`
- `blackboard.get("path_blocked", true) == false`

### Priority & Timing
- **Priority (0-100)**: lower values check first
- **Cooldown**: prevent transition flicker by blocking retries for a duration
- **Delay**: require the condition to remain true for a delay interval before transition executes

### Advanced Transition Options
- **Interrupt control**: choose whether the current state can be interrupted immediately
- **Animation blending**: smoothly blend animations between states with a configurable duration
- **Custom transition code**: run GDScript when the transition happens to trigger sounds, events, or blackboard updates

### Debug & Logging
- Enable per-transition logging
- Add custom labels for easier debugging
- Use debug colors to distinguish transitions in logs

### Generated Transition Behavior
- Transitions are gathered and filtered by condition validity
- Priority sorting picks the highest-priority valid transition
- Cooldowns are tracked per transition using keys stored in the blackboard
- Delays use temporary blackboard values to ensure the condition holds long enough

## Blackboard System

- Shared data storage accessible by every state
- Supports bool, int, float, String, Vector3, Array, Dictionary, Node, and custom values
- Add and edit variables through the visual blackboard editor
- Use helper functions from state code:
  - `owner.bb_set(key, value)`
  - `owner.bb_get(key, default)`
  - `owner.bb_has(key)`

### How it works
1. Add blackboard variables with default values in the plugin UI
2. Write values from state code in the `Update` or `Enter` tabs
3. Read values in conditions and transitions using `blackboard.get(...)`

### Common Usage Patterns
- Write detection results from a state:
```gdscript
owner.bb_set("distance_to_player", distance)
owner.bb_set("player_detected", distance < 20.0)
owner.bb_set("can_see_player", can_see)
```
- Read values in another state:
```gdscript
var distance = owner.bb_get("distance_to_player", 999.0)
var is_detected = owner.bb_get("player_detected", false)
```
- Use values in transition conditions:
```
blackboard.get("player_detected", false)
blackboard.get("distance_to_player", 999) < 5.0
blackboard.get("health", 100) < 30
```

### Quick Start
1. Add variables in the Blackboard panel
2. Write updates in state `Update` tabs
3. Use `blackboard.get()` inside transition conditions

### Pro Tips
- Always use a default value with `bb_get`
- Keep variable names descriptive
- Update runtime values every frame when needed
- Use the blackboard to share state such as `player_detected`, `distance_to_player`, `ammo`, `health`, and `in_cover`

## Animation Integration

- Auto-detect animations from the configured scene
- Per-state animation assignment
- AnimationPlayer playback support
- Smooth animation blending between transitions
- Speed and blend control

## State Templates

Built-in templates include:
- Idle
- Patrol
- Chase
- Attack
- Cover
- Flee

Each template offers a starting point for common AI behaviors.

## Code Generation

The plugin generates clean, ready-to-use code:

- Organized main FSM and per-state scripts
- Type hints and null-safety checks
- Helper functions and utility sections
- Clear regenerated vs custom code sections
- Debug integration and logging
- Smart merge support for custom functions

## Validation System

- State count validation
- Initial state check
- Connection validation
- Duplicate or missing state names
- Transition target verification
- Condition syntax validation
- Detailed error reporting

## Setup Wizard

- Base class selection (`CharacterBody3D`, `CharacterBody2D`, `Node3D`)
- Enemy scene and AnimationPlayer path
- Animation detection
- Persistent configuration saved for the project
- Validation for valid paths and settings

## Generated File Structure

```
res://ai_states/your_fsm_name/
├── your_fsm_name.gd
├── idle_state.gd
├── patrol_state.gd
├── chase_state.gd
├── attack_state.gd
└── ...
```

### Main FSM script includes
- State management and transition checking
- Blackboard dictionary and helper access
- Priority-based evaluation
- Cooldown and delay handling
- Animation blending support
- Debug logging and history tracking

### State scripts include
- `enter()`
- `update()`
- `exit()`
- Optional animation references

## Real-World Use Cases

- FPS enemy AI
- Stealth guard behavior
- Boss battles with phases
- NPC interactions and patrols
- Racing AI and obstacle avoidance
- RTS unit control
- Puzzle game AI
- Sports AI

## Troubleshooting

### Common issues

- **AnimationPlayer not found**
  - Verify the AnimationPlayer path
  - Confirm the node exists under the configured root

- **No initial state defined**
  - Mark one state as the initial state in the Basic tab

- **Transitions not working**
  - Verify blackboard values are set
  - Confirm transition conditions are valid

- **Player not found**
  - Add the player node to the `player` group
  - Or manually assign a player reference in code

- **States not switching**
  - Use `blackboard.get()` in transition conditions
  - Confirm state names are correct and transitions are connected

## Notes

- This plugin is designed for Godot 4.x
- The file generator creates scripts intended for game-ready AI
- Keep generated `.gd` files with custom code separated from regenerated sections

---

For sample state machines, see `EXAMPLES.md`.