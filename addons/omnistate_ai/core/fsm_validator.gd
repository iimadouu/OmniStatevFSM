@tool
extends RefCounted
class_name FSMValidator

# Validates state machine configuration for errors and warnings

static func validate(state_nodes: Array, connections: Array) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"info": []
	}
	
	# Check for empty state machine
	if state_nodes.is_empty():
		result.errors.append("State machine is empty - add at least one state")
		result.valid = false
		return result
	
	# Check for initial state
	var initial_states = []
	for node in state_nodes:
		if node.is_initial_state():
			initial_states.append(node)
	
	if initial_states.is_empty():
		result.errors.append("No initial state defined - mark one state as initial")
		result.valid = false
	elif initial_states.size() > 1:
		result.errors.append("Multiple initial states defined - only one state can be initial")
		result.valid = false
	
	# Check for unnamed states
	var state_names = []
	for node in state_nodes:
		var name = node.get_state_name()
		if name == "" or name == "unnamed_state":
			result.warnings.append("State at position " + str(node.position_offset) + " has no name")
		else:
			state_names.append(name)
	
	# Check for duplicate state names
	var unique_names = {}
	for name in state_names:
		if unique_names.has(name):
			result.errors.append("Duplicate state name: '" + name + "'")
			result.valid = false
		else:
			unique_names[name] = true
	
	# Check for disconnected states (except if only one state)
	if state_nodes.size() > 1:
		for node in state_nodes:
			var has_connection = false
			for conn in connections:
				if conn.from_node == node.name or conn.to_node == node.name:
					has_connection = true
					break
			
			if not has_connection:
				result.warnings.append("State '" + node.get_state_name() + "' is not connected to any other state")
	
	# Check for states without transitions (dead ends)
	for node in state_nodes:
		if node.transitions.is_empty() and node.get_state_name() != "dead":
			result.warnings.append("State '" + node.get_state_name() + "' has no transitions - may be a dead end")
	
	# Check for invalid transition targets
	for node in state_nodes:
		for trans in node.transitions:
			var target_exists = false
			for target_node in state_nodes:
				if target_node.get_state_name() == trans.to_state:
					target_exists = true
					break
			
			if not target_exists:
				result.errors.append("State '" + node.get_state_name() + "' has transition to non-existent state '" + trans.to_state + "'")
				result.valid = false
	
	# Check for empty transition conditions
	for node in state_nodes:
		for trans in node.transitions:
			if trans.condition == "":
				result.warnings.append("Transition from '" + node.get_state_name() + "' to '" + trans.to_state + "' has no condition")
	
	# Check for unreachable states
	if not initial_states.is_empty():
		var reachable = _find_reachable_states(initial_states[0], state_nodes)
		for node in state_nodes:
			if not reachable.has(node.get_state_name()):
				result.warnings.append("State '" + node.get_state_name() + "' is unreachable from initial state")
	
	# Info messages
	result.info.append("Total states: " + str(state_nodes.size()))
	result.info.append("Total connections: " + str(connections.size()))
	
	var total_transitions = 0
	for node in state_nodes:
		total_transitions += node.transitions.size()
	result.info.append("Total transitions: " + str(total_transitions))
	
	return result

static func _find_reachable_states(initial_state, all_states: Array) -> Dictionary:
	var reachable = {}
	var to_visit = [initial_state.get_state_name()]
	var visited = {}
	
	while not to_visit.is_empty():
		var current_name = to_visit.pop_front()
		if visited.has(current_name):
			continue
		
		visited[current_name] = true
		reachable[current_name] = true
		
		# Find the node with this name
		for node in all_states:
			if node.get_state_name() == current_name:
				# Add all transition targets to visit list
				for trans in node.transitions:
					if not visited.has(trans.to_state):
						to_visit.append(trans.to_state)
				break
	
	return reachable

static func format_validation_result(result: Dictionary) -> String:
	var text = ""
	
	if result.errors.is_empty() and result.warnings.is_empty():
		text += "✓ VALIDATION PASSED\n\n"
		text += "No errors or warnings found!\n\n"
	else:
		if not result.errors.is_empty():
			text += "❌ ERRORS:\n"
			for error in result.errors:
				text += "  • " + error + "\n"
			text += "\n"
		
		if not result.warnings.is_empty():
			text += "⚠ WARNINGS:\n"
			for warning in result.warnings:
				text += "  • " + warning + "\n"
			text += "\n"
	
	if not result.info.is_empty():
		text += "ℹ INFO:\n"
		for info in result.info:
			text += "  • " + info + "\n"
	
	return text
