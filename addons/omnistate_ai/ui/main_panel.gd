@tool
extends Control

# UI Components
var toolbar: HBoxContainer
var graph_edit: GraphEdit
var setup_wizard
var transition_dialog

# References
var StateNodeClass = preload("res://addons/omnistate_ai/ui/state_node.gd")
var FsmGenerator = preload("res://addons/omnistate_ai/core/fsm_generator.gd")
var FSMValidator = preload("res://addons/omnistate_ai/core/fsm_validator.gd")
var StateTemplates = preload("res://addons/omnistate_ai/core/state_templates.gd")
var editor_plugin = null

# Configuration
var fsm_script_name = "enemy_fsm"
var base_class_name = "CharacterBody3D"
var enemy_scene_path = ""
var player_scene_path = ""
var animation_player_path = "AnimationPlayer"
var detected_animations: Array = []

# State tracking
var selected_state_node: OmniStateNode = null
var connection_from_node: String = ""

# Undo/Redo
var undo_redo: EditorUndoRedoManager = null

func _ready():
	print("[DEBUG] main_panel _ready() called")
	_setup_ui()
	print("[DEBUG] _setup_ui() completed")
	# Try to auto-load existing graph
	call_deferred("_try_auto_load")
	print("[DEBUG] call_deferred _try_auto_load scheduled")

func _try_auto_load():
	print("[DEBUG] _try_auto_load called")
	print("[DEBUG] fsm_script_name = ", fsm_script_name)
	
	# First, try to load existing graph JSON
	var load_path = "res://ai_states/" + fsm_script_name + "/" + fsm_script_name + "_graph.json"
	print("[DEBUG] Checking for graph JSON at: ", load_path)
	
	if FileAccess.file_exists(load_path):
		print("🔄 Auto-loading saved graph...")
		_load_graph_from_file()
		
		# Wait for nodes to be loaded
		await get_tree().process_frame
		
		# Auto-sync from generated files if they exist (silently, no confirmation)
		var dir_path = "res://ai_states/" + fsm_script_name + "/"
		if DirAccess.dir_exists_absolute(dir_path):
			print("🔄 Auto-syncing from generated files...")
			_perform_sync_from_files(dir_path)
	else:
		# No graph JSON found, try to recover from generated files
		print("🔍 No saved graph found, scanning for generated FSM files...")
		_try_auto_recover_from_files()

func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		# Auto-save when closing
		var states = _get_all_state_nodes()
		if not states.is_empty():
			_save_graph_to_file()
			print("💾 Auto-saved graph on exit")

func _setup_ui():
	custom_minimum_size = Vector2(0, 400)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# === TOOLBAR (2 rows for better organization) ===
	var toolbar_container = VBoxContainer.new()
	main_vbox.add_child(toolbar_container)
	
	# Row 1: Main actions
	toolbar = HBoxContainer.new()
	toolbar_container.add_child(toolbar)

	var btn_setup = Button.new()
	btn_setup.text = "⚙ Setup"
	btn_setup.tooltip_text = "Configure FSM settings and detect animations"
	btn_setup.pressed.connect(_on_setup_pressed)
	toolbar.add_child(btn_setup)

	toolbar.add_child(VSeparator.new())

	var btn_add_state = Button.new()
	btn_add_state.text = "+ State"
	btn_add_state.tooltip_text = "Add a new state node"
	btn_add_state.pressed.connect(_on_add_state_pressed)
	toolbar.add_child(btn_add_state)

	var btn_add_template = Button.new()
	btn_add_template.text = "📋 Template"
	btn_add_template.tooltip_text = "Add from template"
	btn_add_template.pressed.connect(_on_add_template_pressed)
	toolbar.add_child(btn_add_template)

	var btn_add_transition = Button.new()
	btn_add_transition.text = "→ Transition"
	btn_add_transition.tooltip_text = "Add transition"
	btn_add_transition.pressed.connect(_on_add_transition_pressed)
	toolbar.add_child(btn_add_transition)

	toolbar.add_child(VSeparator.new())

	var btn_auto_arrange = Button.new()
	btn_auto_arrange.text = "📐 Arrange"
	btn_auto_arrange.tooltip_text = "Auto arrange nodes"
	btn_auto_arrange.pressed.connect(_on_auto_arrange_pressed)
	toolbar.add_child(btn_auto_arrange)

	var btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "🔍 Zoom"
	btn_zoom_reset.tooltip_text = "Reset zoom"
	btn_zoom_reset.pressed.connect(_on_zoom_reset_pressed)
	toolbar.add_child(btn_zoom_reset)

	toolbar.add_child(VSeparator.new())

	var btn_validate = Button.new()
	btn_validate.text = "✓ Validate"
	btn_validate.tooltip_text = "Check for errors"
	btn_validate.pressed.connect(_on_validate_pressed)
	toolbar.add_child(btn_validate)
	
	# Row 2: File operations
	var toolbar2 = HBoxContainer.new()
	toolbar_container.add_child(toolbar2)

	var btn_save = Button.new()
	btn_save.text = "� Save & Generate"
	btn_save.tooltip_text = "Generate FSM scripts from the visual graph"
	btn_save.modulate = Color(0.5, 1.0, 0.5)
	btn_save.pressed.connect(_on_save_pressed)
	toolbar2.add_child(btn_save)
	
	var btn_recover = Button.new()
	btn_recover.text = "🔍 Auto-Recover"
	btn_recover.tooltip_text = "Scan for generated FSM files and reconstruct graph"
	btn_recover.modulate = Color(1.0, 0.8, 0.3)
	btn_recover.pressed.connect(_on_recover_pressed)
	toolbar2.add_child(btn_recover)
	
	var btn_sync = Button.new()
	btn_sync.text = "🔄 Sync from Files"
	btn_sync.tooltip_text = "Import code changes from generated state files"
	btn_sync.modulate = Color(0.5, 0.8, 1.0)
	btn_sync.pressed.connect(_on_sync_from_files_pressed)
	toolbar2.add_child(btn_sync)
	
	toolbar2.add_child(VSeparator.new())
	
	# Script name display
	var script_label = Label.new()
	script_label.text = "  Script: "
	toolbar2.add_child(script_label)
	
	var script_name_label = Label.new()
	script_name_label.text = "enemy_fsm"
	script_name_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	toolbar2.add_child(script_name_label)

	# === GRAPH EDIT ===
	graph_edit = GraphEdit.new()
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_edit.right_disconnects = true
	graph_edit.show_zoom_label = true
	graph_edit.minimap_enabled = true
	graph_edit.minimap_opacity = 0.7
	
	# Connect signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)
	graph_edit.popup_request.connect(_on_popup_request)
	
	main_vbox.add_child(graph_edit)

	# === STATUS BAR ===
	var status_bar = HBoxContainer.new()
	main_vbox.add_child(status_bar)
	
	var status_label = Label.new()
	status_label.text = "Ready | Right-click on canvas for quick actions"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar.add_child(status_label)

	# === SETUP WIZARD ===
	setup_wizard = preload("res://addons/omnistate_ai/ui/setup_wizard.gd").new()
	add_child(setup_wizard)
	setup_wizard.confirmed.connect(_on_wizard_confirmed)

	# === TRANSITION DIALOG ===
	transition_dialog = preload("res://addons/omnistate_ai/ui/transition_dialog.gd").new()
	add_child(transition_dialog)
	transition_dialog.confirmed.connect(_on_transition_confirmed)

func _on_setup_pressed():
	setup_wizard.popup_centered()

func _on_wizard_confirmed():
	fsm_script_name = setup_wizard.script_name_input.text
	base_class_name = setup_wizard.get_base_class_name()
	enemy_scene_path = setup_wizard.enemy_scene_input.text
	player_scene_path = setup_wizard.player_scene_input.text
	animation_player_path = setup_wizard.animation_player_path_input.text
	detected_animations = setup_wizard.detected_animations.duplicate()
	
	# Update all existing state nodes with detected animations
	_update_state_animations()
	
	print("✓ FSM Configured!")
	print("  Script: ", fsm_script_name)
	print("  Base Class: ", base_class_name)
	print("  Animations: ", detected_animations)

func _update_state_animations():
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			# Clear existing animations
			node.anim_input.clear()
			node.anim_input.add_item("(None)", 0)
			
			# Add detected animations
			for anim in detected_animations:
				node.add_animation_option(anim)

func _on_add_state_pressed():
	_create_new_state(Vector2(100, 100))

func _create_new_state(pos: Vector2):
	var new_state = StateNodeClass.new()
	new_state.position_offset = pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	new_state
	new_state.state_selected.connect(_on_state_node_selected)
	new_state.state_data_changed.connect(_on_state_data_changed)
	
	# Add detected animations to the new state
	for anim in detected_animations:
		new_state.add_animation_option(anim)
	
	graph_edit.add_child(new_state)
	
	# If this is the first state, make it initial
	if _get_all_state_nodes().size() == 1:
		new_state.is_initial_state_check.button_pressed = true
		new_state._on_initial_state_toggled(true)

func _on_add_transition_pressed():
	var states = _get_all_state_nodes()
	if states.size() < 2:
		_show_notification("Need at least 2 states to create a transition")
		return
	
	transition_dialog.setup_with_states(states)
	transition_dialog.popup_centered()

func _on_transition_confirmed():
	var from_state = transition_dialog.from_state_option.get_item_text(transition_dialog.from_state_option.selected)
	var to_state = transition_dialog.to_state_option.get_item_text(transition_dialog.to_state_option.selected)
	var condition = transition_dialog.condition_input.text
	
	# Find the from_state node and add the transition
	for node in graph_edit.get_children():
		if node is OmniStateNode and node.get_state_name() == from_state:
			node.add_transition_condition(to_state, condition)
			
			# Create visual connection
			var from_node_name = node.name
			var to_node_name = _find_state_node_by_name(to_state)
			if to_node_name != "":
				graph_edit.connect_node(from_node_name, 0, to_node_name, 0)
			break

func _find_state_node_by_name(state_name: String) -> String:
	for node in graph_edit.get_children():
		if node is OmniStateNode and node.get_state_name() == state_name:
			return node.name
	return ""

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Create visual connection
	graph_edit.connect_node(from_node, from_port, to_node, to_port)
	
	# Open dialog to add condition
	var from_state_node = graph_edit.get_node(NodePath(from_node))
	var to_state_node = graph_edit.get_node(NodePath(to_node))
	
	if from_state_node is OmniStateNode and to_state_node is OmniStateNode:
		_prompt_for_transition_condition(from_state_node, to_state_node)

func _prompt_for_transition_condition(from_state: OmniStateNode, to_state: OmniStateNode):
	var dialog = AcceptDialog.new()
	dialog.title = "Transition Condition"
	dialog.min_size = Vector2(400, 200)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Condition for transition from '%s' to '%s':" % [from_state.get_state_name(), to_state.get_state_name()]
	vbox.add_child(label)
	
	var input = LineEdit.new()
	input.placeholder_text = "e.g., player_detected, health < 30, timer > 5.0"
	vbox.add_child(input)
	
	var examples = Label.new()
	examples.text = "Examples:\n• player_in_range\n• health <= 20\n• can_see_player and not is_reloading"
	examples.add_theme_font_size_override("font_size", 10)
	vbox.add_child(examples)
	
	dialog.confirmed.connect(func():
		if input.text != "":
			from_state.add_transition_condition(to_state.get_state_name(), input.text)
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	
	# Remove transition from state node
	var from_state_node = graph_edit.get_node(NodePath(from_node))
	var to_state_node = graph_edit.get_node(NodePath(to_node))
	
	if from_state_node is OmniStateNode and to_state_node is OmniStateNode:
		var to_name = to_state_node.get_state_name()
		from_state_node.transitions = from_state_node.transitions.filter(
			func(t): return t.to_state != to_name
		)
		from_state_node._refresh_transitions_display()

func _on_delete_nodes_request(nodes: Array):
	for node_name in nodes:
		var node = graph_edit.get_node(NodePath(node_name))
		if node:
			node.queue_free()

func _on_node_selected(node: Node):
	if node is OmniStateNode:
		selected_state_node = node

func _on_node_deselected(node: Node):
	if selected_state_node == node:
		selected_state_node = null

func _on_state_node_selected(state_node: OmniStateNode):
	selected_state_node = state_node

func _on_state_data_changed():
	# Could trigger auto-save or validation here
	pass

func _on_add_template_pressed():
	var popup = PopupMenu.new()
	var templates = StateTemplates.get_template_names()
	
	for i in range(templates.size()):
		popup.add_item(templates[i], i)
	
	popup.id_pressed.connect(func(id):
		var template_name = templates[id]
		_create_state_from_template(template_name, Vector2(100, 100))
		popup.queue_free()
	)
	
	add_child(popup)
	popup.popup(Rect2(get_global_mouse_position(), Vector2(200, 300)))

func _create_state_from_template(template_name: String, pos: Vector2):
	var new_state = StateNodeClass.new()
	new_state.position_offset = pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	new_state
	new_state.state_selected.connect(_on_state_node_selected)
	new_state.state_data_changed.connect(_on_state_data_changed)
	
	# Add detected animations
	for anim in detected_animations:
		new_state.add_animation_option(anim)
	
	# Apply template
	StateTemplates.apply_template_to_node(new_state, template_name)
	
	graph_edit.add_child(new_state)
	
	print("✓ Created state from template: ", template_name)

func _on_popup_request(position: Vector2):
	var popup = PopupMenu.new()
	popup.add_item("Add State Here", 0)
	popup.add_item("Add Initial State", 1)
	popup.add_separator()
	
	var templates = StateTemplates.get_template_names()
	var template_submenu = PopupMenu.new()
	template_submenu.name = "Templates"
	
	for i in range(templates.size()):
		template_submenu.add_item(templates[i], i)
	
	template_submenu.id_pressed.connect(func(id):
		var template_name = templates[id]
		_create_state_from_template(template_name, position)
		template_submenu.queue_free()
	)
	
	popup.add_child(template_submenu)
	popup.add_submenu_item("Add from Template", "Templates", 2)
	
	popup.add_separator()
	popup.add_item("Clear All", 3)
	
	popup.id_pressed.connect(func(id):
		match id:
			0:
				_create_new_state(position)
			1:
				var state = StateNodeClass.new()
				state.position_offset = position
				state.is_initial_state_check.button_pressed = true
				state._on_initial_state_toggled(true)
				for anim in detected_animations:
					state.add_animation_option(anim)
				graph_edit.add_child(state)
			3:
				_clear_all_states()
		popup.queue_free()
	)
	
	add_child(popup)
	popup.popup(Rect2(get_global_mouse_position(), Vector2(200, 150)))

func _on_auto_arrange_pressed():
	var states = _get_all_state_nodes()
	if states.is_empty():
		return
	
	# Simple circular arrangement
	var center = Vector2(400, 300)
	var radius = 250
	var angle_step = TAU / states.size()
	
	for i in range(states.size()):
		var angle = i * angle_step
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		states[i].position_offset = pos

func _on_zoom_reset_pressed():
	graph_edit.zoom = 1.0

func _on_validate_pressed():
	var states = _get_all_state_nodes()
	var connections = graph_edit.get_connection_list()
	
	var result = FSMValidator.validate(states, connections)
	var result_text = FSMValidator.format_validation_result(result)
	
	_show_notification(result_text)

func _on_save_pressed():
	# Validate first
	var states = _get_all_state_nodes()
	if states.is_empty():
		_show_notification("No states to save!")
		return
	
	# Save the graph configuration first
	_save_graph_to_file()
	
	print("==================================================")
	print("Generating State Machine...")
	print("==================================================")
	
	# Gather connections
	var connections = graph_edit.get_connection_list()
	
	# Generate FSM
	var generator = FsmGenerator.new()
	generator.generate_fsm(
		fsm_script_name,
		base_class_name,
		states,
		connections,
		enemy_scene_path,
		player_scene_path,
		animation_player_path
	)
	
	print("==================================================")
	print("✓ Generation Complete!")
	print("==================================================")
	
	_show_notification("FSM generated successfully!\nCheck res://ai_states/" + fsm_script_name + "/")

func _on_load_pressed():
	_load_graph_from_file()

func _on_recover_pressed():
	print("[MANUAL RECOVERY] Button clicked")
	_try_auto_recover_from_files()

func _save_graph_to_file():
	var save_data = {
		"fsm_script_name": fsm_script_name,
		"base_class_name": base_class_name,
		"enemy_scene_path": enemy_scene_path,
		"player_scene_path": player_scene_path,
		"animation_player_path": animation_player_path,
		"detected_animations": detected_animations,
		"states": [],
		"connections": graph_edit.get_connection_list()
	}
	
	# Save all state nodes
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			var state_data = {
				"name": node.get_state_name(),
				"position": node.position_offset,
				"is_initial": node.is_initial_state_check.button_pressed,
				"color": node.state_color_picker.color,
				"animation": node.get_selected_animation(),
				"is_dynamic_animation": node.is_dynamic_animation(),
				"enter_code": node.enter_code_input.text,
				"update_code": node.code_input.text,
				"exit_code": node.exit_code_input.text,
				"transitions": node.transitions.duplicate(),
				"behaviors": node.behaviors.duplicate()
			}
			save_data.states.append(state_data)
	
	# Save to file
	var save_path = "res://ai_states/" + fsm_script_name + "/" + fsm_script_name + "_graph.json"
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://ai_states/" + fsm_script_name):
		dir.make_dir_recursive("res://ai_states/" + fsm_script_name)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("✓ Graph saved to: ", save_path)
	else:
		push_error("Failed to save graph to: " + save_path)

func _load_graph_from_file():
	var load_path = "res://ai_states/" + fsm_script_name + "/" + fsm_script_name + "_graph.json"
	
	if not FileAccess.file_exists(load_path):
		_show_notification("No saved graph found at:\n" + load_path)
		return
	
	var file = FileAccess.open(load_path, FileAccess.READ)
	if not file:
		_show_notification("Failed to open graph file!")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		_show_notification("Failed to parse graph file!")
		return
	
	var save_data = json.data
	
	# Clear existing graph
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			node.queue_free()
	
	# Wait for nodes to be freed
	await get_tree().process_frame
	
	# Restore configuration
	fsm_script_name = save_data.get("fsm_script_name", "enemy_fsm")
	base_class_name = save_data.get("base_class_name", "CharacterBody3D")
	enemy_scene_path = save_data.get("enemy_scene_path", "")
	player_scene_path = save_data.get("player_scene_path", "")
	animation_player_path = save_data.get("animation_player_path", "AnimationPlayer")
	detected_animations = save_data.get("detected_animations", [])
	
	# Restore state nodes
	var node_name_map = {}  # Map state names to node names for connections
	
	for state_data in save_data.get("states", []):
		var new_state = StateNodeClass.new()
		new_state.position_offset = Vector2(state_data.position.x, state_data.position.y)
		new_state
		new_state.state_selected.connect(_on_state_node_selected)
		new_state.state_data_changed.connect(_on_state_data_changed)
		
		# Add animations
		for anim in detected_animations:
			new_state.add_animation_option(anim)
		
		graph_edit.add_child(new_state)
		
		# Restore state data
		new_state.state_name_input.text = state_data.get("name", "state")
		new_state.is_initial_state_check.button_pressed = state_data.get("is_initial", false)
		new_state.state_color_picker.color = Color(
			state_data.color.r,
			state_data.color.g,
			state_data.color.b,
			state_data.color.a
		) if state_data.has("color") else Color.WHITE
		
		# Restore animation selection
		var anim_name = state_data.get("animation", "")
		if anim_name != "":
			for i in range(new_state.anim_input.item_count):
				if new_state.anim_input.get_item_text(i) == anim_name:
					new_state.anim_input.selected = i
					break
		
		# Restore code
		new_state.enter_code_input.text = state_data.get("enter_code", "# Enter state logic\npass")
		new_state.code_input.text = state_data.get("update_code", "# Update state logic\npass")
		new_state.exit_code_input.text = state_data.get("exit_code", "# Exit state logic\npass")
		
		# Restore transitions
		new_state.transitions = state_data.get("transitions", [])
		new_state._refresh_transitions_display()
		
		# Restore behaviors
		new_state.behaviors = state_data.get("behaviors", [])
		
		# Update visual state
		new_state._on_initial_state_toggled(new_state.is_initial_state_check.button_pressed)
		
		# Map state name to node name for connections
		node_name_map[state_data.get("name", "")] = new_state.name
	
	# Wait for nodes to be added
	await get_tree().process_frame
	
	# Restore connections
	for connection in save_data.get("connections", []):
		var from_node = connection.get("from_node", "")
		var to_node = connection.get("to_node", "")
		var from_port = connection.get("from_port", 0)
		var to_port = connection.get("to_port", 0)
		
		if from_node != "" and to_node != "":
			graph_edit.connect_node(from_node, from_port, to_node, to_port)
	
	print("✓ Graph loaded from: ", load_path)
	_show_notification("Graph loaded successfully!")

func _on_sync_from_files_pressed():
	var states = _get_all_state_nodes()
	if states.is_empty():
		_show_notification("No states in the graph to sync!")
		return
	
	var dir_path = "res://ai_states/" + fsm_script_name + "/"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		_show_notification("No generated files found at:\n" + dir_path)
		return
	
	# Show confirmation dialog
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "This will import code from generated state files and overwrite the code in your visual nodes.\n\nAny unsaved changes in the visual editor will be replaced.\n\nContinue?"
	confirm.title = "Sync from Files"
	confirm.confirmed.connect(func():
		_perform_sync_from_files(dir_path)
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _perform_sync_from_files(dir_path: String):
	var states = _get_all_state_nodes()
	var synced_count = 0
	var failed_states = []
	
	for state_node in states:
		var state_name = state_node.get_state_name()
		var file_name = state_name.to_snake_case() + "_state.gd"
		var file_path = dir_path + file_name
		
		if not FileAccess.file_exists(file_path):
			failed_states.append(state_name + " (file not found)")
			continue
		
		var file = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			failed_states.append(state_name + " (cannot open)")
			continue
		
		var file_content = file.get_as_text()
		file.close()
		
		# Extract code from the generated file
		var enter_code = _extract_function_body(file_content, "func enter()")
		var update_code = _extract_function_body(file_content, "func update(delta: float)")
		var exit_code = _extract_function_body(file_content, "func exit()")
		
		# Update the state node
		if enter_code != null:
			state_node.enter_code_input.text = enter_code
		if update_code != null:
			state_node.code_input.text = update_code
		if exit_code != null:
			state_node.exit_code_input.text = exit_code
		
		synced_count += 1
		print("✓ Synced: ", state_name)
	
	# Show result
	var message = "Synced %d state(s) from generated files!" % synced_count
	if not failed_states.is_empty():
		message += "\n\nFailed to sync:\n• " + "\n• ".join(failed_states)
	
	_show_notification(message)
	
	# Auto-save the updated graph
	_save_graph_to_file()
	print("💾 Auto-saved graph after sync")

func _extract_function_body(file_content: String, function_signature: String):
	# Try to find the function with exact signature first
	var func_start = file_content.find(function_signature)
	
	# If not found, try flexible matching for old format
	if func_start == -1:
		# Extract function name from signature (e.g., "enter" from "func enter()")
		var func_name_start = function_signature.find("func ") + 5
		var func_name_end = function_signature.find("(", func_name_start)
		if func_name_end != -1:
			var func_name = function_signature.substr(func_name_start, func_name_end - func_name_start)
			# Try to find any function with this name (old format: func enter(owner):)
			var search_pattern = "func " + func_name + "("
			func_start = file_content.find(search_pattern)
			print("[DEBUG] Flexible search for '", search_pattern, "' result: ", func_start)
	
	if func_start == -1:
		print("[DEBUG] Function not found: ", function_signature)
		return ""
	
	# Find the start of the function body (after the colon and newline)
	var body_start = file_content.find(":", func_start)
	if body_start == -1:
		return ""
	
	body_start = file_content.find("\n", body_start) + 1
	
	# Extract lines until we hit the next function or end of class
	var lines = []
	var current_pos = body_start
	var indent_level = -1
	
	print("[DEBUG] Starting extraction from position: ", body_start)
	
	while current_pos < file_content.length():
		var line_end = file_content.find("\n", current_pos)
		if line_end == -1:
			line_end = file_content.length()
		
		var line = file_content.substr(current_pos, line_end - current_pos)
		
		# Detect indentation level from first non-empty line
		if indent_level == -1 and line.strip_edges() != "":
			indent_level = 0
			for c in line:
				if c == '\t':
					indent_level += 1
				else:
					break
			print("[DEBUG] Detected indent level: ", indent_level)
		
		# Check if we've reached the next function or end of indented block
		if line.strip_edges().begins_with("func ") and current_pos > body_start:
			print("[DEBUG] Hit next function, stopping extraction")
			break
		
		# Check if line is less indented (end of function)
		if line.strip_edges() != "":
			var current_indent = 0
			for c in line:
				if c == '\t':
					current_indent += 1
				else:
					break
			
			if current_indent < indent_level and current_indent == 0:
				print("[DEBUG] Hit less indented line, stopping extraction")
				break
		
		# Remove one level of indentation and add to lines
		if line.begins_with("\t") and indent_level > 0:
			lines.append(line.substr(1))
		else:
			lines.append(line)
		
		current_pos = line_end + 1
	
	print("[DEBUG] Extracted ", lines.size(), " lines")
	
	# Join lines and clean up
	var result = "\n".join(lines).strip_edges()
	
	# Remove common placeholder comments
	if result == "pass" or result == "# Custom enter logic\npass" or result == "# Custom update logic\npass" or result == "# Custom exit logic\npass":
		return "pass"
	
	# Remove "# Custom X logic" comments that the generator adds
	result = result.replace("# Custom enter logic\n", "")
	result = result.replace("# Custom update logic\n", "")
	result = result.replace("# Custom exit logic\n", "")
	
	return result if result != "" else "pass"

func _clear_all_states():
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to clear all states?"
	confirm.confirmed.connect(func():
		for node in graph_edit.get_children():
			if node is OmniStateNode:
				node.queue_free()
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _get_all_state_nodes() -> Array:
	var states = []
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			states.append(node)
	return states

func _show_notification(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.min_size = Vector2(400, 150)
	add_child(dialog)
	dialog.popup_centered()
	
	# Auto-close after 3 seconds for success messages
	if message.begins_with("✓"):
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(dialog):
			dialog.queue_free()

func _try_auto_recover_from_files():
	"""Scan ai_states folder for generated FSM files and reconstruct the visual graph"""
	print("[DEBUG] _try_auto_recover_from_files called")
	
	var ai_states_dir = DirAccess.open("res://ai_states/")
	if not ai_states_dir:
		print("📁 No ai_states folder found")
		print("[DEBUG] Failed to open res://ai_states/")
		return
	
	print("[DEBUG] Successfully opened res://ai_states/")
	
	# Find all FSM directories
	var fsm_dirs = []
	ai_states_dir.list_dir_begin()
	var dir_name = ai_states_dir.get_next()
	print("[DEBUG] Starting directory scan...")
	
	while dir_name != "":
		print("[DEBUG] Found: ", dir_name, " (is_dir: ", ai_states_dir.current_is_dir(), ")")
		if ai_states_dir.current_is_dir() and not dir_name.begins_with("."):
			fsm_dirs.append(dir_name)
			print("[DEBUG] Added to fsm_dirs: ", dir_name)
		dir_name = ai_states_dir.get_next()
	ai_states_dir.list_dir_end()
	
	print("[DEBUG] Total FSM directories found: ", fsm_dirs.size())
	print("[DEBUG] FSM directories: ", fsm_dirs)
	
	if fsm_dirs.is_empty():
		print("📁 No FSM directories found in ai_states/")
		return
	
	# If multiple FSMs found, use the first one (or could prompt user)
	var fsm_name = fsm_dirs[0]
	var fsm_path = "res://ai_states/" + fsm_name + "/"
	
	print("🔍 Found FSM: " + fsm_name)
	print("📂 Scanning: " + fsm_path)
	
	# Check if main FSM file exists
	var main_file_path = fsm_path + fsm_name + ".gd"
	if not FileAccess.file_exists(main_file_path):
		print("❌ Main FSM file not found: " + main_file_path)
		return
	
	# Read main FSM file to extract configuration
	var main_file = FileAccess.open(main_file_path, FileAccess.READ)
	if not main_file:
		print("❌ Cannot open main FSM file")
		return
	
	var main_content = main_file.get_as_text()
	main_file.close()
	
	# Extract configuration from main file
	var recovered_config = _extract_fsm_config(main_content, fsm_name)
	
	# Apply recovered configuration
	fsm_script_name = recovered_config.script_name
	base_class_name = recovered_config.base_class
	
	print("✓ Recovered config: " + fsm_script_name + " (extends " + base_class_name + ")")
	
	# Find all state files
	var state_files = []
	var dir = DirAccess.open(fsm_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("_state.gd"):
				state_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if state_files.is_empty():
		print("❌ No state files found")
		return
	
	print("📄 Found " + str(state_files.size()) + " state files")
	
	# Extract transitions from main file
	var all_transitions = _extract_transitions_from_main(main_content)
	
	# Reconstruct states
	var recovered_states = []
	var state_name_to_node = {}
	
	for state_file in state_files:
		var state_path = fsm_path + state_file
		var state_data = _extract_state_data(state_path, state_file)
		if state_data:
			recovered_states.append(state_data)
			print("  ✓ Recovered state: " + state_data.name)
	
	# Create visual nodes
	var x_offset = 100.0
	var y_offset = 100.0
	var spacing = 250.0
	var col = 0
	var row = 0
	var max_cols = 3
	
	for state_data in recovered_states:
		var new_state = StateNodeClass.new()
		new_state.position_offset = Vector2(x_offset + (col * spacing), y_offset + (row * spacing))
		new_state
		new_state.state_selected.connect(_on_state_node_selected)
		new_state.state_data_changed.connect(_on_state_data_changed)
		
		graph_edit.add_child(new_state)
		
		# Set state data
		new_state.state_name_input.text = state_data.name
		new_state.enter_code_input.text = state_data.enter_code
		new_state.code_input.text = state_data.update_code
		new_state.exit_code_input.text = state_data.exit_code
		
		# Set animation if found
		if state_data.animation != "":
			new_state.anim_input.add_item(state_data.animation)
			new_state.anim_input.selected = new_state.anim_input.item_count - 1
		
		# Mark first state as initial
		if recovered_states[0] == state_data:
			new_state.is_initial_state_check.button_pressed = true
			new_state._on_initial_state_toggled(true)
		
		# Store for connections
		state_name_to_node[state_data.name] = new_state.name
		
		# Update grid position
		col += 1
		if col >= max_cols:
			col = 0
			row += 1
	
	# Wait for nodes to be added
	await get_tree().process_frame
	
	# Create connections based on transitions
	for trans in all_transitions:
		var from_node_name = state_name_to_node.get(trans.from_state, "")
		var to_node_name = state_name_to_node.get(trans.to_state, "")
		
		if from_node_name != "" and to_node_name != "":
			graph_edit.connect_node(from_node_name, 0, to_node_name, 0)
			
			# Add transition to state node
			var from_node = graph_edit.get_node(NodePath(from_node_name))
			if from_node is OmniStateNode:
				from_node.add_transition_condition(trans.to_state, trans.condition)
	
	# Save the recovered graph
	_save_graph_to_file()
	
	print("✅ Successfully recovered FSM from generated files!")
	print("   States: " + str(recovered_states.size()))
	print("   Transitions: " + str(all_transitions.size()))
	
	_show_notification("✓ FSM Recovered!\n\nRecovered " + str(recovered_states.size()) + " states and " + str(all_transitions.size()) + " transitions from generated files.\n\nGraph has been saved.")

func _extract_fsm_config(main_content: String, fsm_name: String) -> Dictionary:
	"""Extract FSM configuration from main file"""
	var config = {
		"script_name": fsm_name,
		"base_class": "CharacterBody3D"
	}
	
	# Extract base class
	var extends_pos = main_content.find("extends ")
	if extends_pos != -1:
		var line_end = main_content.find("\n", extends_pos)
		var extends_line = main_content.substr(extends_pos, line_end - extends_pos)
		var base_class = extends_line.replace("extends ", "").strip_edges()
		config.base_class = base_class
	
	return config

func _extract_state_data(state_path: String, file_name: String) -> Dictionary:
	"""Extract state data from state file"""
	var file = FileAccess.open(state_path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	# Extract state name from file name
	var state_name = file_name.replace("_state.gd", "")
	
	# Extract animation constant
	var animation = ""
	var anim_pos = content.find("const ANIMATION")
	if anim_pos != -1:
		var line_end = content.find("\n", anim_pos)
		var anim_line = content.substr(anim_pos, line_end - anim_pos)
		var quote_start = anim_line.find("\"")
		if quote_start != -1:
			var quote_end = anim_line.find("\"", quote_start + 1)
			if quote_end != -1:
				animation = anim_line.substr(quote_start + 1, quote_end - quote_start - 1)
	
	print("[DEBUG] Extracting code from: ", state_path)
	
	# Extract function bodies (flexible matching for old and new formats)
	var enter_code = _extract_function_body(content, "func enter()")
	var update_code = _extract_function_body(content, "func update(delta: float)")
	var exit_code = _extract_function_body(content, "func exit()")
	
	print("[DEBUG] Extracted enter_code length: ", enter_code.length())
	print("[DEBUG] Extracted update_code length: ", update_code.length())
	print("[DEBUG] Extracted exit_code length: ", exit_code.length())
	
	return {
		"name": state_name,
		"animation": animation,
		"enter_code": enter_code if enter_code else "pass",
		"update_code": update_code if update_code else "pass",
		"exit_code": exit_code if exit_code else "pass"
	}

func _extract_transitions_from_main(main_content: String) -> Array:
	"""Extract all transitions from main FSM file"""
	var transitions = []
	
	# Find all transition blocks in _check_transitions function
	var lines = main_content.split("\n")
	var current_from_state = ""
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		
		# Detect current state being checked
		if line.begins_with("if current_state_name == \""):
			var quote_start = line.find("\"")
			var quote_end = line.find("\"", quote_start + 1)
			if quote_start != -1 and quote_end != -1:
				current_from_state = line.substr(quote_start + 1, quote_end - quote_start - 1)
		
		# Detect transition target
		if line.begins_with("\"to\": \"") and current_from_state != "":
			var quote_start = line.find("\"to\": \"") + 7
			var quote_end = line.find("\"", quote_start)
			if quote_end != -1:
				var to_state = line.substr(quote_start, quote_end - quote_start)
				
				# Find condition (look backwards)
				var condition = ""
				for j in range(i - 1, max(0, i - 10), -1):
					var prev_line = lines[j].strip_edges()
					if prev_line.begins_with("if _evaluate_condition(\""):
						var cond_start = prev_line.find("\"") + 1
						var cond_end = prev_line.find("\")", cond_start)
						if cond_end != -1:
							condition = prev_line.substr(cond_start, cond_end - cond_start)
						break
				
				transitions.append({
					"from_state": current_from_state,
					"to_state": to_state,
					"condition": condition
				})
	
	return transitions
