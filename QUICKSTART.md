# OmniState AI - Quick Start Guide

Get your AI up and running in 5 minutes!

## Step 1: Enable the Plugin (30 seconds)

1. Go to **Project → Project Settings → Plugins**
2. Find "OmniState Visual AI" and check the **Enable** checkbox
3. The plugin panel will appear at the bottom of your editor

## Step 2: Prepare Your Enemy Scene (2 minutes)

Your enemy needs:
- A root node (CharacterBody3D, CharacterBody2D, etc.)
- An **AnimationPlayer** node with animations
- Optional: NavigationAgent3D for pathfinding

Example structure:
```
Enemy (CharacterBody3D)
├── CollisionShape3D
├── Model (Node3D)
│   └── MeshInstance3D
├── AnimationPlayer  ← Important!
│   ├── idle
│   ├── walk
│   ├── run
│   └── attack
└── NavigationAgent3D (optional)
```

## Step 3: Configure the FSM (1 minute)

1. Click **⚙ Setup Wizard** in the OmniState AI panel
2. Fill in:
   - **Script Name**: `enemy_ai` (or whatever you want)
   - **Base Class**: Select your enemy's root node type
   - **Enemy Scene Path**: Browse to your enemy scene
   - **AnimationPlayer Path**: Usually just `AnimationPlayer`
3. Click **Detect Animations Now** to auto-detect your animations
4. Click **OK**

## Step 4: Build Your State Machine (1 minute)

### Quick Method - Use Templates:
1. Right-click on the canvas
2. Select **Add from Template → Patrol**
3. Repeat for **Chase** and **Attack**
4. Mark **Patrol** as the initial state (check "Initial State" in Basic tab)

### Connect the States:
1. Drag from Patrol's output (right side) to Chase's input (left side)
2. Enter condition: `player_detected`
3. Drag from Chase to Attack
4. Enter condition: `in_attack_range`
5. Drag from Attack back to Chase
6. Enter condition: `player_out_of_range`

## Step 5: Generate and Use (30 seconds)

1. Click **✓ Validate** to check for errors
2. Click **💾 Save & Generate**
3. Your scripts are now in `res://ai_states/enemy_ai/`
4. Attach `enemy_ai.gd` to your enemy scene's root node
5. Run your game!

## What You Get

Generated files:
- `enemy_ai.gd` - Main FSM controller (attach this to your enemy)
- `patrol_state.gd` - Patrol behavior
- `chase_state.gd` - Chase behavior
- `attack_state.gd` - Attack behavior
- `state.gd` - Base class for all states
- `blackboard.gd` - Shared data storage

## Customizing the Behavior

### Add Player Detection

In your enemy's `_ready()` function (or in the generated script):

```gdscript
func _physics_process(delta):
	super._physics_process(delta)
	
	# Update blackboard with player detection
	if player:
		var distance = global_position.distance_to(player.global_position)
		blackboard.set_value("player_detected", distance < 20.0)
		blackboard.set_value("in_attack_range", distance < 5.0)
		blackboard.set_value("player_out_of_range", distance > 7.0)
```

### Customize State Behavior

Edit the generated state files to add your specific logic:

**patrol_state.gd**:
```gdscript
func update(delta: float):
	# Your patrol logic here
	var patrol_points = blackboard.get_value("patrol_points", [])
	if patrol_points.is_empty():
		return
	
	# Move to next patrol point
	# ... your code ...
```

**attack_state.gd**:
```gdscript
func update(delta: float):
	var player = get_player()
	if not player:
		return
	
	# Look at player
	var owner_node = get_owner()
	owner_node.look_at(player.global_position, Vector3.UP)
	
	# Attack logic
	var timer = blackboard.get_value("attack_timer", 0.0)
	timer += delta
	
	if timer >= 1.0:  # Attack every second
		_perform_attack()
		blackboard.set_value("attack_timer", 0.0)
	else:
		blackboard.set_value("attack_timer", timer)

func _perform_attack():
	print("Attacking player!")
	# Your attack logic here
```

## Common Patterns

### Player Detection with Raycast

```gdscript
func can_see_player() -> bool:
	var player = blackboard.get_value("player")
	if not player:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,  # From enemy eye level
		player.global_position + Vector3.UP
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player
```

### Navigation with NavigationAgent3D

```gdscript
func update(delta: float):
	var nav_agent = blackboard.get_value("navigation_agent")
	if not nav_agent or nav_agent.is_navigation_finished():
		return
	
	var next_position = nav_agent.get_next_path_position()
	var owner_node = get_owner()
	var direction = (next_position - owner_node.global_position).normalized()
	
	owner_node.velocity = direction * 5.0
	owner_node.move_and_slide()
```

### Health-Based Transitions

```gdscript
# In your enemy script
func _physics_process(delta):
	super._physics_process(delta)
	
	# Update health status in blackboard
	blackboard.set_value("health_low", health < 30)
	blackboard.set_value("health_critical", health < 10)
```

Then use `health_low` or `health_critical` as transition conditions!

## Tips

1. **Start Simple**: Begin with 2-3 states, test, then expand
2. **Use Blackboard**: Share data between states via the blackboard
3. **Test Often**: Generate and test after each major change
4. **Validate First**: Always validate before generating
5. **Read Generated Code**: The generated code is meant to be read and customized!

## Next Steps

- Add more complex states (Cover, Flee, Investigate)
- Implement advanced behaviors (flanking, group tactics)
- Add sound effects and particles to state transitions
- Create multiple AI types with different state machines
- Use the blackboard for team coordination

## Troubleshooting

**"Player not found"**
- Add your player to a group called "player"
- Or manually set: `blackboard.set_value("player", player_node)`

**"Animation not playing"**
- Check AnimationPlayer path in Setup Wizard
- Verify animation names match your AnimationPlayer

**"Enemy not moving"**
- Ensure you're calling `move_and_slide()` in state update code
- Check that velocity is being set

**"Transitions not working"**
- Make sure conditions are being set in blackboard
- Use `print()` to debug condition values
- Check transition conditions in the Transitions tab

## Need Help?

- Check the full README.md for detailed documentation
- Examine the generated code - it's well-commented!
- Look at the state templates for examples
- Validate your state machine for errors

Happy AI building! 🤖
