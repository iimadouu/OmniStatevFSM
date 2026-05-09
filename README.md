# OmniState Visual FSM

**Version 1.0.0** | **Released: May 8, 2026** | **Godot 4.6.x**

A professional-grade visual state machine editor for Godot 4.x with **AAA-quality transition system**. Create sophisticated AI behaviors through an intuitive node-based interface. Specialized for FPS games but adaptable to any genre.

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue.svg)
![Version 1.0.0](https://img.shields.io/badge/Version-1.0.0-orange.svg)
![Quality: AAA](https://img.shields.io/badge/Quality-AAA-gold.svg)

---
** Please, If you find this tool helpful, consider helping me grow through my BEP20 USDT wallet: 0xee1e5f87180d91a11a7f4c57eb0a8ea4a40317f9**

![OmniState Preview](Donations.jpg)
---

## 🎯 **What is OmniState AI?**

OmniState AI transforms AI development from tedious coding into visual design. Create complex enemy behaviors, NPC interactions, and boss patterns through an intuitive graph editor with **professional-grade transition system** matching Unreal Engine 5/6 quality. The plugin generates clean, production-ready GDScript code with professional structure, type hints, and comprehensive error handling.

### **Key Highlights**

- ✅ **Visual State Machine Editor** - Node-based workflow with drag-and-drop
- ✅ **AAA Transition System** - 4-tab editor with cooldowns, delays, blending 
- ✅ **Professional Code Generation** - AAA-quality, well-structured scripts
- ✅ **Advanced Conditions** - 3 modes + 9 quick presets + syntax highlighting 
- ✅ **Priority System** - Control transition evaluation order (0-100)
- ✅ **Timing Control** - Cooldowns and delays for realistic behavior 
- ✅ **Animation Blending** - Smooth transitions between animations 
- ✅ **Debug System** - Per-transition logging with colors 
- ✅ **Blackboard Variables** - Shared data between states
- ✅ **Animation Integration** - Auto-detect and assign animations
- ✅ **State Templates** - Pre-built behaviors for rapid development
- ✅ **Zero Boilerplate** - Focus on logic, not structure

---

## 📦 **Installation**

### **Method 1: Direct Use (Assets Library)**


1. Go to **Project → Project Settings → Plugins**
2. Find "OmniState Visual AI"
3. Check the **Enable** checkbox
4. Look for the "OmniState AI" tab at the bottom of the editor

### **Method 2: Install in Another Project**
1. Copy the entire `addons/omnistate_ai/` folder
2. Paste into your target project's `addons/` directory
3. Enable in Project Settings → Plugins

---


## 🚀 **Quick Start (5 Minutes)**

### **Step 1: Enable & Configure**
1. Enable the plugin (see Installation above)
2. Click **⚙ Setup** in the OmniState AI panel
3. Configure:
   - **Script Name**: `enemy_ai`
   - **Base Class**: `CharacterBody3D`
   - **Enemy Scene**: `res://scenes/enemy.tscn` (optional)
   - **AnimationPlayer Path**: `AnimationPlayer`
4. Click **🔍 Detect Animations** (if you provided enemy scene)
5. Click **OK**

### **Step 2: Add Blackboard Variables**
1. Click **📊 Blackboard**
2. Add these variables:
   - `player_detected` (bool) = false
   - `distance_to_player` (float) = 999.0
   - `health` (int) = 100
   - `can_see_player` (bool) = false
3. Click **Close**

### **Step 3: Create States**
1. Click **📋 Templates** → **Patrol** (mark as Initial State in Basic tab)
2. Click **📋 Templates** → **Chase**
3. Click **📋 Templates** → **Attack**

### **Step 4: Add Logic**

**Patrol State - Update Tab:**
```gdscript
# Detect player
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    owner.bb_set("player_detected", distance < 20.0)
    
    # Check line of sight
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position,
        owner.player.global_position
    )
    var result = space_state.intersect_ray(query)
    owner.bb_set("can_see_player", result.is_empty() or result.collider == owner.player)
```

**Chase State - Update Tab:**
```gdscript
# Chase player
if owner.player:
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Update distance
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
```

**Attack State - Update Tab:**
```gdscript
# Attack player
if owner.player:
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Simple attack logic
    var attack_timer = owner.bb_get("attack_timer", 0.0)
    attack_timer += delta
    
    if attack_timer >= 1.0:  # Attack every second
        print("Attacking player!")
        # Add your attack logic here
        attack_timer = 0.0
    
    owner.bb_set("attack_timer", attack_timer)
    
    # Update distance
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
```

### **Step 5: Connect States with Advanced Transitions** 

#### **Patrol → Chase Transition**
1. Drag from **Patrol** (right blue dot) to **Chase** (left blue dot)
2. **Advanced Transition Editor** opens with 4 tabs:

**Conditions Tab:**
- Mode: Simple Expression
- Click preset: **"Player Detected"** (inserts condition)
- Or manually enter: `blackboard.get("player_detected", false) and blackboard.get("can_see_player", false)`

**Priority & Timing Tab:**
- Priority: `10`
- Enable Cooldown: ✅ (checked)
- Cooldown Duration: `1.0` seconds (prevents rapid switching)
- Enable Delay: ✅ (checked)
- Delay Duration: `0.3` seconds (reaction time)

**Advanced Tab:**
- Can Interrupt: ✅ (checked)
- Enable Animation Blend: ✅ (checked)
- Blend Duration: `0.2` seconds

**Debug Tab:**
- Enable Debug Logging: ✅ (checked)
- Debug Label: `"Player spotted - begin chase"`
- Debug Color: Yellow

3. Click **"Create Transition"**

#### **Chase → Attack Transition**
1. Drag from **Chase** to **Attack**

**Conditions Tab:**
- Click preset: **"In Range"**
- Modify to: `blackboard.get("distance_to_player", 999) < 5.0 and blackboard.get("can_see_player", false)`

**Priority & Timing Tab:**
- Priority: `5` (higher priority than returning to patrol)
- Enable Cooldown: ✅
- Cooldown Duration: `0.5` seconds

**Advanced Tab:**
- Can Interrupt: ✅
- Enable Animation Blend: ✅
- Blend Duration: `0.15` seconds
- Custom Code:
```gdscript
# Play attack sound
if owner.has_node("AudioPlayer"):
    owner.get_node("AudioPlayer").play()
```

**Debug Tab:**
- Enable Debug Logging: ✅
- Debug Label: `"Engaging target - attack range"`
- Debug Color: Red

2. Click **"Create Transition"**

#### **Attack → Chase Transition**
1. Drag from **Attack** to **Chase**

**Conditions Tab:**
- Expression: `blackboard.get("distance_to_player", 999) > 7.0`

**Priority & Timing Tab:**
- Priority: `15`
- Enable Cooldown: ✅
- Cooldown Duration: `1.0` seconds
- Enable Delay: ✅
- Delay Duration: `0.5` seconds (don't chase immediately)

**Advanced Tab:**
- Can Interrupt: ✅
- Enable Animation Blend: ✅
- Blend Duration: `0.2` seconds

**Debug Tab:**
- Enable Debug Logging: ✅
- Debug Label: `"Target out of range - resume chase"`
- Debug Color: Orange

2. Click **"Create Transition"**

#### **Chase → Patrol Transition** (Fallback)
1. Drag from **Chase** to **Patrol**

**Conditions Tab:**
- Expression: `not blackboard.get("player_detected", false) or not blackboard.get("can_see_player", false)`

**Priority & Timing Tab:**
- Priority: `50` (lower priority - fallback)
- Enable Delay: ✅
- Delay Duration: `3.0` seconds (give up after 3 seconds)

**Advanced Tab:**
- Can Interrupt: ✅
- Enable Animation Blend: ✅
- Blend Duration: `0.3` seconds

**Debug Tab:**
- Enable Debug Logging: ✅
- Debug Label: `"Lost player - return to patrol"`
- Debug Color: Gray

2. Click **"Create Transition"**

### **Step 6: Generate & Use**
1. Click **💾 Generate**
2. Check console for success message:
```
============================================================
🚀 GENERATING STATE MACHINE: enemy_ai
============================================================
✓ Generated professional main FSM with transitions and blackboard
✓ Generated state: patrol
✓ Generated state: chase
✓ Generated state: attack
============================================================
✓ GENERATION COMPLETE!
📁 Location: res://ai_states/enemy_ai/
📄 Main script: enemy_ai.gd
📄 State files: 3 files
============================================================
```

3. Find scripts in `res://ai_states/enemy_ai/`
4. Attach `enemy_ai.gd` to your enemy's root node
5. Add player to "player" group:
   - Select player node
   - Inspector → Node → Groups
   - Add "player" group
6. Run your game! 🎮

### **What You'll See:**
- Enemy patrols initially
- Detects player within 20 units
- Waits 0.3 seconds (reaction time)
- Smoothly transitions to chase (0.2s blend)
- Chases player with smooth movement
- Attacks when within 5 units
- Returns to chase if player moves away (7+ units)
- Returns to patrol if player lost for 3 seconds
- All transitions logged in console with colors!

---

## ✨ **Complete Feature List**

### **🎨 Visual Editor**
- **GraphEdit-based canvas** - Familiar node workflow
- **Drag-and-drop** - Intuitive state placement
- **Visual connections** - Draw transition arrows
- **Minimap** - Navigate large state machines
- **Auto-arrange** - Organize nodes automatically
- **Zoom controls** - Scale from overview to detail
- **Context menus** - Right-click for quick actions
- **Delete options** - Close button (×), Delete key, or right-click menu
- **Resizable nodes** - Adjust to fit content
- **Color-coded ports** - Blue connection points

### **📝 Advanced State Nodes**
- **Tabbed interface** with 4 tabs:
  - **Basic**: Name, animation, initial state checkbox, behaviors
  - **Enter**: Code when entering state
  - **Update**: Code every frame (_physics_process)
  - **Exit**: Code when leaving state
- **Animation dropdown** - Auto-populated from detection
- **Syntax highlighting** - GDScript code coloring in editors
- **Behavior system** - Add custom behavior functions
- **Color picker** - Customize node colors
- **Close button** - Easy deletion with × button

### **🔗 AAA Transition System** ⭐ v1.0.0

#### **4-Tab Advanced Editor**
Professional transition configuration matching Unreal Engine 5/6:

**Tab 1: Conditions**
- **3 Condition Modes:**
  - **Simple Expression** - Write any GDScript expression
  - **Multiple Conditions (AND)** - All must be true
  - **Multiple Conditions (OR)** - Any can be true
  
- **9 Quick Presets** - One-click insertion:
  1. Player Detected - `blackboard.get("player_detected", false)`
  2. In Range - `blackboard.get("distance_to_player", 999) < 10.0`
  3. Health Low - `blackboard.get("health", 100) < 30`
  4. Can See Player - `blackboard.get("can_see_player", false)`
  5. Ammo Empty - `blackboard.get("ammo", 0) == 0`
  6. Timer Elapsed - `blackboard.get("state_timer", 0) > 5.0`
  7. Is Covering - `blackboard.get("in_cover", false)`
  8. Enemy Nearby - `blackboard.get("enemies_nearby", 0) > 0`
  9. Path Clear - `blackboard.get("path_blocked", true) == false`

- **Syntax Highlighting** - Keywords, operators, comments
- **Code Editor** - Full GDScript support with 80 lines
- **Preset Buttons** - Grid layout for easy access
- **Expression Builder** - Visual condition builder for AND/OR modes

**Tab 2: Priority & Timing**
- **Priority System (0-100)**
  - 0 = Highest priority (checks first)
  - 100 = Lowest priority (checks last)
  - Automatic sorting and evaluation
  - Helpful hints for best practices
  
- **Cooldown System** 
  - Prevent rapid state switching
  - Duration: 0.1 - 60 seconds
  - Per-transition cooldown tracking
  - Prevents state "flickering"
  - Blackboard-based implementation
  
- **Delay System** 
  - Add deliberate transition delays
  - Duration: 0.1 - 10 seconds
  - Condition must remain true during delay
  - More realistic AI behavior
  - Reaction time simulation

**Tab 3: Advanced**
- **Interrupt Control** 
  - Can/Cannot interrupt current state
  - Useful for animations that must complete
  - Prevents jarring mid-action transitions
  - State-level control
  
- **Animation Blending** 
  - Smooth transitions between animations
  - Blend time: 0.0 - 2.0 seconds
  - Professional animation quality
  - No sudden animation pops
  - Automatic AnimationPlayer integration
  
- **Custom Transition Code** 
  - Execute GDScript when transitioning
  - Play sounds, set variables, trigger events
  - Full code editor with syntax highlighting
  - 100 lines of custom logic
  - Access to owner, blackboard, states

**Tab 4: Debug**
- **Debug Logging** 
  - Enable per-transition logging
  - Custom debug labels
  - Track transition execution
  - Console output with timestamps
  
- **Debug Colors** 
  - Assign colors to transitions
  - Color-coded console output
  - Visual identification in logs
  - Easier debugging of complex FSMs
  - 16 million color options

#### **Transition Features Summary**
- Multiple transitions per state (unlimited)
- Expression-based condition evaluation
- Priority-sorted checking
- Cooldown management
- Delay handling
- Interrupt control
- Animation blending
- Custom code execution
- Debug logging with colors
- Visual connection lines
- Easy deletion and modification

### **📊 Blackboard System**
- **Shared variables** - Data accessible by all states
- **Type support** - bool, int, float, String, Vector3
- **Visual editor** - Manage through UI (📊 button)
- **Helper functions** - bb_set(), bb_get(), bb_has()
- **Default values** - Set initial values
- **Runtime updates** - Modify during gameplay
- **Persistent data** - Survives state changes
- **Unlimited variables** - No restrictions

### **🎬 Animation Integration**
- **Auto-detection** - Scan enemy scene for animations
- **Dropdown selection** - Choose per state
- **Flexible paths** - Any AnimationPlayer location
- **Automatic playback** - Plays on state enter
- **Blend support** - Smooth animation transitions 
- **Speed control** - Adjust animation speed

### **📋 State Templates**
Pre-built behaviors for rapid development:
1. **Idle** - Waiting and looking around
2. **Patrol** - Following waypoints
3. **Chase** - Pursuing player
4. **Attack** - Combat behavior
5. **Cover** - Tactical positioning
6. **Flee** - Escape and retreat

Each template includes:
- Pre-configured state name
- Suggested animation
- Basic code structure
- Common behaviors
- Best practice patterns

### **💾 Professional Code Generation**
- **Well-structured** - Clean, organized output
- **Professional headers** - Project name, timestamp, metadata
- **Class names** - Proper GDScript conventions
- **Type hints** - Full type annotations
- **Docstrings** - Function documentation
- **Error handling** - Warnings and error messages
- **Helper functions** - Utility methods included
- **Organized sections** - Clear separation of concerns
- **Advanced transition logic** - Cooldowns, delays, blending 
- **Debug integration** - Logging code generation 

### **✅ Validation System**
- **State count** - Verify states exist
- **Initial state check** - Ensure one marked
- **Connection validation** - Check for disconnected states
- **Name validation** - Detect unnamed/duplicate states
- **Transition validation** - Verify targets exist
- **Condition syntax** - Basic expression checking
- **Comprehensive reporting** - Detailed error messages

### **⚙️ Setup Wizard**
- **Configuration dialog** - One-time setup
- **Base class selection** - CharacterBody3D, CharacterBody2D, Node3D
- **Scene paths** - Link enemy and player scenes
- **AnimationPlayer path** - Specify location
- **Animation detection** - 🔍 Auto-detect all animations
- **Persistent settings** - Configuration saved for session
- **Validation** - Checks for valid paths

---

## 📚 **Usage Examples**

### **Example 1: Advanced Tactical Shooter AI** 

Complete AI with cooldowns, delays, and blending for realistic behavior.

**States**: Idle → Patrol → Alert → Chase → Attack → Cover → Reload

#### **State Logic**

**Idle State - Update:**
```gdscript
# Look around randomly
var look_timer = owner.bb_get("look_timer", 0.0)
look_timer += delta

if look_timer >= 2.0:
    owner.rotate_y(randf_range(-PI/4, PI/4))
    look_timer = 0.0

owner.bb_set("look_timer", look_timer)

# Check for player
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    owner.bb_set("player_detected", distance < 25.0)
```

**Patrol State - Update:**
```gdscript
# Move between waypoints
var waypoints = owner.bb_get("waypoints", [])
if waypoints.is_empty():
    return

var current_wp = owner.bb_get("current_waypoint", 0)
var target = waypoints[current_wp]

var direction = (target - owner.global_position).normalized()
owner.velocity = direction * 3.0
owner.move_and_slide()

if owner.global_position.distance_to(target) < 1.0:
    current_wp = (current_wp + 1) % waypoints.size()
    owner.bb_set("current_waypoint", current_wp)

# Always check for player
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Line of sight check
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position + Vector3.UP,
        owner.player.global_position + Vector3.UP
    )
    var result = space_state.intersect_ray(query)
    var can_see = result.is_empty() or result.collider == owner.player
    owner.bb_set("can_see_player", can_see)
    owner.bb_set("player_detected", distance < 20.0 and can_see)
```

**Alert State - Enter:**
```gdscript
# Play alert animation and sound
if owner.animation_player:
    owner.animation_player.play("alert")

if owner.has_node("AudioPlayer"):
    owner.get_node("AudioPlayer").play()

# Set alert timestamp
owner.bb_set("alert_time", Time.get_ticks_msec() / 1000.0)
```

**Alert State - Update:**
```gdscript
# Look at last known player position
if owner.player:
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Update detection
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position + Vector3.UP,
        owner.player.global_position + Vector3.UP
    )
    var result = space_state.intersect_ray(query)
    var can_see = result.is_empty() or result.collider == owner.player
    owner.bb_set("can_see_player", can_see)
    owner.bb_set("alert_confirmed", can_see)
```

**Chase State - Update:**
```gdscript
# Chase player aggressively
if owner.player:
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 7.0
    owner.move_and_slide()
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Update distance
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Check line of sight
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position + Vector3.UP,
        owner.player.global_position + Vector3.UP
    )
    var result = space_state.intersect_ray(query)
    owner.bb_set("can_see_player", result.is_empty() or result.collider == owner.player)
    
    # Update health and ammo
    owner.bb_set("health_low", owner.bb_get("health", 100) < 40)
    owner.bb_set("ammo_low", owner.bb_get("ammo", 30) < 10)
```

**Attack State - Update:**
```gdscript
# Attack player
if owner.player:
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Attack logic
    var attack_timer = owner.bb_get("attack_timer", 0.0)
    attack_timer += delta
    
    if attack_timer >= 0.5:  # Attack every 0.5 seconds
        # Fire weapon
        print("BANG! Attacking player")
        
        # Reduce ammo
        var ammo = owner.bb_get("ammo", 30)
        ammo -= 1
        owner.bb_set("ammo", ammo)
        owner.bb_set("ammo_low", ammo < 10)
        
        attack_timer = 0.0
    
    owner.bb_set("attack_timer", attack_timer)
    
    # Update distance
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
```

**Cover State - Enter:**
```gdscript
# Find nearest cover
var cover_points = owner.get_tree().get_nodes_in_group("cover")
var nearest_cover = null
var nearest_distance = INF

for cover in cover_points:
    var dist = owner.global_position.distance_to(cover.global_position)
    if dist < nearest_distance:
        nearest_distance = dist
        nearest_cover = cover

if nearest_cover:
    owner.bb_set("cover_position", nearest_cover.global_position)
    owner.bb_set("in_cover", false)
```

**Cover State - Update:**
```gdscript
# Move to cover
var cover_pos = owner.bb_get("cover_position")
if not cover_pos:
    return

var in_cover = owner.bb_get("in_cover", false)

if not in_cover:
    # Move to cover
    var direction = (cover_pos - owner.global_position).normalized()
    owner.velocity = direction * 5.0
    owner.move_and_slide()
    
    if owner.global_position.distance_to(cover_pos) < 1.0:
        owner.bb_set("in_cover", true)
        owner.velocity = Vector3.ZERO
else:
    # In cover - wait for reload or health recovery
    pass
```

**Reload State - Update:**
```gdscript
# Reload weapon
var reload_timer = owner.bb_get("reload_timer", 0.0)
reload_timer += delta

if reload_timer >= 2.0:  # 2 second reload
    owner.bb_set("ammo", 30)  # Full ammo
    owner.bb_set("ammo_low", false)
    owner.bb_set("reload_complete", true)
    reload_timer = 0.0

owner.bb_set("reload_timer", reload_timer)
```

#### **Advanced Transitions**

**Idle → Patrol**
- **Condition**: `true` (always transition)
- **Priority**: 100 (lowest)
- **Delay**: 1.0 seconds
- **Blend**: 0.3 seconds
- **Debug**: "Starting patrol"

**Patrol → Alert**
- **Condition**: `blackboard.get("player_detected", false)`
- **Priority**: 10
- **Delay**: 0.3 seconds (reaction time)
- **Cooldown**: 2.0 seconds
- **Blend**: 0.2 seconds
- **Custom Code**: `owner.get_node("AudioPlayer").play()`
- **Debug**: "Player detected - going on alert" (Yellow)

**Alert → Chase**
- **Condition**: `blackboard.get("alert_confirmed", false) and blackboard.get("can_see_player", false)`
- **Priority**: 5
- **Delay**: 0.5 seconds (confirmation time)
- **Blend**: 0.2 seconds
- **Debug**: "Alert confirmed - begin chase" (Orange)

**Chase → Attack**
- **Condition**: `blackboard.get("distance_to_player", 999) < 8.0 and blackboard.get("can_see_player", false)`
- **Priority**: 0 (highest!)
- **Cooldown**: 0.5 seconds
- **Blend**: 0.15 seconds
- **Custom Code**: `print("Engaging target!")`
- **Debug**: "In attack range - engage!" (Red)

**Attack → Cover**
- **Condition**: `blackboard.get("health_low", false) or blackboard.get("ammo_low", false)`
- **Priority**: 1 (very high)
- **Delay**: 0.2 seconds
- **Blend**: 0.2 seconds
- **Debug**: "Taking cover - low health/ammo" (Purple)

**Cover → Reload**
- **Condition**: `blackboard.get("in_cover", false) and blackboard.get("ammo_low", false)`
- **Priority**: 5
- **Cannot Interrupt**: true (must reach cover first)
- **Blend**: 0.1 seconds
- **Custom Code**: `owner.bb_set("reload_timer", 0.0)`
- **Debug**: "Reloading weapon" (Cyan)

**Reload → Attack**
- **Condition**: `blackboard.get("reload_complete", false)`
- **Priority**: 10
- **Cooldown**: 1.0 seconds
- **Blend**: 0.2 seconds
- **Custom Code**: `owner.bb_set("reload_complete", false)`
- **Debug**: "Reload complete - re-engage" (Green)

**Attack → Chase**
- **Condition**: `blackboard.get("distance_to_player", 999) > 10.0`
- **Priority**: 20
- **Cooldown**: 1.0 seconds
- **Delay**: 0.5 seconds
- **Blend**: 0.2 seconds
- **Debug**: "Target out of range - chase" (Orange)

**Chase → Patrol**
- **Condition**: `not blackboard.get("can_see_player", false)`
- **Priority**: 50 (fallback)
- **Delay**: 5.0 seconds (give up after 5 seconds)
- **Blend**: 0.3 seconds
- **Debug**: "Lost player - return to patrol" (Gray)

---

### **Example 2: Boss Battle with Phases** 

Multi-phase boss with dramatic transitions and custom code.

**States**: Phase1 → Phase2 → Phase3 → Enraged

#### **Phase Transitions**

**Phase1 → Phase2**
- **Condition**: `blackboard.get("health", 100) < 70`
- **Priority**: 0
- **Cannot Interrupt**: true (finish current attack)
- **Delay**: 1.0 seconds (dramatic pause)
- **Blend**: 1.5 seconds (long dramatic blend)
- **Custom Code**:
```gdscript
# Phase 2 activation
print("PHASE 2 ACTIVATED!")
owner.get_node("AudioPlayer").play("phase2_music")
owner.get_node("ParticleEffects").emit()
owner.bb_set("attack_speed", 1.5)  # Faster attacks
owner.bb_set("damage_multiplier", 1.3)
```
- **Debug**: "=== PHASE 2 ACTIVATED ===" (Red)

**Phase2 → Phase3**
- **Condition**: `blackboard.get("health", 100) < 40`
- **Priority**: 0
- **Cannot Interrupt**: true
- **Delay**: 2.0 seconds (longer dramatic pause)
- **Blend**: 2.0 seconds
- **Custom Code**:
```gdscript
# Phase 3 - Final Form
print("FINAL PHASE!")
owner.get_node("AudioPlayer").play("phase3_music")
owner.spawn_minions()
owner.bb_set("attack_speed", 2.0)
owner.bb_set("damage_multiplier", 1.6)
owner.bb_set("can_summon", true)
```
- **Debug**: "=== PHASE 3 - FINAL FORM ===" (Purple)

**Any Phase → Enraged**
- **Condition**: `blackboard.get("health", 100) < 10`
- **Priority**: 0 (overrides everything!)
- **Can Interrupt**: true
- **Blend**: 0.5 seconds
- **Custom Code**:
```gdscript
# ENRAGED MODE
print("BOSS ENRAGED!")
owner.modulate = Color.RED
owner.bb_set("speed_multiplier", 2.5)
owner.bb_set("damage_multiplier", 2.0)
owner.bb_set("attack_speed", 3.0)
owner.get_node("AudioPlayer").play("enrage_roar")
```
- **Debug**: "!!! ENRAGED MODE !!!" (Orange)

---

### **Example 3: Stealth Game Guard** 

Realistic guard AI with investigation and alert states.

**States**: Patrol → Investigate → Search → Alert → Chase → Attack

#### **Key Transitions**

**Patrol → Investigate**
- **Condition**: `blackboard.get("heard_noise", false)`
- **Priority**: 15
- **Delay**: 0.5 seconds (reaction time)
- **Cooldown**: 3.0 seconds (don't investigate every sound)
- **Blend**: 0.3 seconds
- **Custom Code**: `owner.bb_set("investigation_point", owner.bb_get("noise_position"))`
- **Debug**: "Heard something - investigating" (Yellow)

**Investigate → Search**
- **Condition**: `blackboard.get("reached_investigation_point", false) and not blackboard.get("found_player", false)`
- **Priority**: 10
- **Delay**: 1.0 seconds (look around first)
- **Blend**: 0.2 seconds
- **Debug**: "Nothing here - searching area" (Orange)

**Search → Patrol**
- **Condition**: `blackboard.get("search_timer", 0) > 10.0`
- **Priority**: 50 (fallback)
- **Delay**: 2.0 seconds
- **Blend**: 0.4 seconds
- **Custom Code**: `owner.bb_set("search_timer", 0.0)`
- **Debug**: "Search complete - resume patrol" (Gray)

**Investigate → Alert**
- **Condition**: `blackboard.get("found_player", false)`
- **Priority**: 5
- **Can Interrupt**: true
- **Blend**: 0.1 seconds (fast reaction)
- **Custom Code**: `owner.get_node("AudioPlayer").play("alert_sound")`
- **Debug**: "PLAYER FOUND!" (Red)

---

## 📁 **Generated File Structure**

```
res://ai_states/your_fsm_name/
├── your_fsm_name.gd          # Main FSM controller (attach this!)
├── idle_state.gd             # Individual state files
├── patrol_state.gd
├── chase_state.gd
├── attack_state.gd
└── ...
```

### **Main FSM Script Features**
- State management system
- Blackboard dictionary with your variables
- Transition checking with priorities
- Expression evaluation for conditions
- Helper functions (bb_set, bb_get, force_state)
- State history tracking
- Player and navigation references
- Professional structure with sections

### **State Script Features**
- enter() function with your Enter code
- update() function with your Update code
- exit() function with your Exit code
- Animation constant (if selected)
- Proper indentation and formatting

---

## 🎮 **Real-World Use Cases**

1. **FPS Enemy AI** - Patrol, detect, chase, take cover, flank, suppress
2. **Stealth Game Guards** - Patrol routes, investigate sounds, alert states
3. **Boss Battles** - Phase transitions based on health/time
4. **NPC Behaviors** - Idle, wander, interact, flee, follow
5. **Racing AI** - Follow path, overtake, avoid obstacles, pit stop
6. **RTS Units** - Move, attack, retreat, gather, build
7. **Puzzle Game AI** - Pattern-based movement and reactions
8. **Sports Game AI** - Position, pass, shoot, defend

---

## 🔧 **Technical Details**

### **Performance**
- Minimal overhead per frame
- Efficient transition checking
- No unnecessary allocations
- Optimized for many AI entities
- Scalable to large state machines

### **Code Quality**
- Type hints for all variables and functions
- Null safety checks
- Error handling with push_error() and push_warning()
- Expression-based condition evaluation
- Priority-sorted transition checking
- State history for debugging
- Helper methods for common operations

### **Compatibility**
- **Godot**: 4.0, 4.1, 4.2, 4.3+
- **Platforms**: Windows, macOS, Linux, Web, Mobile
- **3D**: CharacterBody3D, Node3D
- **2D**: CharacterBody2D, Node2D
- **Version Control**: Git-friendly text files

---

## 💡 **Tips & Best Practices**

1. **Start Simple** - Begin with 2-3 states, test, then expand
2. **Use Blackboard** - Share data between states efficiently
3. **Validate Often** - Click ✓ Validate to catch errors early
4. **Name Clearly** - Use descriptive names like "patrol_alert" not "state1"
5. **Test Incrementally** - Generate and test after each major change
6. **Leverage Templates** - Use pre-built behaviors as starting points
7. **Use Priorities** - Control transition order when multiple conditions are true
8. **Comment Your Code** - Add comments in the code editors
9. **Check History** - Use state_history for debugging
10. **Read Generated Code** - It's meant to be read and customized!

---

## 🐛 **Troubleshooting**

### **"AnimationPlayer not found"**
- Check the AnimationPlayer path in Setup Wizard
- Verify the path is relative to your enemy node
- Common paths: `AnimationPlayer`, `Model/AnimationPlayer`

### **"No initial state defined"**
- Mark one state as "Initial State" in the Basic tab
- Only one state can be initial

### **"Transitions not working"**
- Verify conditions are being set in blackboard
- Use print() statements to debug condition values
- Check transition conditions in the dialog

### **"Player not found"**
- Add your player to the "player" group
- Or manually set: `player = get_node("/root/Player")`

### **"States not switching"**
- Ensure you're using blackboard.get() in conditions
- Check state names match exactly (case-sensitive)
- Verify initial state is marked

---

## 📖 **Documentation**

### **Complete Guides**
- **[TRANSITION_SYSTEM.md](TRANSITION_SYSTEM.md)** - Advanced transition system guide 
- **[BLACKBOARD_GUIDE.md](BLACKBOARD_GUIDE.md)** - Complete Blackboard tutorial
- **[QUICK_START_BLACKBOARD.md](QUICK_START_BLACKBOARD.md)** - 5-minute Blackboard guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and updates
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute getting started guide
- **[EXAMPLES.md](EXAMPLES.md)** - 4+ complete example state machines

### **v1.0.0** ⭐
- **[TRANSITION_SYSTEM.md](TRANSITION_SYSTEM.md)** - Complete guide to the AAA transition system
  - 4-tab editor walkthrough
  - All features explained with examples
  - Real-world use cases
  - Best practices and guidelines
  - Performance optimization tips
  - Comparison to Unreal Engine 5/6

### **Quick Reference**

#### **Transition System Features**
```
4-Tab Advanced Editor:
├── Conditions Tab
│   ├── 3 Modes (Simple, AND, OR)
│   ├── 9 Quick Presets
│   ├── Syntax Highlighting
│   └── Code Editor (80 lines)
│
├── Priority & Timing Tab
│   ├── Priority (0-100)
│   ├── Cooldown System (0.1-60s)
│   └── Delay System (0.1-10s)
│
├── Advanced Tab
│   ├── Interrupt Control
│   ├── Animation Blending (0-2s)
│   └── Custom Code (100 lines)
│
└── Debug Tab
    ├── Debug Logging
    ├── Custom Labels
    └── Color Picker

Key Features:
✅ Cooldowns - Prevent state flickering
✅ Delays - Realistic reaction time
✅ Interrupts - Protect animations
✅ Blending - Smooth transitions
✅ Custom Code - Unlimited flexibility
✅ Debug Logging - Track execution
✅ 9 Presets - One-click insertion
✅ Syntax Highlighting - Professional editors
```

#### **Priority Guidelines**
```
Priority Range | Use Case              | Examples
---------------|----------------------|---------------------------
0-10           | Emergency/Critical   | Flee, Die, Enrage
11-30          | Combat Actions       | Attack, Defend, Reload
31-60          | Movement             | Chase, Patrol, Wander
61-100         | Idle/Fallback        | Return to Patrol, Idle
```

#### **Cooldown Guidelines**
```
Duration  | Purpose                    | Example
----------|----------------------------|---------------------------
0.5-1s    | Prevent flickering         | Chase ↔ Attack
2-3s      | Tactical decisions         | Cover, Reload
5-10s     | Major state changes        | Alert → Patrol
10-30s    | Special abilities          | Boss special attacks
```

#### **Delay Guidelines**
```
Duration  | Purpose                    | Example
----------|----------------------------|---------------------------
0.1-0.3s  | Reaction time (human-like) | Patrol → Alert
0.5-1s    | Decision making            | Alert → Chase
1-2s      | Confirmation               | Investigate → Search
2-5s      | Dramatic pauses            | Boss phase transitions
5-10s     | Give up/timeout            | Search → Patrol
```

#### **Blackboard Helper Functions**
```gdscript
# Set value
owner.bb_set("key", value)

# Get value with default
var value = owner.bb_get("key", default_value)

# Check if exists
if owner.bb_has("key"):
    # Do something

# Common patterns
owner.bb_set("distance_to_player", distance)
owner.bb_set("player_detected", distance < 20.0)
owner.bb_set("can_see_player", raycast_result)
owner.bb_set("health_low", health < 30)
owner.bb_set("ammo_low", ammo < 10)
```

#### **State Access in Code**
```gdscript
# In state Update/Enter/Exit code, access owner:
owner.player              # Player reference (Node)
owner.animation_player    # AnimationPlayer
owner.blackboard          # Blackboard (Dictionary)
owner.navigation_agent    # NavigationAgent3D
owner.current_state       # Current state object
owner.previous_state      # Previous state object
owner.state_history       # Array of state names

# State control
owner.force_state("state_name")           # Force change
owner.change_state("state_name")          # Normal change
var current = owner.get_current_state_name()  # Get current
var previous = owner.get_previous_state()     # Get previous

# Blackboard shortcuts
owner.bb_set("key", value)
owner.bb_get("key", default)
owner.bb_has("key")
```

#### **Quick Preset Conditions**
```gdscript
# 1. Player Detected
blackboard.get("player_detected", false)

# 2. In Range
blackboard.get("distance_to_player", 999) < 10.0

# 3. Health Low
blackboard.get("health", 100) < 30

# 4. Can See Player
blackboard.get("can_see_player", false)

# 5. Ammo Empty
blackboard.get("ammo", 0) == 0

# 6. Timer Elapsed
blackboard.get("state_timer", 0) > 5.0

# 7. Is Covering
blackboard.get("in_cover", false)

# 8. Enemy Nearby
blackboard.get("enemies_nearby", 0) > 0

# 9. Path Clear
blackboard.get("path_blocked", true) == false
```

---

## 🗺️ **Roadmap**

### **Version 1.0.0** ✅ RELEASED!
- ✅ AAA-Quality Transition System (4-tab editor)
- ✅ Cooldown System (prevent flickering)
- ✅ Delay System (realistic reactions)
- ✅ Interrupt Control (protect animations)
- ✅ Animation Blending (smooth transitions)
- ✅ Custom Transition Code (unlimited flexibility)
- ✅ Debug Logging with Colors
- ✅ 9 Quick Presets
- ✅ Syntax Highlighting
- ✅ Enhanced Code Generation

### **Version 1.1** (Planned - Q3 2026)
- Save/Load state machine configurations (JSON format)
- Visual debugging mode (runtime state visualization)
- More FPS templates (Flank, Suppress, Reload, Grenade)
- Copy/paste states (with all settings)
- Undo/redo system (full history)
- State groups/folders (organize large FSMs)
- Transition visualization (arrows with labels)
- Performance profiler (track state execution time)

### **Version 1.2** (Planned - Q4 2026)
- Behavior tree integration (hybrid FSM + BT)
- Sub-state machines (nested states)
- Parallel states (multiple active states)
- State machine templates (save/load entire FSMs)
- Runtime state editor (modify in-game)
- Breakpoint system (pause on state change)
- Variable watchers (monitor blackboard in real-time)

### **Version 2.0** (Vision - 2027)
- Utility AI support (score-based decisions)
- Hierarchical state machines (parent/child states)
- Team coordination system (multi-agent FSMs)
- Machine learning integration (train AI behaviors)
- Visual scripting nodes (no-code state logic)
- Multiplayer synchronization (networked FSMs)
- Advanced pathfinding integration
- Perception system (sight, sound, smell)

---

## 🤝 **Contributing**

Contributions are welcome! Whether it's:
- Bug reports
- Feature requests
- Code contributions
- Documentation improvements
- Example state machines

---

## 📄 **License**

MIT License - Free to use in personal projects!

---

## 🙏 **Credits**

Created with ❤️ for the Godot community

**Special Thanks:**
- Godot Engine team for the amazing engine
- Community for feedback and support

---

## 📞 **Support**

- **Issues**: Report bugs and request features
- **Documentation**: Check the included .md files
- **Examples**: See EXAMPLES.md for complete implementations

---

## ⭐ **Show Your Support**

If you find OmniState AI useful:
- Star the repository
- Share with other developers
- Create and share your state machines
- Contribute improvements
- Report bugs and suggest features
- Donations 

---


**Version**: 1.0.0
*Documentation Version: 1.0.0*  
**Release Date**: May 8, 2026  
*Last Updated: May 9, 2026* 
**Godot Version**: 4.6.2 
**Status**: ✅ Production Ready

**Start building amazing AI now!** 🚀🎮

## Please note that the generated scripts may contain few syntax errors sometimes, but most of them a indentation errors
