# 📊 Blackboard Quick Start - 5 Minutes

## 🎯 What You Need to Know

**Blackboard = Shared Memory for All States**

Think of it as a whiteboard where states write and read information.

---

## ⚡ 3-Step Process

### **Step 1: Add Variables (30 seconds)**

Click **📊 Blackboard** button → Add variables:

```
player_detected (bool) = false
distance_to_player (float) = 999.0
health (int) = 100
ammo (int) = 30
```

### **Step 2: Write Values in States (1 minute)**

In your state's **Update** tab:

```gdscript
# Calculate distance
var distance = owner.global_position.distance_to(owner.player.global_position)

# WRITE to blackboard
owner.bb_set("distance_to_player", distance)

# Detect player
if distance < 20.0:
    owner.bb_set("player_detected", true)
```

### **Step 3: Use in Transitions (30 seconds)**

When connecting states:

```
Condition: blackboard.get("player_detected", false)
```

**Done!** 🎉

---

## 📝 Copy-Paste Examples

### **Example 1: Distance Tracking**

**In Patrol State - Update Tab:**
```gdscript
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
```

**In Transition (Patrol → Chase):**
```
Condition: blackboard.get("distance_to_player", 999) < 10.0
```

### **Example 2: Health Monitoring**

**In Any State - When Taking Damage:**
```gdscript
func take_damage(amount: int):
    var health = owner.bb_get("health", 100)
    health -= amount
    owner.bb_set("health", health)
```

**In Transition (Any → Flee):**
```
Condition: blackboard.get("health", 100) < 30
```

### **Example 3: Ammo Management**

**In Attack State - Update Tab:**
```gdscript
var ammo = owner.bb_get("ammo", 30)
if ammo > 0:
    # Fire weapon
    print("BANG!")
    owner.bb_set("ammo", ammo - 1)
```

**In Transition (Attack → Reload):**
```
Condition: blackboard.get("ammo", 30) < 5
```

---

## 🔧 Three Functions You Need

### **1. bb_set(key, value)** - Write
```gdscript
owner.bb_set("player_detected", true)
owner.bb_set("health", 50)
owner.bb_set("ammo", 20)
```

### **2. bb_get(key, default)** - Read
```gdscript
var detected = owner.bb_get("player_detected", false)
var health = owner.bb_get("health", 100)
var ammo = owner.bb_get("ammo", 30)
```

### **3. In Transitions** - Check
```gdscript
blackboard.get("player_detected", false)
blackboard.get("health", 100) < 30
blackboard.get("distance_to_player", 999) < 10.0
```

---

## 🎮 Complete Mini-Example

### **Setup:**
Add these variables in Blackboard:
- `player_detected` (bool) = false
- `distance_to_player` (float) = 999.0

### **Patrol State - Update Tab:**
```gdscript
if owner.player:
    var distance = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", distance)
    
    if distance < 20.0:
        owner.bb_set("player_detected", true)
```

### **Chase State - Update Tab:**
```gdscript
var distance = owner.bb_get("distance_to_player", 999.0)
print("Chasing! Distance: ", distance)

if owner.player:
    var direction = (owner.player.global_position - owner.global_position).normalized()
    owner.velocity = direction * 6.0
    owner.move_and_slide()
```

### **Transitions:**
```
Patrol → Chase:
  Condition: blackboard.get("player_detected", false)

Chase → Attack:
  Condition: blackboard.get("distance_to_player", 999) < 5.0
```

**That's it!** Your AI now shares data between states! 🚀

---

## 💡 Pro Tips

### **Tip 1: Always Use Defaults**
```gdscript
# GOOD ✅
var health = owner.bb_get("health", 100)

# BAD ❌
var health = owner.bb_get("health")  # Could crash!
```

### **Tip 2: Update Every Frame**
```gdscript
# In Update tab - runs every frame
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **Tip 3: Use Descriptive Names**
```gdscript
# GOOD ✅
owner.bb_set("player_detected", true)

# BAD ❌
owner.bb_set("pd", true)
```

---

## 🐛 Common Mistakes

### **Mistake 1: Typos**
```gdscript
# WRONG ❌
owner.bb_set("player_detcted", true)  # typo!
var detected = owner.bb_get("player_detected", false)  # different!

# RIGHT ✅
owner.bb_set("player_detected", true)
var detected = owner.bb_get("player_detected", false)
```

### **Mistake 2: Not Updating**
```gdscript
# WRONG ❌ - Only set once in Enter tab
owner.bb_set("distance_to_player", 10.0)

# RIGHT ✅ - Update every frame in Update tab
var distance = owner.global_position.distance_to(owner.player.global_position)
owner.bb_set("distance_to_player", distance)
```

### **Mistake 3: Wrong Syntax in Transitions**
```gdscript
# WRONG ❌
owner.bb_get("player_detected", false)

# RIGHT ✅
blackboard.get("player_detected", false)
```

---

## 📊 Cheat Sheet

| Action | Code | Where |
|--------|------|-------|
| **Write** | `owner.bb_set("key", value)` | State Update tab |
| **Read** | `owner.bb_get("key", default)` | State Update tab |
| **Check** | `blackboard.get("key", default)` | Transition condition |

---

## 🎯 Most Common Variables

```gdscript
# Detection
player_detected: bool = false
can_see_player: bool = false
distance_to_player: float = 999.0

# Combat
health: int = 100
ammo: int = 30
in_cover: bool = false

# Timing
state_timer: float = 0.0
```

---

## 🎉 You're Ready!

Now you know:
- ✅ What the Blackboard is
- ✅ How to add variables
- ✅ How to write values (`bb_set`)
- ✅ How to read values (`bb_get`)
- ✅ How to use in transitions

**Go build amazing AI!** 🚀

---

**Need more details?** See [BLACKBOARD_GUIDE.md](BLACKBOARD_GUIDE.md) for complete examples!
