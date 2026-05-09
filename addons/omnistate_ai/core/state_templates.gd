@tool
extends RefCounted
class_name StateTemplates

# Provides pre-built state templates for common AI behaviors

static func get_template_names() -> Array:
	return [
		"Idle",
		"Patrol",
		"Chase",
		"Attack",
		"Cover",
		"Flee",
		"Investigate",
		"Search",
		"Dead"
	]

static func get_template(template_name: String) -> Dictionary:
	match template_name:
		"Idle":
			return {
				"name": "idle",
				"animation": "idle",
				"enter_code": "# Look around randomly\nblackboard.set_value(\"idle_timer\", 0.0)",
				"update_code": "var timer = blackboard.get_value(\"idle_timer\", 0.0)\ntimer += delta\nblackboard.set_value(\"idle_timer\", timer)\n\n# Random look direction\nif timer > 2.0:\n\tvar random_angle = randf_range(-PI, PI)\n\tstate_machine.rotation.y = random_angle\n\tblackboard.set_value(\"idle_timer\", 0.0)",
				"exit_code": "pass",
				"behaviors": ["is_idle"],
				"transitions": [
					{"to": "patrol", "condition": "should_patrol"},
					{"to": "chase", "condition": "player_detected"}
				]
			}
		
		"Patrol":
			return {
				"name": "patrol",
				"animation": "walk",
				"enter_code": "# Set up patrol points\nif not blackboard.has_value(\"patrol_points\"):\n\tblackboard.set_value(\"patrol_points\", [])\n\tblackboard.set_value(\"current_patrol_index\", 0)",
				"update_code": "var nav_agent = blackboard.get_value(\"navigation_agent\")\nif nav_agent and not nav_agent.is_navigation_finished():\n\tvar next_position = nav_agent.get_next_path_position()\n\tvar direction = (next_position - state_machine.global_position).normalized()\n\tstate_machine.velocity = direction * 3.0\n\tstate_machine.move_and_slide()\n\t\n\t# Look in movement direction\n\tif direction.length() > 0.1:\n\t\tstate_machine.look_at(state_machine.global_position + direction, Vector3.UP)",
				"exit_code": "state_machine.velocity = Vector3.ZERO",
				"behaviors": ["is_patrolling", "get_next_patrol_point"],
				"transitions": [
					{"to": "idle", "condition": "reached_patrol_point"},
					{"to": "chase", "condition": "player_detected"}
				]
			}
		
		"Chase":
			return {
				"name": "chase",
				"animation": "run",
				"enter_code": "print(\"Chasing player!\")\nblackboard.set_value(\"chase_speed\", 6.0)",
				"update_code": "var player = blackboard.get_value(\"player\")\nif not player:\n\treturn\n\nvar direction = (player.global_position - state_machine.global_position).normalized()\nvar speed = blackboard.get_value(\"chase_speed\", 5.0)\n\nstate_machine.velocity = direction * speed\nstate_machine.move_and_slide()\n\n# Look at player\nstate_machine.look_at(player.global_position, Vector3.UP)",
				"exit_code": "state_machine.velocity = Vector3.ZERO",
				"behaviors": ["can_see_player", "distance_to_player"],
				"transitions": [
					{"to": "attack", "condition": "in_attack_range"},
					{"to": "search", "condition": "lost_player"}
				]
			}
		
		"Attack":
			return {
				"name": "attack",
				"animation": "attack",
				"enter_code": "blackboard.set_value(\"attack_timer\", 0.0)\nblackboard.set_value(\"attack_cooldown\", 1.0)",
				"update_code": "var player = blackboard.get_value(\"player\")\nif not player:\n\treturn\n\n# Look at player\nstate_machine.look_at(player.global_position, Vector3.UP)\n\n# Attack timer\nvar timer = blackboard.get_value(\"attack_timer\", 0.0)\ntimer += delta\n\nif timer >= blackboard.get_value(\"attack_cooldown\", 1.0):\n\t# Perform attack\n\t_perform_attack()\n\tblackboard.set_value(\"attack_timer\", 0.0)\nelse:\n\tblackboard.set_value(\"attack_timer\", timer)",
				"exit_code": "pass",
				"behaviors": ["can_attack", "perform_attack"],
				"transitions": [
					{"to": "chase", "condition": "player_out_of_range"},
					{"to": "cover", "condition": "health_low"}
				]
			}
		
		"Cover":
			return {
				"name": "cover",
				"animation": "cover_idle",
				"enter_code": "# Find nearest cover point\nvar cover_point = _find_nearest_cover()\nif cover_point:\n\tblackboard.set_value(\"cover_position\", cover_point)\nblackboard.set_value(\"in_cover\", false)",
				"update_code": "var cover_pos = blackboard.get_value(\"cover_position\")\nif not cover_pos:\n\treturn\n\nvar in_cover = blackboard.get_value(\"in_cover\", false)\n\nif not in_cover:\n\t# Move to cover\n\tvar direction = (cover_pos - state_machine.global_position).normalized()\n\tstate_machine.velocity = direction * 4.0\n\tstate_machine.move_and_slide()\n\t\n\tif state_machine.global_position.distance_to(cover_pos) < 1.0:\n\t\tblackboard.set_value(\"in_cover\", true)\n\t\tstate_machine.velocity = Vector3.ZERO\nelse:\n\t# In cover - peek and shoot occasionally\n\tpass",
				"exit_code": "blackboard.set_value(\"in_cover\", false)",
				"behaviors": ["is_in_cover", "find_cover"],
				"transitions": [
					{"to": "attack", "condition": "health_recovered"},
					{"to": "flee", "condition": "cover_compromised"}
				]
			}
		
		"Flee":
			return {
				"name": "flee",
				"animation": "run",
				"enter_code": "print(\"Fleeing!\")\nblackboard.set_value(\"flee_timer\", 0.0)",
				"update_code": "var player = blackboard.get_value(\"player\")\nif player:\n\t# Run away from player\n\tvar direction = (state_machine.global_position - player.global_position).normalized()\n\tstate_machine.velocity = direction * 7.0\n\tstate_machine.move_and_slide()\n\nvar timer = blackboard.get_value(\"flee_timer\", 0.0)\ntimer += delta\nblackboard.set_value(\"flee_timer\", timer)",
				"exit_code": "state_machine.velocity = Vector3.ZERO",
				"behaviors": ["is_fleeing", "is_safe"],
				"transitions": [
					{"to": "cover", "condition": "found_safe_spot"},
					{"to": "idle", "condition": "flee_timer > 5.0"}
				]
			}
		
		"Investigate":
			return {
				"name": "investigate",
				"animation": "walk",
				"enter_code": "var last_known_pos = blackboard.get_value(\"last_known_player_position\")\nif last_known_pos:\n\tblackboard.set_value(\"investigate_position\", last_known_pos)",
				"update_code": "var investigate_pos = blackboard.get_value(\"investigate_position\")\nif not investigate_pos:\n\treturn\n\nvar direction = (investigate_pos - state_machine.global_position).normalized()\nstate_machine.velocity = direction * 3.0\nstate_machine.move_and_slide()\n\nif state_machine.global_position.distance_to(investigate_pos) < 2.0:\n\tblackboard.set_value(\"investigation_complete\", true)",
				"exit_code": "state_machine.velocity = Vector3.ZERO",
				"behaviors": ["is_investigating"],
				"transitions": [
					{"to": "search", "condition": "investigation_complete"},
					{"to": "chase", "condition": "player_detected"}
				]
			}
		
		"Search":
			return {
				"name": "search",
				"animation": "walk",
				"enter_code": "blackboard.set_value(\"search_timer\", 0.0)\nblackboard.set_value(\"search_duration\", 10.0)",
				"update_code": "# Search in expanding circle\nvar timer = blackboard.get_value(\"search_timer\", 0.0)\ntimer += delta\nblackboard.set_value(\"search_timer\", timer)\n\n# Rotate and look around\nstate_machine.rotation.y += delta * 0.5",
				"exit_code": "pass",
				"behaviors": ["is_searching"],
				"transitions": [
					{"to": "chase", "condition": "player_detected"},
					{"to": "patrol", "condition": "search_timer > search_duration"}
				]
			}
		
		"Dead":
			return {
				"name": "dead",
				"animation": "death",
				"enter_code": "print(\"Enemy died\")\nstate_machine.set_physics_process(false)\nstate_machine.collision_layer = 0\nstate_machine.collision_mask = 0",
				"update_code": "# Dead - do nothing",
				"exit_code": "# Cannot exit death state",
				"behaviors": ["is_dead"],
				"transitions": []
			}
		
		_:
			return {}

static func apply_template_to_node(node, template_name: String):
	var template = get_template(template_name)
	if template.is_empty():
		return
	
	node.state_name_input.text = template.name
	node.title = template.name.capitalize()
	
	if template.has("animation"):
		# Set animation if it exists in the dropdown
		for i in range(node.anim_input.item_count):
			if node.anim_input.get_item_text(i) == template.animation:
				node.anim_input.selected = i
				break
	
	if template.has("enter_code"):
		node.enter_code_input.text = template.enter_code
	
	if template.has("update_code"):
		node.code_input.text = template.update_code
	
	if template.has("exit_code"):
		node.exit_code_input.text = template.exit_code
	
	if template.has("behaviors"):
		for behavior in template.behaviors:
			node._add_behavior(behavior)
