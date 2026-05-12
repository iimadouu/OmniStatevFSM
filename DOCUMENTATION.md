# OmniState Visual FSM — Documentation

---

## Table of Contents

1. [The Main Panel](#1-the-main-panel)
2. [Toolbar — Row 1 (Actions)](#2-toolbar--row-1-actions)
3. [Toolbar — Row 2 (File Operations)](#3-toolbar--row-2-file-operations)
4. [The Graph Canvas](#4-the-graph-canvas)
5. [Setup Wizard](#5-setup-wizard)
6. [Blackboard Variables Panel](#6-blackboard-variables-panel)
7. [State Node](#7-state-node)
8. [Transition Dialog](#8-transition-dialog)
9. [Connection Info Panel](#9-connection-info-panel)
10. [Saving, Loading & Recovery](#10-saving-loading--recovery)

---

## 1. The Main Panel

The main panel is the bottom-panel tab labelled **OmniState AI**. It opens automatically when Godot loads the plugin. Everything you need to build, edit, and generate your FSM lives here.

The panel is split into three areas:

- **Two toolbar rows** at the top — all buttons and controls
- **The graph canvas** in the middle — where you place and connect state nodes
- **A status bar** at the bottom — shows hints and the current script name

---

## 2. Toolbar — Row 1 (Actions)

### ⚙ Setup
Opens the Setup Wizard. Use this to configure your FSM before you start building states. You can reopen it at any time to change settings.

### 📊 Blackboard
Opens the Blackboard Variables panel. This is where you define shared variables that all states can read and write.

### + State
Adds a new blank state node to the graph at a default position. You can also right-click anywhere on the canvas to add a state at a specific location.

### 📋 Template
Opens a dropdown of pre-built state templates (Idle, Patrol, Chase, Attack, Cover, Flee, etc.). Selecting one creates a state node pre-filled with typical logic for that behavior.

### → Transition
Opens the Transition Dialog to manually create a transition between two states. You choose the From state, the To state, and all transition settings. You can also create transitions by dragging a connection line directly between two nodes on the canvas.

### 📐 Arrange
Automatically repositions all state nodes in a clean hierarchical layout, starting from the initial state and flowing downward. If no initial state is set, it falls back to a grid layout.

### 🔍+ / 🔍- / 🔍 Reset
Zoom in, zoom out, and reset zoom to 100%.

### ⊡ Fit
Zooms and pans the canvas so all state nodes are visible at once.

### ✓ Validate
Runs a validation check on your FSM and shows a report. It checks for:
- At least one state exists
- Exactly one initial state is marked
- No states are disconnected from the graph
- No duplicate or missing state names
- All transition targets exist

### 🗺
Toggles the minimap in the bottom-right corner of the canvas on and off.

### 🔗 Info
Opens the Connection Info Panel, which lists every transition in the entire FSM with its condition, priority, and edit/highlight buttons.

---

## 3. Toolbar — Row 2 (File Operations)

### 💾 Save Graph
Saves the entire visual graph to a JSON file at:
`res://ai_states/[script_name]/[script_name]_graph.json`

This file stores everything: state positions, all code, all transitions, blackboard variables, and wizard settings. The graph also auto-saves every 30 seconds if changes are detected, and saves automatically when you close Godot.

### ⚙ Generate Code
Saves the graph and then generates all GDScript files into `res://ai_states/[script_name]/`. This produces the main FSM controller and one state file per state node. After generating, attach the main script to your enemy scene.

### 🔍 Auto-Recover
Scans the `res://ai_states/` folder for previously generated FSM files and reconstructs the visual graph from them. Useful if the graph JSON was lost or deleted — as long as the generated `.gd` files exist, the graph can be rebuilt.

### 🔄 Sync from Files
Imports the `enter()`, `update()`, and `exit()` function bodies from the generated state files back into the visual editor. Use this if you edited the generated files directly in your IDE and want those changes reflected in the graph.

### Script name display
Shows the current FSM script name (e.g. `enemy_fsm`) in light blue. This updates whenever you change the name in the Setup Wizard.

---

## 4. The Graph Canvas

The canvas is a free-form workspace where you place and connect state nodes.

**Navigation:**
- Scroll wheel to zoom
- Middle-click drag (or right-click drag) to pan
- The minimap in the corner shows a bird's-eye view

**Creating connections:**
- Hover over a state node until the connection port (colored dot) appears on the edge
- Click and drag from one port to another to draw a connection
- When you release, the Transition Dialog opens automatically so you can set the condition and settings
- If a connection already exists between those two nodes, a duplicate warning appears instead

**Deleting:**
- Select a node and press Delete, or click the × button in the node's title bar
- Right-click a node for a context menu with delete and other options
- To remove a connection, right-click the line and drag it away from the port

**Right-click on empty canvas:**
Opens a quick-action menu to add a state at that position, add an initial state, add from a template, arrange all nodes, fit the view, or clear everything.

---

## 5. Setup Wizard

Opened via the **⚙ Setup** button. Configure this before building your FSM.

### Main AI Script Name
The name used for all generated files and folders. For example, `enemy_fsm` produces `res://ai_states/enemy_fsm/enemy_fsm.gd`. Use snake_case.

### Base Class Type
The Godot class your enemy extends. Choose from:
- `CharacterBody3D` — standard 3D character with physics
- `CharacterBody2D` — standard 2D character with physics
- `Node3D` — 3D object without built-in physics
- `Node2D` — 2D object without built-in physics
- `Node` — generic, no physics

### Enemy Scene Path
Path to your enemy's `.tscn` file. Used to detect animations. Click **Browse** to open a file picker. If auto-detect is enabled, animations are scanned immediately when you select a scene.

### Player Scene Path
Path to your player's `.tscn` file. Optional — used as a reference for the generated FSM.

### AnimationPlayer Node Path
The path to the `AnimationPlayer` node inside your enemy scene, relative to the scene root. Default is `AnimationPlayer`. If your AnimationPlayer is nested (e.g. inside a `Model` node), enter the full path like `Model/AnimationPlayer`.

### Auto-detect animations checkbox
When enabled, animations are automatically scanned from the enemy scene whenever the scene path changes.

### Detect Animations Now
Manually triggers animation detection from the currently entered enemy scene path. The detected animations become available in the Animation dropdown on every state node.

---

## 6. Blackboard Variables Panel

Opened via the **📊 Blackboard** button. The blackboard is a shared dictionary of variables that every state can read and write at runtime. Think of it as the AI's working memory.

### Variable list
Shows all currently defined variables with their name, type, and default value. Each row has a × button to remove that variable.

### Adding a variable
At the bottom of the panel:
1. Enter a variable name (snake_case recommended, e.g. `player_detected`)
2. Choose a type from the dropdown: `bool`, `int`, `float`, `String`, `Vector2`, `Vector3`, `Array`, `Dictionary`, or `Node`
3. Optionally enter a default value in the text field
4. Click **+ Add**

Supported types and their defaults if left blank:
- `bool` → `false`
- `int` → `0`
- `float` → `0.0`
- `String` → empty string
- `Vector2` → `(0, 0)`
- `Vector3` → `(0, 0, 0)`
- `Array` → empty array
- `Dictionary` → empty dictionary
- `Node` → `null`

Blackboard variables are saved with the graph and restored when the graph loads.

---

## 7. State Node

Each state in your FSM is represented by a resizable, draggable node on the canvas. Every node has a title bar and five tabs.

### Title Bar
- **State name** — displayed as the node title. Updates live as you type in the Basic tab.
- **→N badge** — shows the number of outgoing transitions. Green when transitions exist, gray when none.
- **× button** — deletes the state node.

### Tab 1 — Basic

**State Name**
The name of this state. Used as the state identifier throughout the FSM. Keep it lowercase and descriptive (e.g. `idle`, `patrol`, `cover_stand`).

**Initial State checkbox**
Mark exactly one state as the initial state. This is where the FSM starts when the enemy spawns. The node gets a yellow tint when marked as initial.

**Node Color**
A color picker to visually distinguish states on the canvas. The color also applies to the connection ports on the node.

**Animation**
A dropdown populated with all animations detected from your enemy scene. The selected animation plays automatically when this state is entered. Select `(None)` if you want to handle animation manually in the Enter tab.

**Set animation dynamically checkbox**
When enabled, the Animation dropdown is disabled. Use this when you need to choose the animation at runtime inside the Enter tab based on conditions.

**Behaviors**
A list of named behavior flags for this state (e.g. `is_covering`, `can_attack`). These are informational tags that can be referenced in transition conditions. Click **+ Add Behavior** to add one, and the × button next to each to remove it.

### Tab 2 — Enter

GDScript that runs once when the FSM transitions into this state. Use it to:
- Set the animation
- Reset timers or counters
- Set blackboard variables
- Configure navigation targets

The editor has syntax highlighting for GDScript keywords, types, comments, and strings.

### Tab 3 — Update

GDScript that runs every physics frame while this state is active. Use it to:
- Move the character
- Scan for the player
- Update blackboard variables
- Check conditions and set flags

The `delta` variable is available here for frame-rate-independent movement.

### Tab 4 — Exit

GDScript that runs once when the FSM leaves this state. Use it to:
- Clean up flags
- Reset variables
- Stop sounds or effects

### Tab 5 — Transitions

Lists all outgoing transitions from this state. Each row shows:
- The target state name
- The condition expression
- Priority, delay, and cooldown hints in brackets (e.g. `[P:5] [D:0.3s]`)
- A **✏ edit button** — opens the full Transition Dialog pre-filled with this transition's data so you can change any setting
- A **× remove button** — deletes this transition

---

## 8. Transition Dialog

Opens when you:
- Click **→ Transition** in the toolbar
- Drag a connection between two nodes on the canvas
- Click the **✏ edit button** on an existing transition

The dialog has four sections.

### From / To
Dropdowns to select the source and destination states. The first option in both dropdowns is **[ANY]**, which means the transition applies to every state in the FSM. Use `[ANY] → death` with priority 0 to create a universal death transition that fires from any state.

### Condition
A text field for the transition condition expression. The condition is evaluated every frame while the source state is active. When it becomes true, the transition fires (subject to delay and cooldown).

**Quick presets** — a dropdown of common conditions you can insert with one click:
- `player_detected`
- `player_in_range`
- `health_low`
- `can_see_player`
- `is_under_fire`
- `ammo_empty`
- `timer_expired`
- `is_covering`
- `enemy_nearby`
- `path_clear`

You can write any valid GDScript expression. Examples:
- `blackboard.get("health", 100) < 30`
- `blackboard.get("player_detected", false) and blackboard.get("player_visible", false)`
- `not blackboard.get("is_reloading", false)`

### Priority & Timing

**Priority (0–100)**
Controls which transition fires first when multiple conditions are true at the same time. Lower number = higher priority. Priority 0 is the highest and should be reserved for critical transitions like death. Default is 10.

**Delay (0–10 seconds)**
The condition must remain true for this many seconds before the transition fires. The timer resets if the condition becomes false before the delay expires. Use this to prevent flickering between states.

**Cooldown (0–60 seconds)**
The minimum time that must pass after this transition fires before it can fire again. Useful for flanking, grenade throws, or any behavior you don't want to repeat too quickly.

### Advanced

**Can Interrupt**
When checked (default), this transition can fire at any time while the condition is true. When unchecked, the current state's animation must finish playing before the transition is allowed. Use this to protect animations that must complete (e.g. a reload or death animation).

**Anim Blend (0–2 seconds)**
Smooth crossfade time between the outgoing and incoming state animations. 0 means an instant cut.

**Custom Code on Transition**
Optional GDScript that executes at the exact moment this transition fires, before the new state's Enter code runs. Use it for one-off effects like playing a sound, spawning a particle, or broadcasting an alert to nearby allies.

### Debug

**Log this transition**
When enabled, a message is printed to the Godot console every time this transition fires. Useful for tracing FSM behavior during testing.

**Debug label**
An optional custom label for the log message. If left blank, the log shows `[FSM] idle → patrol`. If you enter a label, it shows that text instead.

---

## 9. Connection Info Panel

Opened via the **🔗 Info** button. Shows every transition in the entire FSM in one scrollable list, grouped by source state.

Each transition row shows:
- The target state
- The condition expression
- A **👁 button** — highlights the connection line on the canvas and scrolls to show both nodes
- A **✏ button** — closes the info panel and opens the Transition Dialog pre-filled with that transition's data for editing

---

## 10. Saving, Loading & Recovery

### Auto-save
The graph saves automatically every 30 seconds if any changes have been made. It also saves when you close Godot. You never need to manually save unless you want to force an immediate save.

### Manual save
Click **💾 Save Graph** at any time. A confirmation message appears briefly.

### What gets saved
The graph JSON stores everything:
- All state nodes with their positions, colors, and all code (enter, update, exit)
- All transitions with every setting (condition, priority, delay, cooldown, interrupt, blend, custom code, debug)
- All blackboard variables
- Setup Wizard settings (script name, base class, scene paths, animation player path, detected animations)
- All visual connections between nodes

### Loading
The graph loads automatically when Godot opens and the plugin initializes. It looks for the JSON file at `res://ai_states/[script_name]/[script_name]_graph.json`.

### Auto-Recovery
If the graph JSON is missing but generated `.gd` files exist, clicking **🔍 Auto-Recover** reconstructs the visual graph from the generated code. It recovers state names, enter/update/exit code, animations, and transitions. Node positions and colors are not recoverable from code — nodes are placed in a grid layout after recovery.

### Sync from Files
If you edited the generated state files directly in your IDE, click **🔄 Sync from Files** to pull those changes back into the visual editor. It extracts the `enter()`, `update()`, and `exit()` function bodies from each state file and updates the corresponding code tabs in the graph. A confirmation dialog warns you before overwriting.

---

## Quick Reference — Toolbar Buttons

| Button | Action |
|---|---|
| ⚙ Setup | Configure FSM settings and detect animations |
| 📊 Blackboard | Manage shared AI variables |
| + State | Add a blank state node |
| 📋 Template | Add a pre-built state |
| → Transition | Create a transition between states |
| 📐 Arrange | Auto-layout all nodes |
| 🔍+ / 🔍- | Zoom in / out |
| 🔍 Reset | Reset zoom to 100% |
| ⊡ Fit | Fit all nodes in view |
| ✓ Validate | Check FSM for errors |
| 🗺 | Toggle minimap |
| 🔗 Info | View and edit all transitions |
| 💾 Save Graph | Save the visual graph |
| ⚙ Generate Code | Save and generate GDScript files |
| 🔍 Auto-Recover | Rebuild graph from generated files |
| 🔄 Sync from Files | Import code edits from generated files |
