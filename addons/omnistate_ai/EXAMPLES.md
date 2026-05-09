# OmniState AI - Example State Machines

## Example 1: Simple Guard AI

**States**: Idle → Alert → Chase → Attack

### Setup
1. Create 4 states: Idle, Alert, Chase, Attack
2. Mark Idle as initial state

### Transitions
- Idle → Alert: `noise_heard or player_spotted`
- Alert → Chase: `player_confirmed`
- Alert → Idle: `alert_timer > 5.0`
- Chase → Attack: `distance_to_player < 3.0`
- Chase → Idle: `lost_player`
- Attack → Chase: `distance_to_player > 5.0`

### Code Snippets

**Idle State - Update**:
```gdscript
# Look around randomly
var timer = blackboard.get_value("idle_timer", 0.0)
timer += delta
blackboard.set_value("idle_timer", timer)

if timer > 3.0:
	var random_angle = randf_range(-PI, PI)
	get_owner().rotation.y = random_angle
	blackboard.set_value("idle_timer", 0.0)

# Check for player
var player = get_player()
if player and global_position.distance_to(player.global_position) < 15.0:
	blackboard.set_value("player_spotted", true)
```

---

## Example 2: Tactical Combat AI

**States**: Patrol → Engage → Flank → Cover → Reload → Retreat

### State Descriptions
- **Patrol**: Follow waypoints
- **Engage**: Move toward player while shooting
- **Flank**: Try to get behind player
- **Cover**: Hide and peek-shoot
- **Reload**: Find safe spot to reload
- **Retreat**: Fall back when health low

### Transitions
```
Patrol → Engage: player_detected
Engage → Flank: has_flanking_position
Engage → Cover: taking_damage
Engage → Reload: ammo_low
Flank → Engage: flanking_complete
Cover → Engage: health_recovered
Cover → Retreat: health_critical
Reload → Cover: reload_complete
Retreat → Cover: reached_safe_distance
```

### Advanced Code

**Flank State - Update**:
```gdscript
var player = get_player()
if not player:
	return

var owner_node = get_owner()

# Calculate flanking position (90 degrees from player's facing)
var player_forward = -player.global_transform.basis.z
var flank_offset = player_forward.rotated(Vector3.UP, PI/2) * 10.0
var flank_position = player.global_position + flank_offset

# Move to flank position
var direction = (flank_position - owner_node.global_position).normalized()
owner_node.velocity = direction * 6.0
owner_node.move_and_slide()

# Check if flanking complete
if owner_node.global_position.distance_to(flank_position) < 2.0:
	blackboard.set_value("flanking_complete", true)
```

**Cover State - Update**:
```gdscript
var in_cover = blackboard.get_value("in_cover", false)
var owner_node = get_owner()

if not in_cover:
	# Move to cover
	var cover_pos = blackboard.get_value("cover_position")
	if cover_pos:
		var direction = (cover_pos - owner_node.global_position).normalized()
		owner_node.velocity = direction * 5.0
		owner_node.move_and_slide()
		
		if owner_node.global_position.distance_to(cover_pos) < 1.0:
			blackboard.set_value("in_cover", true)
			owner_node.velocity = Vector3.ZERO
else:
	# Peek and shoot
	var peek_timer = blackboard.get_value("peek_timer", 0.0)
	peek_timer += delta
	
	if peek_timer > 2.0:
		_peek_and_shoot()
		blackboard.set_value("peek_timer", 0.0)
	else:
		blackboard.set_value("peek_timer", peek_timer)
	
	# Check if health recovered
	var health = blackboard.get_value("health", 100)
	if health > 60:
		blackboard.set_value("health_recovered", true)
```

---

## Example 3: Stealth Enemy AI

**States**: Patrol → Investigate → Search → Hunt → Ambush → Alert

### Behavior
- Patrols until hearing a sound
- Investigates suspicious activity
- Searches area if player escapes
- Hunts player when detected
- Sets up ambushes at choke points
- Calls for backup when alerted

### Key Features

**Sound Detection**:
```gdscript
# In main enemy script
func on_sound_detected(sound_position: Vector3, loudness: float):
	if loudness > 0.5:
		blackboard.set_value("last_sound_position", sound_position)
		blackboard.set_value("should_investigate", true)
```

**Investigate State**:
```gdscript
func enter():
	var sound_pos = blackboard.get_value("last_sound_position")
	if sound_pos:
		var nav_agent = blackboard.get_value("navigation_agent")
		if nav_agent:
			nav_agent.target_position = sound_pos

func update(delta: float):
	var nav_agent = blackboard.get_value("navigation_agent")
	if not nav_agent:
		return
	
	if nav_agent.is_navigation_finished():
		# Reached investigation point
		blackboard.set_value("investigation_complete", true)
		return
	
	# Move to investigation point
	var next_pos = nav_agent.get_next_path_position()
	var owner_node = get_owner()
	var direction = (next_pos - owner_node.global_position).normalized()
	
	owner_node.velocity = direction * 3.0  # Slow, cautious movement
	owner_node.move_and_slide()
	
	# Look around while moving
	owner_node.rotation.y += delta * 0.5
```

**Ambush State**:
```gdscript
func enter():
	# Find ambush position
	var player = get_player()
	if player:
		var ambush_pos = _find_ambush_position(player.global_position)
		blackboard.set_value("ambush_position", ambush_pos)
	
	blackboard.set_value("is_hidden", false)

func update(delta: float):
	var is_hidden = blackboard.get_value("is_hidden", false)
	var owner_node = get_owner()
	
	if not is_hidden:
		# Move to ambush position
		var ambush_pos = blackboard.get_value("ambush_position")
		if ambush_pos:
			var direction = (ambush_pos - owner_node.global_position).normalized()
			owner_node.velocity = direction * 4.0
			owner_node.move_and_slide()
			
			if owner_node.global_position.distance_to(ambush_pos) < 1.0:
				blackboard.set_value("is_hidden", true)
				owner_node.velocity = Vector3.ZERO
				# Play hide animation
				if state_machine.animation_player:
					state_machine.animation_player.play("crouch_idle")
	else:
		# Wait for player
		var player = get_player()
		if player:
			var distance = owner_node.global_position.distance_to(player.global_position)
			if distance < 5.0:
				# Spring the ambush!
				blackboard.set_value("ambush_triggered", true)

func _find_ambush_position(player_pos: Vector3) -> Vector3:
	# Find a position near the player's predicted path
	var owner_node = get_owner()
	var to_player = (player_pos - owner_node.global_position).normalized()
	var ambush_offset = to_player.rotated(Vector3.UP, PI/4) * 8.0
	return player_pos + ambush_offset
```

---

## Example 4: Boss AI with Phases

**States**: Phase1 → Transition1 → Phase2 → Transition2 → Phase3 → Enraged → Dead

### Phase System

**Phase 1 (100-70% HP)**: Basic attacks
**Phase 2 (70-40% HP)**: Adds special attacks
**Phase 3 (40-0% HP)**: All attacks, faster
**Enraged**: Triggered at 20% HP

### Implementation

**Main Boss Script**:
```gdscript
extends CharacterBody3D

var health = 100
var max_health = 100

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update phase based on health
	var health_percent = (health / float(max_health)) * 100
	
	blackboard.set_value("health_percent", health_percent)
	blackboard.set_value("phase1_complete", health_percent < 70)
	blackboard.set_value("phase2_complete", health_percent < 40)
	blackboard.set_value("should_enrage", health_percent < 20)
	blackboard.set_value("is_dead", health <= 0)

func take_damage(amount: int):
	health -= amount
	blackboard.set_value("taking_damage", true)
	
	# Reset after a frame
	await get_tree().process_frame
	blackboard.set_value("taking_damage", false)
```

**Phase1 State**:
```gdscript
func update(delta: float):
	var player = get_player()
	if not player:
		return
	
	var owner_node = get_owner()
	
	# Basic attack pattern
	var attack_timer = blackboard.get_value("attack_timer", 0.0)
	attack_timer += delta
	
	if attack_timer > 2.0:
		_perform_basic_attack()
		blackboard.set_value("attack_timer", 0.0)
	else:
		blackboard.set_value("attack_timer", attack_timer)
	
	# Move toward player
	var direction = (player.global_position - owner_node.global_position).normalized()
	owner_node.velocity = direction * 3.0
	owner_node.move_and_slide()
```

**Phase2 State**:
```gdscript
func update(delta: float):
	var player = get_player()
	if not player:
		return
	
	var owner_node = get_owner()
	var attack_timer = blackboard.get_value("attack_timer", 0.0)
	attack_timer += delta
	
	# Alternate between basic and special attacks
	if attack_timer > 1.5:
		var attack_count = blackboard.get_value("attack_count", 0)
		
		if attack_count % 3 == 0:
			_perform_special_attack()
		else:
			_perform_basic_attack()
		
		blackboard.set_value("attack_count", attack_count + 1)
		blackboard.set_value("attack_timer", 0.0)
	else:
		blackboard.set_value("attack_timer", attack_timer)
	
	# Faster movement
	var direction = (player.global_position - owner_node.global_position).normalized()
	owner_node.velocity = direction * 4.5
	owner_node.move_and_slide()
```

**Enraged State**:
```gdscript
func enter():
	print("BOSS ENRAGED!")
	var owner_node = get_owner()
	owner_node.modulate = Color.RED
	
	if state_machine.animation_player:
		state_machine.animation_player.speed_scale = 1.5

func update(delta: float):
	var player = get_player()
	if not player:
		return
	
	var owner_node = get_owner()
	
	# Rapid attacks
	var attack_timer = blackboard.get_value("attack_timer", 0.0)
	attack_timer += delta
	
	if attack_timer > 0.8:
		# Random attack
		var rand = randf()
		if rand < 0.5:
			_perform_basic_attack()
		else:
			_perform_special_attack()
		
		blackboard.set_value("attack_timer", 0.0)
	else:
		blackboard.set_value("attack_timer", attack_timer)
	
	# Very fast movement
	var direction = (player.global_position - owner_node.global_position).normalized()
	owner_node.velocity = direction * 7.0
	owner_node.move_and_slide()

func exit():
	var owner_node = get_owner()
	owner_node.modulate = Color.WHITE
	
	if state_machine.animation_player:
		state_machine.animation_player.speed_scale = 1.0
```

---

## Tips for Complex State Machines

1. **Use Sub-States**: Break complex states into smaller ones
2. **Blackboard is Key**: Share data extensively via blackboard
3. **Timer Pattern**: Use timers for cooldowns and delays
4. **Distance Checks**: Cache distance calculations
5. **Debug Prints**: Add prints to track state changes
6. **Visual Feedback**: Change colors/effects per state
7. **Animation Sync**: Match animations to state behavior
8. **Gradual Complexity**: Start simple, add features incrementally

## Common Helper Functions

Add these to your main FSM script:

```gdscript
func get_distance_to_player() -> float:
	var player = blackboard.get_value("player")
	if not player:
		return INF
	return global_position.distance_to(player.global_position)

func can_see_player() -> bool:
	var player = blackboard.get_value("player")
	if not player:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		player.global_position + Vector3.UP
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func find_cover_position() -> Vector3:
	# Implement cover finding logic
	# Could use raycasts, navigation mesh, or pre-placed cover points
	return Vector3.ZERO

func call_for_backup():
	# Alert nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < 20.0:
			enemy.blackboard.set_value("backup_called", true)
			enemy.blackboard.set_value("backup_location", global_position)
```

---

Experiment with these examples and create your own unique AI behaviors!
