# OmniState AI - Quick Start Guide

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

## Need Help?

- Check the full README.md for detailed documentation
- Examine the generated code - it's well-commented!
- Look at the state templates for examples
- Validate your state machine for errors

Happy AI building! 🤖
