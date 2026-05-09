# 📊 Blackboard System - Complete Guide

## 🤔 What is the Blackboard?

The **Blackboard** is a shared memory space where all your states can read and write data. Think of it as a **bulletin board** where states post information for other states to see.

### **Why Use It?**
- ✅ Share data between states (player position, health, etc.)
- ✅ Make decisions based on shared information
- ✅ Avoid duplicating code across states
- ✅ Create smart, reactive AI

---

## 🎯 How It Works

### **Simple Analogy:**
```
Imagine a whiteboard in an office:
- Patrol state writes: "Player detected = true"
- Chase state reads: "Is player detected? Yes!"
- Attack state writes: "Ammo = 5"
- Reload state reads: "Ammo < 10? Time to reload!"
```

### **In Your AI:**
```
State 1 (Patrol):
  → Writes: "player_detected = true"
  → Writes: "distance_to_player = 8.5"

State 2 (Chase):
  → Reads: "Is player_detected true? Yes!"
  → Reads: "Is distance < 10? Yes!"
  → Decision: Keep chasing!

State 3 (Attack):
  → Reads: "Is distance < 5? Yes!"
  → Transition to Attack!
```

---

## 📝 Step-by-Step Tutorial

### **Step 1: Add Blackboard Variables**

1. Click **📊 Blackboard** button in the plugin
2. Add variables you need:

**Example for FPS Enemy:**
```
Variable Name: player_detected
Type: bool
Default Value: false

Variable Name: distance_to_player
Type: float
Default Value: 999.0

Variable Name: health
Type: int
Default Value: 100

Variable Name: ammo
Type: int
Default Value: 30

Variable Name: can_see_player
Type: bool
Default Value: false

Variable Name: in_cover
Type: bool
Default Value: false

Variable Name: last_known_position
Type: Vector3
Default Value: (0, 0, 0)
```

### **Step 2: Write to Blackboard in States**

In your state's **Update** tab, write values:

#### **Patrol State - Update Tab:**
```gdscript
# Check if player is nearby
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    
    # WRITE to blackboard
    owner.bb_set("distance_to_player", distance)
    
    # Check if we can see player
    var can_see = _check_line_of_sight()
    owner.bb_set("can_see_player", can_see)
    
    # Detect player if close and visible
    if distance < 20.0 and can_see:
        owner.bb_set("player_detected", true)
        owner.bb_set("last_known_position", owner.player.global_position)

func _check_line_of_sight() -> bool:
    # Your raycast logic here
    return true
```

#### **Chase State - Update Tab:**
```gdscript
# READ from blackboard
var distance = owner.bb_get("distance_to_player", 999.0)
var last_pos = owner.bb_get("last_known_position", Vector3.ZERO)

# Move towards player
if owner.player:
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
    
    # UPDATE blackboard
    owner.bb_set("distance_to_player", distance)
else:
    # Move to last known position
    var direction = (last_pos - owner.global_position).normalized()
    owner.velocity = direction * 4.0
    owner.move_and_slide()
```

#### **Attack State - Update Tab:**
```gdscript
# READ from blackboard
var ammo = owner.bb_get("ammo", 0)
var distance = owner.bb_get("distance_to_player", 999.0)

if ammo > 0 and distance < 10.0:
    # Attack!
    _fire_weapon()
    
    # UPDATE ammo
    ammo -= 1
    owner.bb_set("ammo", ammo)
else:
    # Need to reload or player too far
    owner.bb_set("needs_reload", true)
```

#### **Cover State - Update Tab:**
```gdscript
# Find cover
if not owner.bb_get("in_cover", false):
    var cover_pos = _find_nearest_cover()
    if cover_pos:
        owner.bb_set("cover_position", cover_pos)
        _move_to_cover(cover_pos)
        
        # Check if reached cover
        if owner.global_position.distance_to(cover_pos) < 1.0:
            owner.bb_set("in_cover", true)
```

### **Step 3: Use in Transitions**

When connecting states, use blackboard values in conditions:

#### **Patrol → Chase Transition:**
```
Condition: blackboard.get("player_detected", false)
```

#### **Chase → Attack Transition:**
```
Condition: blackboard.get("distance_to_player", 999) < 5.0
```

#### **Attack → Reload Transition:**
```
Condition: blackboard.get("ammo", 30) < 5
```

#### **Any → Cover Transition:**
```
Condition: blackboard.get("health", 100) < 30 and not blackboard.get("in_cover", false)
```

---

## 🎮 Complete Example: FPS Enemy AI

### **Setup:**

**Blackboard Variables:**
```
player_detected: bool = false
distance_to_player: float = 999.0
health: int = 100
ammo: int = 30
can_see_player: bool = false
in_cover: bool = false
last_known_position: Vector3 = (0,0,0)
needs_reload: bool = false
```

### **State 1: Patrol**

**Update Tab:**
```gdscript
# Patrol logic
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Raycast to check visibility
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position,
        owner.player.global_position
    )
    var result = space_state.intersect_ray(query)
    
    var can_see = result.is_empty() or result.collider == owner.player
    owner.bb_set("can_see_player", can_see)
    
    # Detect player
    if distance < 20.0 and can_see:
        owner.bb_set("player_detected", true)
        owner.bb_set("last_known_position", owner.player.global_position)
        print("Player detected!")
```

**Transition to Chase:**
```
Condition: blackboard.get("player_detected", false)
Priority: 10
```

### **State 2: Chase**

**Enter Tab:**
```gdscript
print("Chasing player!")
owner.bb_set("player_detected", true)
```

**Update Tab:**
```gdscript
# Update distance
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Chase player
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Update last known position
    owner.bb_set("last_known_position", owner.player.global_position)
```

**Transition to Attack:**
```
Condition: blackboard.get("distance_to_player", 999) < 5.0 and blackboard.get("can_see_player", false)
Priority: 5
```

**Transition to Cover:**
```
Condition: blackboard.get("health", 100) < 30
Priority: 1 (higher priority!)
```

### **State 3: Attack**

**Update Tab:**
```gdscript
# Look at player
if owner.player:
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Check ammo
    var ammo = owner.bb_get("ammo", 0)
    
    if ammo > 0:
        # Fire weapon (every 0.5 seconds)
        var time = Time.get_ticks_msec() / 1000.0
        var last_shot = owner.bb_get("last_shot_time", 0.0)
        
        if time - last_shot > 0.5:
            print("BANG! Ammo: ", ammo)
            owner.bb_set("ammo", ammo - 1)
            owner.bb_set("last_shot_time", time)
            
            # Deal damage to player
            if owner.player.has_method("take_damage"):
                owner.player.take_damage(10)
    else:
        owner.bb_set("needs_reload", true)
```

**Transition to Reload:**
```
Condition: blackboard.get("ammo", 30) < 5 or blackboard.get("needs_reload", false)
Priority: 5
```

**Transition to Chase:**
```
Condition: blackboard.get("distance_to_player", 999) > 7.0
Priority: 10
```

### **State 4: Cover**

**Enter Tab:**
```gdscript
print("Taking cover!")
owner.bb_set("in_cover", false)
```

**Update Tab:**
```gdscript
# Find and move to cover
if not owner.bb_get("in_cover", false):
    # Find nearest cover point
    var cover_points = owner.get_tree().get_nodes_in_group("cover")
    var nearest = null
    var nearest_dist = INF
    
    for cover in cover_points:
        var dist = owner.global_position.distance_to(cover.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = cover
    
    if nearest:
        # Move to cover
        var direction = (nearest.global_position - owner.global_position).normalized()
        owner.velocity = direction * 5.0
        owner.move_and_slide()
        
        # Check if reached
        if nearest_dist < 1.0:
            owner.bb_set("in_cover", true)
            owner.velocity = Vector3.ZERO
            print("In cover!")
```

**Transition to Reload:**
```
Condition: blackboard.get("in_cover", false) and blackboard.get("ammo", 30) < 10
Priority: 5
```

### **State 5: Reload**

**Enter Tab:**
```gdscript
print("Reloading...")
owner.bb_set("reload_start_time", Time.get_ticks_msec() / 1000.0)
```

**Update Tab:**
```gdscript
# Wait for reload time
var current_time = Time.get_ticks_msec() / 1000.0
var start_time = owner.bb_get("reload_start_time", 0.0)

if current_time - start_time > 2.0:  # 2 second reload
    owner.bb_set("ammo", 30)  # Full ammo
    owner.bb_set("needs_reload", false)
    owner.bb_set("reload_complete", true)
    print("Reload complete!")
```

**Transition to Attack:**
```
Condition: blackboard.get("reload_complete", false)
Priority: 5
```

---

## 🔧 Helper Functions

The generated code includes these helper functions:

### **bb_set(key, value)**
Write a value to the blackboard:
```gdscript
owner.bb_set("health", 50)
owner.bb_set("player_detected", true)
owner.bb_set("last_position", Vector3(10, 0, 5))
```

### **bb_get(key, default)**
Read a value from the blackboard:
```gdscript
var health = owner.bb_get("health", 100)
var detected = owner.bb_get("player_detected", false)
var pos = owner.bb_get("last_position", Vector3.ZERO)
```

### **bb_has(key)**
Check if a key exists:
```gdscript
if owner.bb_has("player_detected"):
    print("Player detection is being tracked")
```

---

## 💡 Best Practices

### **1. Initialize in First State**
```gdscript
# In Patrol state - Enter tab
owner.bb_set("player_detected", false)
owner.bb_set("health", 100)
owner.bb_set("ammo", 30)
```

### **2. Always Use Defaults**
```gdscript
# GOOD - has default
var health = owner.bb_get("health", 100)

# BAD - no default, could crash
var health = owner.bb_get("health")
```

### **3. Update Regularly**
```gdscript
# Update every frame in Update tab
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **4. Use Descriptive Names**
```gdscript
# GOOD
owner.bb_set("player_detected", true)
owner.bb_set("distance_to_player", 10.5)

# BAD
owner.bb_set("pd", true)
owner.bb_set("dist", 10.5)
```

### **5. Group Related Data**
```gdscript
# Detection
owner.bb_set("player_detected", true)
owner.bb_set("can_see_player", true)
owner.bb_set("distance_to_player", 8.5)

# Combat
owner.bb_set("health", 75)
owner.bb_set("ammo", 20)
owner.bb_set("in_cover", false)
```

---

## 🎯 Common Patterns

### **Pattern 1: Distance Checking**
```gdscript
# Write distance
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)

# Use in transition
Condition: blackboard.get("distance_to_player", 999) < 10.0
```

### **Pattern 2: Timer Tracking**
```gdscript
# Start timer
owner.bb_set("state_start_time", Time.get_ticks_msec() / 1000.0)

# Check elapsed time
var current = Time.get_ticks_msec() / 1000.0
var start = owner.bb_get("state_start_time", 0.0)
var elapsed = current - start

# Use in transition
Condition: blackboard.get("state_timer", 0) > 5.0
```

### **Pattern 3: Health Monitoring**
```gdscript
# Update health
func take_damage(amount: int):
    var health = bb_get("health", 100)
    health -= amount
    bb_set("health", health)
    
    if health < 30:
        bb_set("health_critical", true)

# Use in transition
Condition: blackboard.get("health", 100) < 30
```

### **Pattern 4: Ammo Management**
```gdscript
# Fire weapon
var ammo = owner.bb_get("ammo", 0)
if ammo > 0:
    _fire()
    owner.bb_set("ammo", ammo - 1)

# Reload
owner.bb_set("ammo", 30)

# Use in transition
Condition: blackboard.get("ammo", 30) < 5
```

---

## 🐛 Troubleshooting

### **Problem: "Variable not found"**
```gdscript
# WRONG - typo in key name
owner.bb_set("player_detcted", true)  # typo!
var detected = owner.bb_get("player_detected", false)  # different key!

# RIGHT - consistent naming
owner.bb_set("player_detected", true)
var detected = owner.bb_get("player_detected", false)
```

### **Problem: "Value is always default"**
```gdscript
# WRONG - not updating
# Patrol state never writes the value

# RIGHT - update in Update tab
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **Problem: "Transition not triggering"**
```gdscript
# Check if value is being written
print("Distance: ", owner.bb_get("distance_to_player", 999))

# Check transition condition matches
Condition: blackboard.get("distance_to_player", 999) < 10.0
```

---

## 📊 Quick Reference

### **Common Variables:**
```gdscript
# Detection
player_detected: bool
can_see_player: bool
distance_to_player: float
last_known_position: Vector3

# Combat
health: int
ammo: int
in_cover: bool
needs_reload: bool

# Timing
state_start_time: float
last_shot_time: float
cooldown_end_time: float

# Navigation
target_position: Vector3
path_blocked: bool
waypoint_index: int
```

### **Common Conditions:**
```gdscript
# Detection
blackboard.get("player_detected", false)
blackboard.get("can_see_player", false)
blackboard.get("distance_to_player", 999) < 10.0

# Combat
blackboard.get("health", 100) < 30
blackboard.get("ammo", 30) < 5
blackboard.get("in_cover", false)

# Timing
blackboard.get("state_timer", 0) > 5.0
```

---

## 🎉 Summary

The Blackboard is your **shared memory** for AI states:

1. **Add variables** in the Blackboard editor (📊 button)
2. **Write values** in state Update tabs using `owner.bb_set()`
3. **Read values** in state code using `owner.bb_get()`
4. **Use in transitions** with `blackboard.get()`

**That's it!** Simple, powerful, and flexible! 🚀

---

**Need help?** Check the examples above or the generated code in `res://ai_states/your_fsm/`

# 📊 Blackboard System - Complete Guide

## 🤔 What is the Blackboard?

The **Blackboard** is a shared memory space where all your states can read and write data. Think of it as a **bulletin board** where states post information for other states to see.

### **Why Use It?**
- ✅ Share data between states (player position, health, etc.)
- ✅ Make decisions based on shared information
- ✅ Avoid duplicating code across states
- ✅ Create smart, reactive AI

---

## 🎯 How It Works

### **Simple Analogy:**
```
Imagine a whiteboard in an office:
- Patrol state writes: "Player detected = true"
- Chase state reads: "Is player detected? Yes!"
- Attack state writes: "Ammo = 5"
- Reload state reads: "Ammo < 10? Time to reload!"
```

### **In Your AI:**
```
State 1 (Patrol):
  → Writes: "player_detected = true"
  → Writes: "distance_to_player = 8.5"

State 2 (Chase):
  → Reads: "Is player_detected true? Yes!"
  → Reads: "Is distance < 10? Yes!"
  → Decision: Keep chasing!

State 3 (Attack):
  → Reads: "Is distance < 5? Yes!"
  → Transition to Attack!
```

---

## 📝 Step-by-Step Tutorial

### **Step 1: Add Blackboard Variables**

1. Click **📊 Blackboard** button in the plugin
2. Add variables you need:

**Example for FPS Enemy:**
```
Variable Name: player_detected
Type: bool
Default Value: false

Variable Name: distance_to_player
Type: float
Default Value: 999.0

Variable Name: health
Type: int
Default Value: 100

Variable Name: ammo
Type: int
Default Value: 30

Variable Name: can_see_player
Type: bool
Default Value: false

Variable Name: in_cover
Type: bool
Default Value: false

Variable Name: last_known_position
Type: Vector3
Default Value: (0, 0, 0)
```

### **Step 2: Write to Blackboard in States**

In your state's **Update** tab, write values:

#### **Patrol State - Update Tab:**
```gdscript
# Check if player is nearby
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    
    # WRITE to blackboard
    owner.bb_set("distance_to_player", distance)
    
    # Check if we can see player
    var can_see = _check_line_of_sight()
    owner.bb_set("can_see_player", can_see)
    
    # Detect player if close and visible
    if distance < 20.0 and can_see:
        owner.bb_set("player_detected", true)
        owner.bb_set("last_known_position", owner.player.global_position)

func _check_line_of_sight() -> bool:
    # Your raycast logic here
    return true
```

#### **Chase State - Update Tab:**
```gdscript
# READ from blackboard
var distance = owner.bb_get("distance_to_player", 999.0)
var last_pos = owner.bb_get("last_known_position", Vector3.ZERO)

# Move towards player
if owner.player:
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
    
    # UPDATE blackboard
    owner.bb_set("distance_to_player", distance)
else:
    # Move to last known position
    var direction = (last_pos - owner.global_position).normalized()
    owner.velocity = direction * 4.0
    owner.move_and_slide()
```

#### **Attack State - Update Tab:**
```gdscript
# READ from blackboard
var ammo = owner.bb_get("ammo", 0)
var distance = owner.bb_get("distance_to_player", 999.0)

if ammo > 0 and distance < 10.0:
    # Attack!
    _fire_weapon()
    
    # UPDATE ammo
    ammo -= 1
    owner.bb_set("ammo", ammo)
else:
    # Need to reload or player too far
    owner.bb_set("needs_reload", true)
```

#### **Cover State - Update Tab:**
```gdscript
# Find cover
if not owner.bb_get("in_cover", false):
    var cover_pos = _find_nearest_cover()
    if cover_pos:
        owner.bb_set("cover_position", cover_pos)
        _move_to_cover(cover_pos)
        
        # Check if reached cover
        if owner.global_position.distance_to(cover_pos) < 1.0:
            owner.bb_set("in_cover", true)
```

### **Step 3: Use in Transitions**

When connecting states, use blackboard values in conditions:

#### **Patrol → Chase Transition:**
```
Condition: blackboard.get("player_detected", false)
```

#### **Chase → Attack Transition:**
```
Condition: blackboard.get("distance_to_player", 999) < 5.0
```

#### **Attack → Reload Transition:**
```
Condition: blackboard.get("ammo", 30) < 5
```

#### **Any → Cover Transition:**
```
Condition: blackboard.get("health", 100) < 30 and not blackboard.get("in_cover", false)
```

---

## 🎮 Complete Example: FPS Enemy AI

### **Setup:**

**Blackboard Variables:**
```
player_detected: bool = false
distance_to_player: float = 999.0
health: int = 100
ammo: int = 30
can_see_player: bool = false
in_cover: bool = false
last_known_position: Vector3 = (0,0,0)
needs_reload: bool = false
```

### **State 1: Patrol**

**Update Tab:**
```gdscript
# Patrol logic
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Raycast to check visibility
    var space_state = owner.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        owner.global_position,
        owner.player.global_position
    )
    var result = space_state.intersect_ray(query)
    
    var can_see = result.is_empty() or result.collider == owner.player
    owner.bb_set("can_see_player", can_see)
    
    # Detect player
    if distance < 20.0 and can_see:
        owner.bb_set("player_detected", true)
        owner.bb_set("last_known_position", owner.player.global_position)
        print("Player detected!")
```

**Transition to Chase:**
```
Condition: blackboard.get("player_detected", false)
Priority: 10
```

### **State 2: Chase**

**Enter Tab:**
```gdscript
print("Chasing player!")
owner.bb_set("player_detected", true)
```

**Update Tab:**
```gdscript
# Update distance
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    # Chase player
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Update last known position
    owner.bb_set("last_known_position", owner.player.global_position)
```

**Transition to Attack:**
```
Condition: blackboard.get("distance_to_player", 999) < 5.0 and blackboard.get("can_see_player", false)
Priority: 5
```

**Transition to Cover:**
```
Condition: blackboard.get("health", 100) < 30
Priority: 1 (higher priority!)
```

### **State 3: Attack**

**Update Tab:**
```gdscript
# Look at player
if owner.player:
    owner.look_at(owner.player.global_position, Vector3.UP)
    
    # Check ammo
    var ammo = owner.bb_get("ammo", 0)
    
    if ammo > 0:
        # Fire weapon (every 0.5 seconds)
        var time = Time.get_ticks_msec() / 1000.0
        var last_shot = owner.bb_get("last_shot_time", 0.0)
        
        if time - last_shot > 0.5:
            print("BANG! Ammo: ", ammo)
            owner.bb_set("ammo", ammo - 1)
            owner.bb_set("last_shot_time", time)
            
            # Deal damage to player
            if owner.player.has_method("take_damage"):
                owner.player.take_damage(10)
    else:
        owner.bb_set("needs_reload", true)
```

**Transition to Reload:**
```
Condition: blackboard.get("ammo", 30) < 5 or blackboard.get("needs_reload", false)
Priority: 5
```

**Transition to Chase:**
```
Condition: blackboard.get("distance_to_player", 999) > 7.0
Priority: 10
```

### **State 4: Cover**

**Enter Tab:**
```gdscript
print("Taking cover!")
owner.bb_set("in_cover", false)
```

**Update Tab:**
```gdscript
# Find and move to cover
if not owner.bb_get("in_cover", false):
    # Find nearest cover point
    var cover_points = owner.get_tree().get_nodes_in_group("cover")
    var nearest = null
    var nearest_dist = INF
    
    for cover in cover_points:
        var dist = owner.global_position.distance_to(cover.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = cover
    
    if nearest:
        # Move to cover
        var direction = (nearest.global_position - owner.global_position).normalized()
        owner.velocity = direction * 5.0
        owner.move_and_slide()
        
        # Check if reached
        if nearest_dist < 1.0:
            owner.bb_set("in_cover", true)
            owner.velocity = Vector3.ZERO
            print("In cover!")
```

**Transition to Reload:**
```
Condition: blackboard.get("in_cover", false) and blackboard.get("ammo", 30) < 10
Priority: 5
```

### **State 5: Reload**

**Enter Tab:**
```gdscript
print("Reloading...")
owner.bb_set("reload_start_time", Time.get_ticks_msec() / 1000.0)
```

**Update Tab:**
```gdscript
# Wait for reload time
var current_time = Time.get_ticks_msec() / 1000.0
var start_time = owner.bb_get("reload_start_time", 0.0)

if current_time - start_time > 2.0:  # 2 second reload
    owner.bb_set("ammo", 30)  # Full ammo
    owner.bb_set("needs_reload", false)
    owner.bb_set("reload_complete", true)
    print("Reload complete!")
```

**Transition to Attack:**
```
Condition: blackboard.get("reload_complete", false)
Priority: 5
```

---

## 🔧 Helper Functions

The generated code includes these helper functions:

### **bb_set(key, value)**
Write a value to the blackboard:
```gdscript
owner.bb_set("health", 50)
owner.bb_set("player_detected", true)
owner.bb_set("last_position", Vector3(10, 0, 5))
```

### **bb_get(key, default)**
Read a value from the blackboard:
```gdscript
var health = owner.bb_get("health", 100)
var detected = owner.bb_get("player_detected", false)
var pos = owner.bb_get("last_position", Vector3.ZERO)
```

### **bb_has(key)**
Check if a key exists:
```gdscript
if owner.bb_has("player_detected"):
    print("Player detection is being tracked")
```

---

## 💡 Best Practices

### **1. Initialize in First State**
```gdscript
# In Patrol state - Enter tab
owner.bb_set("player_detected", false)
owner.bb_set("health", 100)
owner.bb_set("ammo", 30)
```

### **2. Always Use Defaults**
```gdscript
# GOOD - has default
var health = owner.bb_get("health", 100)

# BAD - no default, could crash
var health = owner.bb_get("health")
```

### **3. Update Regularly**
```gdscript
# Update every frame in Update tab
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **4. Use Descriptive Names**
```gdscript
# GOOD
owner.bb_set("player_detected", true)
owner.bb_set("distance_to_player", 10.5)

# BAD
owner.bb_set("pd", true)
owner.bb_set("dist", 10.5)
```

### **5. Group Related Data**
```gdscript
# Detection
owner.bb_set("player_detected", true)
owner.bb_set("can_see_player", true)
owner.bb_set("distance_to_player", 8.5)

# Combat
owner.bb_set("health", 75)
owner.bb_set("ammo", 20)
owner.bb_set("in_cover", false)
```

---

## 🎯 Common Patterns

### **Pattern 1: Distance Checking**
```gdscript
# Write distance
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)

# Use in transition
Condition: blackboard.get("distance_to_player", 999) < 10.0
```

### **Pattern 2: Timer Tracking**
```gdscript
# Start timer
owner.bb_set("state_start_time", Time.get_ticks_msec() / 1000.0)

# Check elapsed time
var current = Time.get_ticks_msec() / 1000.0
var start = owner.bb_get("state_start_time", 0.0)
var elapsed = current - start

# Use in transition
Condition: blackboard.get("state_timer", 0) > 5.0
```

### **Pattern 3: Health Monitoring**
```gdscript
# Update health
func take_damage(amount: int):
    var health = bb_get("health", 100)
    health -= amount
    bb_set("health", health)
    
    if health < 30:
        bb_set("health_critical", true)

# Use in transition
Condition: blackboard.get("health", 100) < 30
```

### **Pattern 4: Ammo Management**
```gdscript
# Fire weapon
var ammo = owner.bb_get("ammo", 0)
if ammo > 0:
    _fire()
    owner.bb_set("ammo", ammo - 1)

# Reload
owner.bb_set("ammo", 30)

# Use in transition
Condition: blackboard.get("ammo", 30) < 5
```

---

## 🐛 Troubleshooting

### **Problem: "Variable not found"**
```gdscript
# WRONG - typo in key name
owner.bb_set("player_detcted", true)  # typo!
var detected = owner.bb_get("player_detected", false)  # different key!

# RIGHT - consistent naming
owner.bb_set("player_detected", true)
var detected = owner.bb_get("player_detected", false)
```

### **Problem: "Value is always default"**
```gdscript
# WRONG - not updating
# Patrol state never writes the value

# RIGHT - update in Update tab
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **Problem: "Transition not triggering"**
```gdscript
# Check if value is being written
print("Distance: ", owner.bb_get("distance_to_player", 999))

# Check transition condition matches
Condition: blackboard.get("distance_to_player", 999) < 10.0
```

---

## 📊 Quick Reference

### **Common Variables:**
```gdscript
# Detection
player_detected: bool
can_see_player: bool
distance_to_player: float
last_known_position: Vector3

# Combat
health: int
ammo: int
in_cover: bool
needs_reload: bool

# Timing
state_start_time: float
last_shot_time: float
cooldown_end_time: float

# Navigation
target_position: Vector3
path_blocked: bool
waypoint_index: int
```

### **Common Conditions:**
```gdscript
# Detection
blackboard.get("player_detected", false)
blackboard.get("can_see_player", false)
blackboard.get("distance_to_player", 999) < 10.0

# Combat
blackboard.get("health", 100) < 30
blackboard.get("ammo", 30) < 5
blackboard.get("in_cover", false)

# Timing
blackboard.get("state_timer", 0) > 5.0
```

---

## 🎉 Summary

The Blackboard is your **shared memory** for AI states:

1. **Add variables** in the Blackboard editor (📊 button)
2. **Write values** in state Update tabs using `owner.bb_set()`
3. **Read values** in state code using `owner.bb_get()`
4. **Use in transitions** with `blackboard.get()`

**That's it!** Simple, powerful, and flexible! 🚀

---

**Need help?** Check the examples above or the generated code in `res://ai_states/your_fsm/`
