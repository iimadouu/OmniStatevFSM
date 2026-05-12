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
var blackboard_vars: Dictionary = {}  # Stores blackboard variables

# State tracking
var selected_state_node: OmniStateNode = null
var connection_from_node: String = ""

# Undo/Redo
var undo_redo: EditorUndoRedoManager = null

# Auto-save
var auto_save_timer: Timer = null
var has_unsaved_changes: bool = false

func _ready():
	print("[DEBUG] main_panel _ready() called")
	_setup_ui()
	print("[DEBUG] _setup_ui() completed")
	
	# Setup auto-save timer (every 30 seconds)
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)
	
	# Try to auto-load existing graph
	call_deferred("_try_auto_load")
	print("[DEBUG] call_deferred _try_auto_load scheduled")

func _on_auto_save_timer_timeout():
	"""Periodic auto-save every 30 seconds if there are unsaved changes"""
	if has_unsaved_changes:
		var states = _get_all_state_nodes()
		if not states.is_empty():
			_save_graph_to_file()
			has_unsaved_changes = false
			print("💾 Auto-saved graph (periodic)")

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
	
	var btn_blackboard = Button.new()
	btn_blackboard.text = "📊 Blackboard"
	btn_blackboard.tooltip_text = "Manage shared variables"
	btn_blackboard.pressed.connect(_on_blackboard_pressed)
	toolbar.add_child(btn_blackboard)

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
	btn_auto_arrange.tooltip_text = "Auto arrange nodes in hierarchical layout"
	btn_auto_arrange.pressed.connect(_on_auto_arrange_pressed)
	toolbar.add_child(btn_auto_arrange)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "🔍+"
	btn_zoom_in.tooltip_text = "Zoom in"
	btn_zoom_in.pressed.connect(_on_zoom_in_pressed)
	toolbar.add_child(btn_zoom_in)
	
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "🔍-"
	btn_zoom_out.tooltip_text = "Zoom out"
	btn_zoom_out.pressed.connect(_on_zoom_out_pressed)
	toolbar.add_child(btn_zoom_out)

	var btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "🔍 Reset"
	btn_zoom_reset.tooltip_text = "Reset zoom to 100%"
	btn_zoom_reset.pressed.connect(_on_zoom_reset_pressed)
	toolbar.add_child(btn_zoom_reset)
	
	var btn_fit_view = Button.new()
	btn_fit_view.text = "⊡ Fit"
	btn_fit_view.tooltip_text = "Fit all nodes in view"
	btn_fit_view.pressed.connect(_on_fit_view_pressed)
	toolbar.add_child(btn_fit_view)

	toolbar.add_child(VSeparator.new())

	var btn_validate = Button.new()
	btn_validate.text = "✓ Validate"
	btn_validate.tooltip_text = "Check for errors"
	btn_validate.pressed.connect(_on_validate_pressed)
	toolbar.add_child(btn_validate)
	
	var btn_toggle_minimap = Button.new()
	btn_toggle_minimap.text = "🗺"
	btn_toggle_minimap.tooltip_text = "Toggle minimap"
	btn_toggle_minimap.pressed.connect(_on_toggle_minimap_pressed)
	toolbar.add_child(btn_toggle_minimap)
	
	var btn_show_connections = Button.new()
	btn_show_connections.text = "🔗 Info"
	btn_show_connections.tooltip_text = "Show all connections and transitions"
	btn_show_connections.pressed.connect(_on_show_connections_pressed)
	toolbar.add_child(btn_show_connections)
	
	# Row 2: File operations
	var toolbar2 = HBoxContainer.new()
	toolbar_container.add_child(toolbar2)

	var btn_save = Button.new()
	btn_save.text = "💾 Save Graph"
	btn_save.tooltip_text = "Save the visual graph (auto-saves every 30s)"
	btn_save.modulate = Color(0.7, 0.9, 1.0)
	btn_save.pressed.connect(_on_manual_save_pressed)
	toolbar2.add_child(btn_save)
	
	var btn_generate = Button.new()
	btn_generate.text = "⚙ Generate Code"
	btn_generate.tooltip_text = "Generate FSM scripts from the visual graph"
	btn_generate.modulate = Color(0.5, 1.0, 0.5)
	btn_generate.pressed.connect(_on_save_pressed)
	toolbar2.add_child(btn_generate)
	
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
	script_name_label.name = "ScriptNameLabel"  # Give it a name so we can update it
	script_name_label.text = fsm_script_name
	script_name_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	toolbar2.add_child(script_name_label)

	# === GRAPH EDIT ===
	graph_edit = GraphEdit.new()
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_edit.right_disconnects = true
	graph_edit.show_zoom_label = true
	graph_edit.minimap_enabled = true
	graph_edit.minimap_opacity = 0.7
	graph_edit.minimap_size = Vector2(200, 150)
	
	# Enhanced visual settings
	graph_edit.connection_lines_curvature = 0.5  # Smoother curves
	graph_edit.connection_lines_thickness = 2.0
	graph_edit.connection_lines_antialiased = true
	
	# Zoom settings
	graph_edit.zoom_min = 0.2
	graph_edit.zoom_max = 2.0
	graph_edit.zoom_step = 1.1
	
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
	# Populate wizard with current values before showing
	setup_wizard.script_name_input.text = fsm_script_name
	setup_wizard.enemy_scene_input.text = enemy_scene_path
	setup_wizard.player_scene_input.text = player_scene_path
	setup_wizard.animation_player_path_input.text = animation_player_path
	
	# Set base class selection
	var base_class_names = ["CharacterBody3D", "CharacterBody2D", "Node3D", "Node2D", "Node"]
	var base_class_index = base_class_names.find(base_class_name)
	if base_class_index != -1:
		setup_wizard.base_class_option.selected = base_class_index
	
	setup_wizard.popup_centered()

func _on_blackboard_pressed():
	_show_blackboard_dialog()

func _show_blackboard_dialog():
	# Remove any existing blackboard dialogs first
	var found_existing = false
	for child in get_children():
		if child is Window and child.title == "Blackboard Variables":
			found_existing = true
			child.queue_free()
	
	if found_existing:
		await get_tree().process_frame
	
	var dialog = Window.new()
	dialog.title = "Blackboard Variables"
	dialog.size = Vector2i(600, 500)
	dialog.transient = true
	dialog.exclusive = false
	
	dialog.close_requested.connect(func():
		dialog.queue_free()
	)
	
	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	dialog.add_child(vb)
	
	var desc = Label.new()
	desc.text = "Shared variables accessible by all states via blackboard.get() / blackboard.set()"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color.GRAY)
	vb.add_child(desc)
	
	vb.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	
	var vars_list = VBoxContainer.new()
	scroll.add_child(vars_list)
	
	if blackboard_vars.is_empty():
		var placeholder = Label.new()
		placeholder.text = "No variables defined yet. Add one below."
		placeholder.add_theme_color_override("font_color", Color.GRAY)
		vars_list.add_child(placeholder)
	else:
		for var_name in blackboard_vars.keys():
			var item = HBoxContainer.new()
			vars_list.add_child(item)
			
			var name_lbl = Label.new()
			name_lbl.text = var_name
			name_lbl.custom_minimum_size.x = 150
			item.add_child(name_lbl)
			
			var type_lbl = Label.new()
			var value = blackboard_vars[var_name]
			var type_str = ""
			if value is bool:
				type_str = "bool"
			elif value is int:
				type_str = "int"
			elif value is float:
				type_str = "float"
			elif value is String:
				type_str = "String"
			elif value is Vector2:
				type_str = "Vector2"
			elif value is Vector3:
				type_str = "Vector3"
			elif value is Array:
				type_str = "Array"
			elif value is Dictionary:
				type_str = "Dictionary"
			elif value is Node:
				type_str = "Node"
			else:
				type_str = "Variant"
			type_lbl.text = "(" + type_str + ")"
			type_lbl.custom_minimum_size.x = 100
			type_lbl.add_theme_color_override("font_color", Color.CYAN)
			item.add_child(type_lbl)
			
			var value_lbl = Label.new()
			value_lbl.text = " = " + str(value)
			value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.add_child(value_lbl)
			
			var del_btn = Button.new()
			del_btn.text = "×"
			del_btn.custom_minimum_size.x = 30
			del_btn.pressed.connect(func():
				blackboard_vars.erase(var_name)
				print("✓ Removed blackboard variable: ", var_name)
				_show_blackboard_dialog()
			)
			item.add_child(del_btn)
	
	vb.add_child(HSeparator.new())
	
	var add_label = Label.new()
	add_label.text = "Add New Variable:"
	add_label.add_theme_font_size_override("font_size", 12)
	vb.add_child(add_label)
	
	var add_hbox = HBoxContainer.new()
	vb.add_child(add_hbox)
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "variable_name"
	name_input.custom_minimum_size.x = 150
	add_hbox.add_child(name_input)
	
	var type_option = OptionButton.new()
	type_option.add_item("bool", 0)
	type_option.add_item("int", 1)
	type_option.add_item("float", 2)
	type_option.add_item("String", 3)
	type_option.add_item("Vector2", 4)
	type_option.add_item("Vector3", 5)
	type_option.add_item("Array", 6)
	type_option.add_item("Dictionary", 7)
	type_option.add_item("Node", 8)
	add_hbox.add_child(type_option)
	
	var value_input = LineEdit.new()
	value_input.placeholder_text = "default_value"
	value_input.custom_minimum_size.x = 150
	add_hbox.add_child(value_input)
	
	var add_btn = Button.new()
	add_btn.text = "+ Add"
	add_btn.pressed.connect(func():
		var var_name = name_input.text.strip_edges()
		if var_name == "":
			print("⚠ Variable name cannot be empty")
			return
		
		if blackboard_vars.has(var_name):
			print("⚠ Variable already exists: ", var_name)
			return
		
		var value = value_input.text.strip_edges()
		var final_value
		
		match type_option.selected:
			0: final_value = value.to_lower() == "true"
			1: final_value = int(value) if value != "" else 0
			2: final_value = float(value) if value != "" else 0.0
			3: final_value = value
			4: final_value = Vector2.ZERO
			5: final_value = Vector3.ZERO
			6: final_value = []  # Empty array
			7: final_value = {}  # Empty dictionary
			8: final_value = null  # Node reference (null by default)
		
		blackboard_vars[var_name] = final_value
		print("✓ Added blackboard variable: ", var_name, " = ", final_value)
		_show_blackboard_dialog()
	)
	add_hbox.add_child(add_btn)
	
	vb.add_child(HSeparator.new())
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): 
		dialog.queue_free()
	)
	vb.add_child(close_btn)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_wizard_confirmed():
	fsm_script_name = setup_wizard.script_name_input.text
	base_class_name = setup_wizard.get_base_class_name()
	enemy_scene_path = setup_wizard.enemy_scene_input.text
	player_scene_path = setup_wizard.player_scene_input.text
	animation_player_path = setup_wizard.animation_player_path_input.text
	detected_animations = setup_wizard.detected_animations.duplicate()
	
	# Mark as changed
	has_unsaved_changes = true
	
	# Update script name label in toolbar
	_update_script_name_label()
	
	# Update all existing state nodes with detected animations
	_update_state_animations()
	
	print("✓ FSM Configured!")
	print("  Script: ", fsm_script_name)
	print("  Base Class: ", base_class_name)
	print("  Animations: ", detected_animations)

func _update_script_name_label():
	"""Update the script name display in the toolbar"""
	if toolbar:
		var label = toolbar.get_parent().get_node_or_null("HBoxContainer/ScriptNameLabel")
		if label:
			label.text = fsm_script_name

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
	new_state.state_selected.connect(_on_state_node_selected)
	new_state.state_data_changed.connect(_on_state_data_changed)
	
	# Add detected animations to the new state
	for anim in detected_animations:
		new_state.add_animation_option(anim)
	
	graph_edit.add_child(new_state)
	
	# Mark as changed
	has_unsaved_changes = true
	
	# If this is the first state, make it initial
	if _get_all_state_nodes().size() == 1:
		new_state.is_initial_state_check.button_pressed = true
		new_state.is_initial_state_check.toggled.emit(true)

func _on_add_transition_pressed():
	var states = _get_all_state_nodes()
	if states.size() < 2:
		_show_notification("Need at least 2 states to create a transition")
		return
	
	transition_dialog.setup_with_states(states)
	transition_dialog.popup_centered()

func _on_transition_confirmed():
	var data = transition_dialog.get_transition_data()
	var from_state = data.from_state
	var to_state = data.to_state

	var settings = {
		"priority":      data.priority,
		"delay":         data.delay,
		"cooldown":      data.cooldown,
		"can_interrupt": data.can_interrupt,
		"blend_time":    data.blend_time,
		"custom_code":   data.custom_code,
		"debug_log":     data.debug_log,
		"debug_label":   data.debug_label,
	}

	if from_state == "[ANY]":
		# Add this transition to every state node (except the target itself)
		var added = 0
		var skipped = 0
		for node in graph_edit.get_children():
			if not (node is OmniStateNode):
				continue
			if node.get_state_name() == to_state:
				continue  # skip self-loop on the target
			# Skip if this state already has a transition to the target
			var already_has = false
			for t in node.transitions:
				if t.to_state == to_state:
					already_has = true
					break
			if already_has:
				skipped += 1
				continue
			node.add_transition_condition(to_state, data.condition, settings)
			# Visual connection from each state to the target
			var to_node_name = _find_state_node_by_name(to_state)
			if to_node_name != "" and node.name != to_node_name:
				var already_connected = false
				for conn in graph_edit.get_connection_list():
					if conn.from_node == node.name and conn.to_node == to_node_name:
						already_connected = true
						break
				if not already_connected:
					graph_edit.connect_node(node.name, 0, to_node_name, 0)
			added += 1
		has_unsaved_changes = true
		var msg = "✓ [ANY] → %s added to %d states!" % [to_state, added]
		if skipped > 0:
			msg += "\n(%d already had this transition, skipped)" % skipped
		_show_notification(msg)
		return

	# Normal single-state transition
	for node in graph_edit.get_children():
		if node is OmniStateNode and node.get_state_name() == from_state:
			# Check for duplicate transition (same from→to already exists)
			for i in range(node.transitions.size()):
				if node.transitions[i].to_state == to_state:
					# Duplicate found — show warning with edit option
					_show_duplicate_connection_dialog(node.name, _find_state_node_by_name(to_state))
					return
			node.add_transition_condition(to_state, data.condition, settings)
			var from_node_name = node.name
			var to_node_name = _find_state_node_by_name(to_state)
			if to_node_name != "":
				graph_edit.connect_node(from_node_name, 0, to_node_name, 0)
			has_unsaved_changes = true
			break

func _find_state_node_by_name(state_name: String) -> String:
	for node in graph_edit.get_children():
		if node is OmniStateNode and node.get_state_name() == state_name:
			return node.name
	return ""

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Check for duplicate visual connection
	for conn in graph_edit.get_connection_list():
		if conn.from_node == from_node and conn.to_node == to_node:
			# Already connected — show duplicate warning
			_show_duplicate_connection_dialog(from_node, to_node)
			return

	# Create visual connection
	graph_edit.connect_node(from_node, from_port, to_node, to_port)
	has_unsaved_changes = true

	var from_state_node = graph_edit.get_node(NodePath(from_node))
	var to_state_node = graph_edit.get_node(NodePath(to_node))

	if from_state_node is OmniStateNode and to_state_node is OmniStateNode:
		_prompt_for_transition_condition(from_state_node, to_state_node)
		_highlight_connection(from_node, to_node)

func _show_duplicate_connection_dialog(from_node: StringName, to_node: StringName):
	"""Warn the user about a duplicate connection and offer to edit the existing transition."""
	var from_state = graph_edit.get_node(NodePath(from_node))
	var to_state   = graph_edit.get_node(NodePath(to_node))
	if not (from_state is OmniStateNode and to_state is OmniStateNode):
		return

	var from_name = from_state.get_state_name()
	var to_name   = to_state.get_state_name()

	# Find the existing transition index on the from_state node
	var existing_idx = -1
	for i in range(from_state.transitions.size()):
		if from_state.transitions[i].to_state == to_name:
			existing_idx = i
			break

	var dlg = Window.new()
	dlg.title = "Duplicate Connection"
	dlg.size = Vector2i(420, 180)
	dlg.transient = true
	dlg.exclusive = true
	add_child(dlg)

	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	dlg.add_child(vb)

	var lbl = Label.new()
	lbl.text = "A connection from  \"%s\"  →  \"%s\"  already exists." % [from_name, to_name]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(lbl)

	if existing_idx >= 0:
		var trans = from_state.transitions[existing_idx]
		var info = Label.new()
		info.text = "Condition: %s   [Priority: %d]" % [trans.get("condition", "(none)"), trans.get("priority", 10)]
		info.add_theme_color_override("font_color", Color.YELLOW)
		info.add_theme_font_size_override("font_size", 11)
		vb.add_child(info)

	vb.add_child(HSeparator.new())

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(btn_row)

	var btn_ok = Button.new()
	btn_ok.text = "OK  (keep existing)"
	btn_ok.pressed.connect(func():
		dlg.queue_free()
	)
	btn_row.add_child(btn_ok)

	if existing_idx >= 0:
		var btn_edit = Button.new()
		btn_edit.text = "✏ Edit existing transition"
		btn_edit.modulate = Color(0.5, 1.0, 0.8)
		btn_edit.pressed.connect(func():
			dlg.queue_free()
			_open_transition_editor(from_state, existing_idx)
		)
		btn_row.add_child(btn_edit)

	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _prompt_for_transition_condition(from_state: OmniStateNode, to_state: OmniStateNode):
	# Use a fresh dialog instance so it never conflicts with the toolbar → Transition button
	var dlg = preload("res://addons/omnistate_ai/ui/transition_dialog.gd").new()
	add_child(dlg)
	dlg.setup_with_states(_get_all_state_nodes())

	# Pre-select the correct from/to states
	for i in range(dlg.from_state_option.item_count):
		if dlg.from_state_option.get_item_text(i) == from_state.get_state_name():
			dlg.from_state_option.selected = i
			break
	for i in range(dlg.to_state_option.item_count):
		if dlg.to_state_option.get_item_text(i) == to_state.get_state_name():
			dlg.to_state_option.selected = i
			break

	dlg.confirmed.connect(func():
		var data = dlg.get_transition_data()
		from_state.add_transition_condition(to_state.get_state_name(), data.condition, {
			"priority": data.priority,
			"delay": data.delay,
			"cooldown": data.cooldown,
			"can_interrupt": data.can_interrupt,
			"blend_time": data.blend_time,
			"custom_code": data.custom_code,
			"debug_log": data.debug_log,
			"debug_label": data.debug_label,
		})
		has_unsaved_changes = true
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	
	# Mark as changed
	has_unsaved_changes = true
	
	# Remove transition from state node
	var from_state_node = graph_edit.get_node(NodePath(from_node))
	var to_state_node = graph_edit.get_node(NodePath(to_node))
	
	if from_state_node is OmniStateNode and to_state_node is OmniStateNode:
		var to_name = to_state_node.get_state_name()
		from_state_node.transitions = from_state_node.transitions.filter(
			func(t): return t.to_state != to_name
		)
		from_state_node.refresh_transitions_display()

func _on_delete_nodes_request(nodes: Array):
	for node_name in nodes:
		var node = graph_edit.get_node(NodePath(node_name))
		if node:
			node.queue_free()
	
	# Mark as changed
	has_unsaved_changes = true

func _on_node_selected(node: Node):
	if node is OmniStateNode:
		selected_state_node = node

func _on_node_deselected(node: Node):
	if selected_state_node == node:
		selected_state_node = null

func _on_state_node_selected(state_node: OmniStateNode):
	selected_state_node = state_node

func _on_state_data_changed():
	# Mark as having unsaved changes
	has_unsaved_changes = true

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
	popup.add_item("Arrange All Nodes", 3)
	popup.add_item("Fit View", 4)
	popup.add_separator()
	popup.add_item("Clear All", 5)
	
	popup.id_pressed.connect(func(id):
		match id:
			0:
				_create_new_state(position)
			1:
				var state = StateNodeClass.new()
				state.position_offset = position
				state.is_initial_state_check.button_pressed = true
				state.on_initial_state_toggled(true)
				for anim in detected_animations:
					state.add_animation_option(anim)
				graph_edit.add_child(state)
			3:
				_on_auto_arrange_pressed()
			4:
				_on_fit_view_pressed()
			5:
				_clear_all_states()
		popup.queue_free()
	)
	
	add_child(popup)
	popup.popup(Rect2(get_global_mouse_position(), Vector2(200, 150)))

func _on_auto_arrange_pressed():
	var states = _get_all_state_nodes()
	if states.is_empty():
		return
	
	# Get connections to understand the graph structure
	var connections = graph_edit.get_connection_list()
	
	# Build adjacency map
	var adjacency = {}
	for state in states:
		adjacency[state.name] = []
	
	for conn in connections:
		if adjacency.has(conn.from_node):
			adjacency[conn.from_node].append(conn.to_node)
	
	# Find initial state (root)
	var initial_state = null
	for state in states:
		if state.is_initial_state_check.button_pressed:
			initial_state = state
			break
	
	# If no initial state, use first state
	if initial_state == null and not states.is_empty():
		initial_state = states[0]
	
	# Use hierarchical layout
	if initial_state:
		_arrange_hierarchical(states, connections, initial_state)
	else:
		_arrange_grid(states)

func _arrange_hierarchical(states: Array, connections: Array, root_state: OmniStateNode):
	"""Arrange nodes in a hierarchical tree layout"""
	var layers = {}  # layer_index -> [nodes]
	var visited = {}
	var node_to_layer = {}
	
	# BFS to assign layers
	var queue = [[root_state, 0]]  # [node, layer]
	visited[root_state.name] = true
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var node = current[0]
		var layer = current[1]
		
		if not layers.has(layer):
			layers[layer] = []
		layers[layer].append(node)
		node_to_layer[node.name] = layer
		
		# Find children
		for conn in connections:
			if conn.from_node == node.name:
				var child = _get_node_by_name(conn.to_node)
				if child and not visited.has(child.name):
					visited[child.name] = true
					queue.append([child, layer + 1])
	
	# Add unvisited nodes to last layer
	var max_layer = layers.keys().max() if not layers.is_empty() else 0
	for state in states:
		if not visited.has(state.name):
			if not layers.has(max_layer + 1):
				layers[max_layer + 1] = []
			layers[max_layer + 1].append(state)
	
	# Position nodes
	var layer_spacing = 300.0
	var node_spacing = 250.0
	var start_x = 100.0
	var start_y = 100.0
	
	for layer_idx in layers.keys():
		var layer_nodes = layers[layer_idx]
		var layer_width = (layer_nodes.size() - 1) * node_spacing
		var x_offset = start_x
		
		for i in range(layer_nodes.size()):
			var node = layer_nodes[i]
			var x = x_offset + (i * node_spacing)
			var y = start_y + (layer_idx * layer_spacing)
			node.position_offset = Vector2(x, y)

func _arrange_grid(states: Array):
	"""Fallback grid arrangement"""
	var cols = ceil(sqrt(states.size()))
	var spacing = 300.0
	var start_x = 100.0
	var start_y = 100.0
	
	for i in range(states.size()):
		var col = i % int(cols)
		var row = i / int(cols)
		var x = start_x + (col * spacing)
		var y = start_y + (row * spacing)
		states[i].position_offset = Vector2(x, y)

func _get_node_by_name(node_name: String) -> OmniStateNode:
	"""Helper to get state node by name"""
	for node in graph_edit.get_children():
		if node is OmniStateNode and node.name == node_name:
			return node
	return null

func _on_zoom_in_pressed():
	graph_edit.zoom *= 1.2
	graph_edit.zoom = clamp(graph_edit.zoom, graph_edit.zoom_min, graph_edit.zoom_max)

func _on_zoom_out_pressed():
	graph_edit.zoom /= 1.2
	graph_edit.zoom = clamp(graph_edit.zoom, graph_edit.zoom_min, graph_edit.zoom_max)

func _on_zoom_reset_pressed():
	graph_edit.zoom = 1.0

func _on_fit_view_pressed():
	"""Fit all nodes in the viewport"""
	var states = _get_all_state_nodes()
	if states.is_empty():
		return
	
	# Calculate bounding box
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for state in states:
		var pos = state.position_offset
		var size = state.size
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x + size.x)
		max_pos.y = max(max_pos.y, pos.y + size.y)
	
	# Calculate center and zoom
	var center = (min_pos + max_pos) / 2.0
	var bounds_size = max_pos - min_pos
	var viewport_size = graph_edit.size
	
	# Calculate zoom to fit
	var zoom_x = viewport_size.x / (bounds_size.x + 200)  # +200 for padding
	var zoom_y = viewport_size.y / (bounds_size.y + 200)
	var target_zoom = min(zoom_x, zoom_y)
	target_zoom = clamp(target_zoom, graph_edit.zoom_min, graph_edit.zoom_max)
	
	graph_edit.zoom = target_zoom
	
	# Center the view
	graph_edit.scroll_offset = center - (viewport_size / (2.0 * target_zoom))

func _on_show_connections_pressed():
	"""Show a dialog with all connections and their conditions"""
	var dialog = Window.new()
	dialog.title = "Transition Connections"
	dialog.size = Vector2i(700, 500)
	dialog.transient = true
	dialog.exclusive = false
	
	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	dialog.add_child(vb)
	
	var title_label = Label.new()
	title_label.text = "All State Transitions (From → To)"
	title_label.add_theme_font_size_override("font_size", 14)
	vb.add_child(title_label)
	
	vb.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	
	var list = VBoxContainer.new()
	scroll.add_child(list)
	
	# Gather all transitions
	var states = _get_all_state_nodes()
	var has_transitions = false
	
	for state in states:
		if state.transitions.is_empty():
			continue
		
		has_transitions = true
		
		# State header
		var state_header = Label.new()
		state_header.text = "━━━ FROM: " + state.get_state_name() + " ━━━"
		state_header.add_theme_font_size_override("font_size", 12)
		state_header.add_theme_color_override("font_color", state.state_color_picker.color)
		list.add_child(state_header)
		
		# List transitions
		for trans_idx in range(state.transitions.size()):
			var trans = state.transitions[trans_idx]
			var trans_container = HBoxContainer.new()
			list.add_child(trans_container)
			
			var arrow_label = Label.new()
			arrow_label.text = "    ➜  "
			arrow_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			trans_container.add_child(arrow_label)
			
			var to_label = Label.new()
			to_label.text = "TO: " + trans.to_state
			to_label.custom_minimum_size.x = 120
			to_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			trans_container.add_child(to_label)
			
			var condition_label = Label.new()
			condition_label.text = "WHEN: " + trans.condition
			condition_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			condition_label.add_theme_color_override("font_color", Color.YELLOW)
			trans_container.add_child(condition_label)
			
			# Show button — highlights the connection in the graph
			var show_btn = Button.new()
			show_btn.text = "👁"
			show_btn.flat = true
			show_btn.custom_minimum_size = Vector2(28, 24)
			show_btn.tooltip_text = "Highlight connection in graph"
			show_btn.pressed.connect(func():
				var from_node_name = state.name
				var to_node_name = _find_state_node_by_name(trans.to_state)
				if to_node_name != "":
					_highlight_connection(from_node_name, to_node_name)
					_focus_on_nodes([state.name, to_node_name])
			)
			trans_container.add_child(show_btn)
			
			# Edit button — opens full transition dialog pre-filled
			var edit_btn = Button.new()
			edit_btn.text = "✏"
			edit_btn.flat = true
			edit_btn.custom_minimum_size = Vector2(28, 24)
			edit_btn.tooltip_text = "Edit this transition"
			var captured_state = state
			var captured_idx = trans_idx
			edit_btn.pressed.connect(func():
				dialog.queue_free()
				_open_transition_editor(captured_state, captured_idx)
			)
			trans_container.add_child(edit_btn)
		
		list.add_child(HSeparator.new())
	
	if not has_transitions:
		var no_trans = Label.new()
		no_trans.text = "No transitions defined yet.\nCreate connections between states to see them here."
		no_trans.add_theme_color_override("font_color", Color.GRAY)
		list.add_child(no_trans)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): dialog.queue_free())
	vb.add_child(close_btn)
	
	add_child(dialog)
	dialog.popup_centered()

func _open_transition_editor(state: OmniStateNode, trans_idx: int):
	"""Open the full transition dialog pre-filled for editing an existing transition."""
	if trans_idx < 0 or trans_idx >= state.transitions.size():
		return
	var trans = state.transitions[trans_idx]

	var dlg = preload("res://addons/omnistate_ai/ui/transition_dialog.gd").new()
	add_child(dlg)

	# Populate dropdowns with all state names
	var all_states = _get_all_state_nodes()
	dlg.from_state_option.clear()
	dlg.to_state_option.clear()
	dlg.from_state_option.add_item("[ANY]")
	dlg.to_state_option.add_item("[ANY]")
	for s in all_states:
		dlg.from_state_option.add_item(s.get_state_name())
		dlg.to_state_option.add_item(s.get_state_name())

	# Pre-select from = this state, to = trans.to_state
	for i in range(dlg.from_state_option.item_count):
		if dlg.from_state_option.get_item_text(i) == state.get_state_name():
			dlg.from_state_option.selected = i
			break
	for i in range(dlg.to_state_option.item_count):
		if dlg.to_state_option.get_item_text(i) == trans.to_state:
			dlg.to_state_option.selected = i
			break

	# Fill all fields from existing transition data
	dlg.condition_input.text        = trans.get("condition", "")
	dlg.priority_input.value        = trans.get("priority", 10)
	dlg.delay_input.value           = trans.get("delay", 0.0)
	dlg.cooldown_input.value        = trans.get("cooldown", 0.0)
	dlg.interrupt_check.button_pressed = trans.get("can_interrupt", true)
	dlg.blend_input.value           = trans.get("blend_time", 0.0)
	dlg.custom_code_input.text      = trans.get("custom_code", "")
	dlg.debug_log_check.button_pressed = trans.get("debug_log", false)
	dlg.debug_label_input.text      = trans.get("debug_label", "")

	dlg.confirmed.connect(func():
		var data = dlg.get_transition_data()
		state.transitions[trans_idx] = {
			"to_state":      data.to_state,
			"condition":     data.condition,
			"priority":      data.priority,
			"delay":         data.delay,
			"cooldown":      data.cooldown,
			"can_interrupt": data.can_interrupt,
			"blend_time":    data.blend_time,
			"custom_code":   data.custom_code,
			"debug_log":     data.debug_log,
			"debug_label":   data.debug_label,
		}
		state.refresh_transitions_display()
		has_unsaved_changes = true
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _focus_on_nodes(node_names: Array):
	"""Center the view on specific nodes"""
	if node_names.is_empty():
		return
	
	var positions = []
	for node_name in node_names:
		var node = graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			positions.append(node.position_offset)
	
	if positions.is_empty():
		return
	
	# Calculate center
	var center = Vector2.ZERO
	for pos in positions:
		center += pos
	center /= positions.size()
	
	# Scroll to center
	var viewport_size = graph_edit.size
	graph_edit.scroll_offset = center - (viewport_size / (2.0 * graph_edit.zoom))

func _on_toggle_minimap_pressed():
	graph_edit.minimap_enabled = not graph_edit.minimap_enabled

func _on_validate_pressed():
	var states = _get_all_state_nodes()
	var connections = graph_edit.get_connection_list()
	
	var result = FSMValidator.validate(states, connections)
	var result_text = FSMValidator.format_validation_result(result)
	
	_show_notification(result_text)

func _on_manual_save_pressed():
	"""Manual save button pressed"""
	var states = _get_all_state_nodes()
	if states.is_empty():
		_show_notification("No states to save!")
		return
	
	_save_graph_to_file()
	_show_notification("✓ Graph saved successfully!")

func _on_save_pressed():
	# Validate first
	var states = _get_all_state_nodes()
	if states.is_empty():
		_show_notification("No states to save!")
		return
		
	var dir_path = "res://ai_states/" + fsm_script_name + "/"
	if DirAccess.dir_exists_absolute(dir_path):
		var confirm = ConfirmationDialog.new()
		confirm.title = "Warning: Overwrite Files"
		confirm.dialog_text = "Do you want to proceed?\n\nThis action will overwrite your state files.\nYour manual edits inside state update/enter functions may be lost.\n\nPlease click 'Sync from Files' first to save manual edits."
		confirm.get_ok_button().text = "Proceed with generation"
		
		confirm.confirmed.connect(func():
			_execute_generation(states)
			confirm.queue_free()
		)
		confirm.canceled.connect(func():
			confirm.queue_free()
		)
		add_child(confirm)
		confirm.popup_centered()
	else:
		_execute_generation(states)

func _execute_generation(states: Array):
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
	# Build a map from node internal name → state name for connection serialization
	var node_to_state: Dictionary = {}
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			node_to_state[node.name] = node.get_state_name()

	# Convert connections to use state names instead of internal node names
	var connections_by_state = []
	for conn in graph_edit.get_connection_list():
		var from_state = node_to_state.get(conn.from_node, "")
		var to_state = node_to_state.get(conn.to_node, "")
		if from_state != "" and to_state != "":
			connections_by_state.append({
				"from_state": from_state,
				"to_state": to_state,
				"from_port": conn.from_port,
				"to_port": conn.to_port,
			})

	var save_data = {
		"fsm_script_name": fsm_script_name,
		"base_class_name": base_class_name,
		"enemy_scene_path": enemy_scene_path,
		"player_scene_path": player_scene_path,
		"animation_player_path": animation_player_path,
		"detected_animations": detected_animations,
		"blackboard_vars": blackboard_vars.duplicate(),
		"states": [],
		"connections": connections_by_state
	}
	
	# Save all state nodes
	for node in graph_edit.get_children():
		if node is OmniStateNode:
			var state_data = {
				"name": node.get_state_name(),
				"position": node.position_offset,
				"is_initial": node.is_initial_state_check.button_pressed,
				"color": {
					"r": node.state_color_picker.color.r,
					"g": node.state_color_picker.color.g,
					"b": node.state_color_picker.color.b,
					"a": node.state_color_picker.color.a
				},
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
		has_unsaved_changes = false  # Clear unsaved flag
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
	blackboard_vars = save_data.get("blackboard_vars", {})  # Restore blackboard variables
	
	# Update UI to reflect loaded configuration
	_update_script_name_label()
	
	# Restore state nodes
	var node_name_map = {}  # Map state names to node names for connections
	
	for state_data in save_data.get("states", []):
		var new_state = StateNodeClass.new()
		
		# Handle position - could be Vector2, Dictionary, or String
		var pos = state_data.get("position", Vector2(100, 100))
		if pos is Vector2:
			new_state.position_offset = pos
		elif pos is Dictionary:
			new_state.position_offset = Vector2(pos.get("x", 100), pos.get("y", 100))
		elif pos is String:
			# Parse string like "(100, 100)"
			var cleaned = pos.replace("(", "").replace(")", "")
			var parts = cleaned.split(",")
			if parts.size() >= 2:
				new_state.position_offset = Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))
			else:
				new_state.position_offset = Vector2(100, 100)
		else:
			new_state.position_offset = Vector2(100, 100)
		
		new_state.state_selected.connect(_on_state_node_selected)
		new_state.state_data_changed.connect(_on_state_data_changed)
		
		# Add animations
		for anim in detected_animations:
			new_state.add_animation_option(anim)
		
		graph_edit.add_child(new_state)
		
		# Restore state data
		var state_name = state_data.get("name", "state")
		new_state.state_name_input.text = state_name
		new_state.title = state_name if state_name != "" else "New State"
		new_state.is_initial_state_check.button_pressed = state_data.get("is_initial", false)
		
		# Restore color - handle different formats
		if state_data.has("color"):
			var color_data = state_data.color
			if color_data is Color:
				new_state.state_color_picker.color = color_data
			elif color_data is Dictionary:
				new_state.state_color_picker.color = Color(
					color_data.get("r", 1.0),
					color_data.get("g", 1.0),
					color_data.get("b", 1.0),
					color_data.get("a", 1.0)
				)
			elif color_data is String:
				# Parse string format like "#RRGGBBAA" or "(r, g, b, a)"
				new_state.state_color_picker.color = Color(color_data) if color_data.begins_with("#") else Color.WHITE
			else:
				new_state.state_color_picker.color = Color.WHITE
		else:
			new_state.state_color_picker.color = Color.WHITE
		
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
		new_state.refresh_transitions_display()
		
		# Restore behaviors
		new_state.behaviors = state_data.get("behaviors", [])
		
		# Update visual state
		new_state.on_initial_state_toggled(new_state.is_initial_state_check.button_pressed)
		
		# Map state name to node name for connections
		node_name_map[state_data.get("name", "")] = new_state.name
	
	# Wait for nodes to be added
	await get_tree().process_frame
	
	# Restore connections using state names → node names via the map built above
	for connection in save_data.get("connections", []):
		# Support both old format (from_node/to_node) and new format (from_state/to_state)
		var from_node: String
		var to_node: String
		if connection.has("from_state"):
			from_node = node_name_map.get(connection.get("from_state", ""), "")
			to_node = node_name_map.get(connection.get("to_state", ""), "")
		else:
			# Legacy: try to map old internal names via state name lookup
			from_node = node_name_map.get(connection.get("from_node", ""), connection.get("from_node", ""))
			to_node = node_name_map.get(connection.get("to_node", ""), connection.get("to_node", ""))
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

func _highlight_connection(from_node: String, to_node: String):
	"""Briefly highlight a connection to show its direction"""
	# Visual feedback is handled by GraphEdit's built-in rendering
	# We can enhance this by temporarily modifying node colors
	var from_state = graph_edit.get_node(NodePath(from_node))
	var to_state = graph_edit.get_node(NodePath(to_node))
	
	if from_state and to_state:
		# Store original modulates
		var from_original = from_state.modulate
		var to_original = to_state.modulate
		
		# Highlight: from = green (source), to = blue (target)
		from_state.modulate = Color(0.5, 1.0, 0.5, 1.0)  # Green tint
		to_state.modulate = Color(0.5, 0.5, 1.0, 1.0)    # Blue tint
		
		# Reset after 1 second
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(from_state):
			from_state.modulate = from_original
		if is_instance_valid(to_state):
			to_state.modulate = to_original

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
		new_state.state_selected.connect(_on_state_node_selected)
		new_state.state_data_changed.connect(_on_state_data_changed)
		
		graph_edit.add_child(new_state)
		
		# Set state data
		new_state.state_name_input.text = state_data.name
		new_state.title = state_data.name if state_data.name != "" else "New State"
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
			new_state.on_initial_state_toggled(true)
		
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
