# OmniState Visual FSM

**Version 1.0.1** | **Released: May 9, 2026** | **Godot 4.6.x**

OmniState Visual FSM is a visual state machine editor for Godot 4.x. It combines a simple node-based interface with a robust transition system, blackboard variables, animation blending, and automatic recovery features.

## Highlights

- Visual state machine editor with drag-and-drop workflow
- Transition system with cooldowns, delays, blending, and custom code
- Auto-save, auto-load, and recovery from generated code
- Sync between visual editor and generated .gd files
- Merge preserves custom functions and properties
- Blackboard variables for shared AI state
- Animation detection and playback integration
- State templates for faster behavior creation
- Clean code generation with type hints and organized structure

## Workflow: Don't Lose Your Work

OmniState Visual FSM adds multiple protection layers to keep your work safe and recoverable:

1. Auto-save on exit: graph data is stored in `res://ai_states/[fsm_name]/[fsm_name]_graph.json`
2. Auto-load on startup: the plugin restores your graph automatically
3. Auto-recovery from code: if JSON is missing, the graph rebuilds from `.gd` files
4. Two-way sync: edit generated code in your IDE, then sync back to the visual editor
5. Smart merge: custom helper functions and exported properties are preserved on regeneration

## Installation

### Method 1: Enable in this project
1. Open Godot
2. Go to `Project → Project Settings → Plugins`
3. Enable **OmniState Visual AI**
4. Open the **OmniState AI** panel at the bottom of the editor

### Method 2: Install in another project
1. Copy the entire `addons/omnistate_ai/` folder
2. Paste it into the target project’s `addons/` directory
3. Enable it in Project Settings → Plugins

## Quick Start

### Step 1: Enable & Configure
1. Enable the plugin
2. Click **⚙ Setup** in the OmniState AI panel
3. Configure:
   - Script Name: `enemy_ai`
   - Base Class: `CharacterBody3D`
   - Enemy Scene: `res://scenes/enemy.tscn` (optional)
   - AnimationPlayer Path: `AnimationPlayer`
4. Click **🔍 Detect Animations** (if you provided an enemy scene)
5. Click **OK**

### Step 2: Add Blackboard Variables
1. Click **📊 Blackboard**
2. Add variables such as:
   - `player_detected` (bool) = false
   - `distance_to_player` (float) = 999.0
   - `health` (int) = 100
   - `can_see_player` (bool) = false
3. Click **Close**

### Step 3: Create States
1. Use **Templates** to add states like **Patrol**, **Chase**, and **Attack**
2. Mark the initial state on the Basic tab

### Step 4: Add State Logic

Use the Enter/Update/Exit tabs inside each state for custom GDScript logic.

**Example: Patrol Update**
```gdscript
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    owner.bb_set("player_detected", distance < 20.0)
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position,
        owner.player.global_position
    )
    var result = space_state.intersect_ray(query)
    owner.bb_set("can_see_player", result.is_empty() or result.collider == owner.player)
```

### Step 5: Connect Transitions
1. Drag from one state’s output port to another state’s input port
2. Configure the transition in the 4-tab editor
3. Use conditions, priority, cooldown, delay, blending, and custom code to refine behavior

### Step 6: Generate and Run
1. Click **💾 Generate**
2. Attach the generated main FSM script to your enemy or AI node
3. Add your player to the `player` group or assign a player reference
4. Run the game

## What You'll See

- Initial patrol behavior
- Player detection and chase behavior
- Smooth animation transitions with blending
- Attack and fallback transitions
- State changes logged in console when enabled

## More Documentation

- `FEATURES.md` — full feature breakdown, including transition system and blackboard usage
- `EXAMPLES.md` — example state machines
- `CHANGELOG.md` — version history
- `RELEASE_NOTES_v1.0.1.md` — release notes

---

*This document was created by splitting the older full README into focused documentation files.*


---
### Please, If you find this tool helpful, consider helping me grow through my BEP20 USDT wallet: 0xee1e5f87180d91a11a7f4c57eb0a8ea4a40317f9**

![OmniState Preview](Donations.jpg)
---