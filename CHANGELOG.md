# Changelog

All notable changes to the OmniState Visual AI plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-05-08

### 🎉 Initial Release - Professional Visual State Machine Editor with AAA-Quality Transition System

First stable release of OmniState AI - A professional-grade visual state machine editor for Godot 4.x, specialized for FPS game AI but adaptable to any game genre. This release includes a comprehensive transition system that matches professional game engines like Unreal Engine 5/6!

### ✨ Core Features

#### Visual State Machine Editor
- **GraphEdit-based canvas** - Intuitive node-based workflow familiar to game developers
- **Drag-and-drop interface** - Create and position states effortlessly
- **Visual connections** - Draw transition arrows between states
- **Minimap navigation** - Overview of large state machines
- **Auto-arrange** - Automatically organize nodes for clarity
- **Zoom controls** - Scale view from overview to detail
- **Context menus** - Right-click for quick actions
- **Delete options** - Close button, Delete key, or right-click menu

#### Advanced State Nodes
- **Tabbed interface** with 4 tabs:
  - **Basic**: State name, animation selection, initial state checkbox
  - **Enter**: Code executed when entering the state
  - **Update**: Code executed every frame (_physics_process)
  - **Exit**: Code executed when leaving the state
- **Animation integration** - Dropdown populated with auto-detected animations
- **Resizable nodes** - Adjust size to fit your content
- **Color-coded ports** - Blue connection points for visual clarity

#### Professional Code Generation
- **Well-structured output** - Clean, organized, production-ready code
- **Professional headers** - Includes project name, timestamp, and metadata
- **Class names** - Proper GDScript class naming conventions
- **Organized sections** - Clear separation of concerns with comments
- **Type hints** - Full type annotations for better code quality
- **Docstrings** - Function documentation for clarity
- **Error handling** - Warnings and error messages for debugging
- **Helper functions** - Utility methods (bb_set, bb_get, force_state, etc.)

#### Advanced Transition System
- **Multiple transitions** - Create many transitions from a single state
- **Condition dialog** - Prompted when connecting states
- **Enhanced Priority System (0-100)**
  - 0 = Highest priority (checks first)
  - 100 = Lowest priority (checks last)
  - Automatic sorting and evaluation
  - Helpful hints and guidelines

- **3 Condition Modes:**
  - Simple Expression (write any GDScript)
  - Multiple Conditions (AND logic)
  - Multiple Conditions (OR logic)

- **9 Quick Presets:**
  - Player Detected
  - In Range
  - Health Low
  - Can See Player
  - Ammo Empty
  - Timer Elapsed
  - Is Covering
  - Enemy Nearby
  - Path Clear

- **Syntax Highlighting** in condition editors
- **One-Click Preset Insertion**

#### Cooldown & Delay System
- **Cooldown System** - Prevent rapid state switching
  - Duration: 0.1 - 60 seconds
  - Per-transition cooldown tracking
  - Prevents state "flickering"

- **Delay System** - Add deliberate transition delays
  - Duration: 0.1 - 10 seconds
  - Condition must remain true during delay
  - More realistic AI behavior

#### Advanced Control Features
- **Interrupt Control** - Can/Cannot interrupt current state
  - Useful for animations that must complete
  - Prevents jarring mid-action transitions

- **Animation Blending** - Smooth transitions between animations
  - Blend time: 0.0 - 2.0 seconds
  - Professional animation quality
  - No sudden animation pops

- **Custom Transition Code** - Execute GDScript when transitioning
  - Play sounds, set variables, trigger events
  - Full code editor with syntax highlighting
  - Unlimited flexibility

#### Debug Features
- **Debug Logging** - Enable per-transition logging
  - Custom debug labels
  - Track transition execution
  - Console output

- **Debug Colors** - Assign colors to transitions
  - Color-coded console output
  - Visual identification in logs
  - Easier debugging of complex FSMs

#### Blackboard System
- **Shared variables** - Data accessible by all states
- **Type support** - bool, int, float, String, Vector3
- **Visual editor** - Manage variables through UI (📊 Blackboard button)
- **Helper functions** - bb_set(), bb_get(), bb_has()
- **Default values** - Set initial values for variables
- **Runtime updates** - Modify values during gameplay

#### Setup Wizard
- **Configuration dialog** - One-time setup for your AI
- **Base class selection** - CharacterBody3D, CharacterBody2D, Node3D
- **Scene paths** - Link enemy and player scenes
- **AnimationPlayer path** - Specify location of AnimationPlayer node
- **Animation detection** - 🔍 Auto-detect all animations from enemy scene
- **Persistent settings** - Configuration saved for the session

#### State Templates
Pre-built templates for rapid development:
- **Idle** - Waiting and looking around
- **Patrol** - Following waypoints
- **Chase** - Pursuing the player
- **Attack** - Combat behavior
- **Cover** - Taking cover tactically
- **Flee** - Escape and retreat

#### Validation System
- **State count** - Verify states exist
- **Initial state check** - Ensure one state is marked as initial
- **Connection validation** - Check for disconnected states
- **Name validation** - Detect unnamed or duplicate states
- **Transition validation** - Verify transition targets exist

### 🔧 Code Generation Improvements
- **Enhanced Transition Checking**
  - Cooldown management code
  - Delay handling logic
  - Priority-based sorting
  - Interrupt checking
  - Blend time support

- **Professional Code Structure**
  - `_check_transitions()` with advanced logic
  - `_execute_transition()` helper function
  - Blackboard-based cooldown tracking
  - Time-based delay management
  - Debug logging integration

### 📊 Technical Improvements
- **Performance Optimizations**
  - Efficient priority sorting
  - Minimal memory overhead
  - Optimized cooldown tracking
  - No unnecessary allocations

- **Scalability**
  - Supports unlimited transitions per state
  - Handles complex FSMs (50+ states)
  - No performance degradation
  - Clean generated code

### 🐛 Bug Fixes
- Fixed GraphNode close button for Godot 4.3+
  - Changed from `show_close` property to manual button
  - Uses `get_titlebar_hbox()` for compatibility
  - Works across all Godot 4.x versions

- Fixed transition deletion
  - Properly removes transition data
  - Cleans up connections
  - Console logging for confirmation

### 📚 Documentation
- `README.md` - Complete setup and usage guide
- `TRANSITION_SYSTEM.md` - In-depth transition system documentation
- `EXAMPLES.md` - Real-world implementation examples
- `QUICKSTART.md` - Quick reference guide

### 📦 Generated File Structure

```
res://ai_states/your_fsm_name/
├── your_fsm_name.gd          # Main FSM controller (attach to enemy)
├── idle_state.gd             # Individual state files
├── patrol_state.gd
├── chase_state.gd
├── attack_state.gd
└── ...
```

### 🎯 Key Capabilities

- **Professional code quality** - AAA game studio level output
- **No syntax errors** - Smart generation prevents common mistakes
- **Blackboard integration** - Seamless data sharing between states
- **Transition logic** - Automatic condition checking with priorities
- **State history** - Track previous states for debugging
- **Animation support** - Automatic animation playback per state
- **Player detection** - Built-in player reference finding
- **Navigation support** - NavigationAgent3D integration ready
- **Extensible** - Easy to modify generated code
- **Well-documented** - Comprehensive inline comments

### 🚀 Quick Start (5 Minutes)

1. **Enable Plugin**
   ```
   Project → Project Settings → Plugins → Enable "OmniState Visual AI"
   ```

2. **Configure Setup**
   - Click **⚙ Setup**
   - Enter script name: `enemy_ai`
   - Select base class: `CharacterBody3D`
   - Enter enemy scene path: `res://scenes/enemy.tscn`
   - Click **🔍 Detect Animations**
   - Click **OK**

3. **Add Blackboard Variables**
   - Click **📊 Blackboard**
   - Add variable: `player_detected` (bool, false)
   - Add variable: `health` (int, 100)
   - Add variable: `distance_to_player` (float, 999.0)

4. **Create States**
   - Click **📋 Templates** → Select **Patrol**
   - Click **📋 Templates** → Select **Chase**
   - Click **📋 Templates** → Select **Attack**
   - Mark **Patrol** as Initial State (check the box in Basic tab)

5. **Configure State Logic**
   
   **Patrol State - Update Tab:**
   ```gdscript
   # Simple patrol behavior
   if owner.player:
       var distance = owner.global_position.distance_to(owner.player.global_position)
       owner.bb_set("distance_to_player", distance)
       owner.bb_set("player_detected", distance < 20.0)
   ```
   
   **Chase State - Update Tab:**
   ```gdscript
   # Chase the player
   if owner.player:
       var direction = (owner.player.global_position - owner.global_position).normalized()
       owner.velocity = direction * 6.0
       owner.move_and_slide()
       owner.look_at(owner.player.global_position, Vector3.UP)
   ```
   
   **Attack State - Update Tab:**
   ```gdscript
   # Attack the player
   if owner.player:
       owner.look_at(owner.player.global_position, Vector3.UP)
       # Add your attack logic here
       print("Attacking!")
   ```

6. **Connect States with Transitions**
   - Drag from **Patrol** (right blue dot) to **Chase** (left blue dot)
     - Condition: `blackboard.get("player_detected", false)`
     - Priority: 10
   - Drag from **Chase** to **Attack**
     - Condition: `blackboard.get("distance_to_player", 999) < 5.0`
     - Priority: 10
   - Drag from **Attack** to **Chase**
     - Condition: `blackboard.get("distance_to_player", 999) > 7.0`
     - Priority: 10

7. **Generate Scripts**
   - Click **💾 Generate**
   - Check console for success message
   - Find scripts in `res://ai_states/enemy_ai/`

8. **Use in Your Game**
   - Open your enemy scene
   - Attach `res://ai_states/enemy_ai/enemy_ai.gd` to root node
   - Add player to "player" group
   - Run game!

### 🎮 Real-World Use Cases

1. **FPS Enemy AI** - Patrol, detect, chase, take cover, flank
2. **Stealth Game Guards** - Patrol routes, investigate sounds, alert states
3. **Boss Battles** - Phase transitions based on health
4. **NPC Behaviors** - Idle, wander, interact, flee
5. **Racing AI** - Follow path, overtake, avoid obstacles
6. **RTS Units** - Move, attack, retreat, gather resources

### 🔧 Technical Details

**Generated Code Features:**
- Type hints for all variables and functions
- Null safety checks
- Error handling with push_error() and push_warning()
- Expression-based condition evaluation
- Priority-sorted transition checking
- State history for debugging
- Blackboard for data sharing
- Helper methods for common operations

**Performance:**
- Minimal overhead per frame
- Efficient transition checking
- No unnecessary allocations
- Optimized for many AI entities

### 🎓 Feature Highlights
Now matches professional game engines:
- ✅ Unreal Engine 5/6 State Machines
- ✅ Unity Animator Controller
- ✅ CryEngine AI System

---

## [Unreleased]

### Planned Features
- Save/Load state machine configurations
- Visual debugging mode with runtime state highlighting
- More FPS-specific templates (Flank, Suppress, Reload)
- Behavior tree integration
- Sub-state machines
- Performance profiling tools

---

**For detailed usage instructions, see [README.md](README.md)**  
**For transition system guide, see [TRANSITION_SYSTEM.md](TRANSITION_SYSTEM.md)**  
**For examples, see [EXAMPLES.md](EXAMPLES.md)**  
**For quick start, see [QUICKSTART.md](QUICKSTART.md)**
