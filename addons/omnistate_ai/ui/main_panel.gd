@tool
extends Control

# UI Components
var toolbar: HBoxContainer
var graph_edit: GraphEdit
var setup_wizard
var transition_dialog
var minimap: GraphEditMinimap

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
	_setup_ui()

func _setup_ui():
	custom_minimum_size = Vector2(0, 400)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# === TOOLBAR ===
	toolbar = HBoxContainer.new()
	main_vbox.add_child(toolbar)

	var btn_setup = Button.new()
	btn_setup.text = "⚙ Setup Wizard"
	btn_setup.tooltip_text = "Configure FSM settings and detect animations"
	btn_setup.pressed.connect(_on_setup_pressed)
	toolbar.add_child(btn_setup)

	toolbar.add_child(VSeparator.new())

	var btn_add_state = Button.new()
	btn_add_state.text = "+ Add State"
	btn_add_state.tooltip_text = "Add a new state node to the graph"
	btn_add_state.pressed.connect(_on_add_state_pressed)
	toolbar.add_child(btn_add_state)

	var btn_add_template = Button.new()
	btn_add_template.text = "📋 Add Template"
	btn_add_template.tooltip_text = "Add a state from a template"
	btn_add_template.pressed.connect(_on_add_template_pressed)
	toolbar.add_child(btn_add_template)

	var btn_add_transition = Button.new()
	btn_add_transition.text = "→ Add Transition"
	btn_add_transition.tooltip_text = "Add a transition between states"
	btn_add_transition.pressed.connect(_on_add_transition_pressed)
	toolbar.add_child(btn_add_transition)

	toolbar.add_child(VSeparator.new())

	var btn_auto_arrange = Button.new()
	btn_auto_arrange.text = "📐 Auto Arrange"
	btn_auto_arrange.tooltip_text = "Automatically arrange nodes"
	btn_auto_arrange.pressed.connect(_on_auto_arrange_pressed)
	toolbar.add_child(btn_auto_arrange)

	var btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "🔍 Reset Zoom"
	btn_zoom_reset.pressed.connect(_on_zoom_reset_pressed)
	toolbar.add_child(btn_zoom_reset)

	toolbar.add_child(VSeparator.new())

	var btn_save = Button.new()
	btn_save.text = "💾 Save & Generate"
	btn_save.tooltip_text = "Generate FSM scripts from the visual graph"
	btn_save.modulate = Color(0.5, 1.0, 0.5)
	btn_save.pressed.connect(_on_save_pressed)
	toolbar.add_child(btn_save)

	var btn_load = Button.new()
	btn_load.text = "📂 Load FSM"
	btn_load.tooltip_text = "Load an existing FSM configuration"
	btn_load.pressed.connect(_on_load_pressed)
	toolbar.add_child(btn_load)

	toolbar.add_child(VSeparator.new())

	var btn_validate = Button.new()
	btn_validate.text = "✓ Validate"
	btn_validate.tooltip_text = "Check for errors in the state machine"
	btn_validate.pressed.connect(_on_validate_pressed)
	toolbar.add_child(btn_validate)

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
	new_state.close_request.connect(func(): new_state.queue_free())
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
	new_state.close_request.connect(func(): new_state.queue_free())
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
	
	print("=" * 50)
	print("Generating State Machine...")
	print("=" * 50)
	
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
	
	print("=" * 50)
	print("✓ Generation Complete!")
	print("=" * 50)
	
	_show_notification("FSM generated successfully!\nCheck res://ai_states/" + fsm_script_name + "/")

func _on_load_pressed():
	_show_notification("Load functionality coming soon!")
	# TODO: Implement loading saved FSM configurations

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
