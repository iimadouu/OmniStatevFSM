@tool
extends EditorPlugin

# Configuration
var config = {
	"script_name": "enemy_ai",
	"enemy_scene": "",
	"player_scene": "",
	"anim_player_path": "AnimationPlayer",
	"base_class": "CharacterBody3D",
	"animations": [],
	"blackboard_vars": {}  # Shared variables
}

# Transition storage
var transitions = {}  # Store transition conditions
var connection_from_id: String = ""  # GraphNode ID for visual connection
var connection_to_id: String = ""    # GraphNode ID for visual connection

# UI
var main_panel: Control
var graph_edit: GraphEdit
var setup_dialog: Window
var transition_dialog: Window
var blackboard_dialog: Window
var selected_node: GraphNode = null
var connection_from: String = ""
var connection_to: String = ""

func _enter_tree():
	print("🎮 OmniState AI: Loading...")
	# Load the main panel from the separate file
	var MainPanelScript = load("res://addons/omnistate_ai/ui/main_panel.gd")
	main_panel = MainPanelScript.new()
	main_panel.editor_plugin = self
	add_control_to_bottom_panel(main_panel, "OmniState AI")
	print("✓ OmniState AI: Ready! Click the tab at bottom.")

func _exit_tree():
	if main_panel:
		remove_control_from_bottom_panel(main_panel)
		main_panel.queue_free()

func _build_ui():
	main_panel = Control.new()
	main_panel.custom_minimum_size = Vector2(0, 450)
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(vbox)
	
	# === TOOLBAR ===
	var toolbar = HBoxContainer.new()
	vbox.add_child(toolbar)
	
	var btn_setup = Button.new()
	btn_setup.text = "⚙ Setup"
	btn_setup.tooltip_text = "Configure enemy scene, player, animations"
	btn_setup.pressed.connect(_show_setup_dialog)
	toolbar.add_child(btn_setup)
	
	toolbar.add_child(VSeparator.new())
	
	var btn_add = Button.new()
	btn_add.text = "+ Add State"
	btn_add.pressed.connect(_on_add_state)
	toolbar.add_child(btn_add)
	
	var btn_template = Button.new()
	btn_template.text = "📋 Templates"
	btn_template.pressed.connect(_show_templates)
	toolbar.add_child(btn_template)
	
	var btn_blackboard = Button.new()
	btn_blackboard.text = "📊 Blackboard"
	btn_blackboard.tooltip_text = "Manage shared variables"
	btn_blackboard.pressed.connect(_show_blackboard_dialog)
	toolbar.add_child(btn_blackboard)
	
	toolbar.add_child(VSeparator.new())
	
	var btn_validate = Button.new()
	btn_validate.text = "✓ Validate"
	btn_validate.pressed.connect(_validate)
	toolbar.add_child(btn_validate)
	
	var btn_gen = Button.new()
	btn_gen.text = "💾 Generate"
	btn_gen.modulate = Color(0.5, 1, 0.5)
	btn_gen.pressed.connect(_on_generate)
	toolbar.add_child(btn_gen)
	
	toolbar.add_child(VSeparator.new())
	
	var lbl = Label.new()
	lbl.text = " Script: "
	toolbar.add_child(lbl)
	
	var name_edit = LineEdit.new()
	name_edit.text = config.script_name
	name_edit.custom_minimum_size.x = 120
	name_edit.text_changed.connect(func(t): config.script_name = t)
	toolbar.add_child(name_edit)
	
	# === GRAPH ===
	graph_edit = GraphEdit.new()
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_edit.right_disconnects = true
	graph_edit.show_zoom_label = true
	graph_edit.minimap_enabled = true
	graph_edit.connection_request.connect(_on_connect)
	graph_edit.disconnection_request.connect(_on_disconnect)
	graph_edit.popup_request.connect(_on_graph_popup)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes)  # Handle Delete key
	graph_edit.connection_to_empty.connect(_on_connection_to_empty)
	graph_edit.connection_from_empty.connect(_on_connection_from_empty)
	
	# Enable connection dragging context menu
	graph_edit.gui_input.connect(_on_graph_input)
	
	vbox.add_child(graph_edit)
	
	# === STATUS ===
	var status = Label.new()
	status.text = "Ready! Click '⚙ Setup' to configure, then '+ Add State' to begin"
	vbox.add_child(status)

func _show_setup_dialog():
	setup_dialog = Window.new()
	setup_dialog.title = "OmniState AI - Setup"
	setup_dialog.size = Vector2i(500, 400)
	setup_dialog.unresizable = false
	
	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	setup_dialog.add_child(vb)
	
	# Script name
	vb.add_child(_create_label("Script Name:"))
	var script_input = LineEdit.new()
	script_input.text = config.script_name
	script_input.text_changed.connect(func(t): config.script_name = t)
	vb.add_child(script_input)
	
	# Base class
	vb.add_child(_create_label("Base Class:"))
	var base_option = OptionButton.new()
	base_option.add_item("CharacterBody3D", 0)
	base_option.add_item("CharacterBody2D", 1)
	base_option.add_item("Node3D", 2)
	base_option.item_selected.connect(func(idx):
		match idx:
			0: config.base_class = "CharacterBody3D"
			1: config.base_class = "CharacterBody2D"
			2: config.base_class = "Node3D"
	)
	vb.add_child(base_option)
	
	# Enemy scene
	vb.add_child(_create_label("Enemy Scene Path (optional):"))
	var enemy_input = LineEdit.new()
	enemy_input.text = config.enemy_scene
	enemy_input.placeholder_text = "res://scenes/enemy.tscn"
	enemy_input.text_changed.connect(func(t): config.enemy_scene = t)
	vb.add_child(enemy_input)
	
	# Player scene
	vb.add_child(_create_label("Player Scene Path (optional):"))
	var player_input = LineEdit.new()
	player_input.text = config.player_scene
	player_input.placeholder_text = "res://scenes/player.tscn"
	player_input.text_changed.connect(func(t): config.player_scene = t)
	vb.add_child(player_input)
	
	# AnimationPlayer path
	vb.add_child(_create_label("AnimationPlayer Node Path:"))
	var anim_input = LineEdit.new()
	anim_input.text = config.anim_player_path
	anim_input.text_changed.connect(func(t): config.anim_player_path = t)
	vb.add_child(anim_input)
	
	# Detect button
	var detect_btn = Button.new()
	detect_btn.text = "🔍 Detect Animations"
	detect_btn.pressed.connect(_detect_animations)
	vb.add_child(detect_btn)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "OK"
	close_btn.pressed.connect(func(): 
		if is_instance_valid(setup_dialog):
			setup_dialog.hide()
	)
	vb.add_child(close_btn)
	
	main_panel.add_child(setup_dialog)
	setup_dialog.popup_centered()

func _detect_animations():
	if config.enemy_scene == "" or not ResourceLoader.exists(config.enemy_scene):
		print("⚠ Enemy scene not found")
		return
	
	var scene = load(config.enemy_scene)
	if not scene:
		return
	
	var inst = scene.instantiate()
	var anim_player = inst.get_node_or_null(config.anim_player_path)
	
	if anim_player and anim_player is AnimationPlayer:
		config.animations = Array(anim_player.get_animation_list())
		print("✓ Detected animations: ", config.animations)
	else:
		print("⚠ AnimationPlayer not found at: ", config.anim_player_path)
	
	inst.queue_free()

func _create_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	return lbl

func _on_add_state():
	_create_state_node("new_state", Vector2(randf_range(50, 400), randf_range(50, 300)))

func _create_state_node(state_name: String, pos: Vector2):
	var node = GraphNode.new()
	node.title = state_name
	node.resizable = true
	node.draggable = true
	node.position_offset = pos
	
	# Add close button to titlebar
	var titlebar = node.get_titlebar_hbox()
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.pressed.connect(func(): node.queue_free())
	titlebar.add_child(close_btn)
	
	node.gui_input.connect(_on_node_input.bind(node))
	
	# Tabs
	var tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(300, 300)
	node.add_child(tabs)
	
	# Tab 1: Basic
	var basic_tab = VBoxContainer.new()
	basic_tab.name = "Basic"
	tabs.add_child(basic_tab)
	
	basic_tab.add_child(_create_label("State Name:"))
	var name_input = LineEdit.new()
	name_input.text = state_name
	name_input.text_changed.connect(func(t): node.title = t)
	basic_tab.add_child(name_input)
	
	basic_tab.add_child(_create_label("Animation:"))
	var anim_option = OptionButton.new()
	anim_option.add_item("(None)", 0)
	for i in range(config.animations.size()):
		anim_option.add_item(config.animations[i], i + 1)
	basic_tab.add_child(anim_option)
	
	var is_initial = CheckBox.new()
	is_initial.text = "Initial State"
	basic_tab.add_child(is_initial)
	
	# Tab 2: Enter Code
	var enter_tab = VBoxContainer.new()
	enter_tab.name = "Enter"
	tabs.add_child(enter_tab)
	
	enter_tab.add_child(_create_label("Code when entering state:"))
	var enter_code = TextEdit.new()
	enter_code.text = "# Enter logic\npass"
	enter_code.custom_minimum_size = Vector2(280, 250)
	enter_tab.add_child(enter_code)
	
	# Tab 3: Update Code
	var update_tab = VBoxContainer.new()
	update_tab.name = "Update"
	tabs.add_child(update_tab)
	
	update_tab.add_child(_create_label("Code every frame:"))
	var update_code = TextEdit.new()
	update_code.text = "# Update logic\npass"
	update_code.custom_minimum_size = Vector2(280, 250)
	update_tab.add_child(update_code)
	
	# Tab 4: Exit Code
	var exit_tab = VBoxContainer.new()
	exit_tab.name = "Exit"
	tabs.add_child(exit_tab)
	
	exit_tab.add_child(_create_label("Code when exiting state:"))
	var exit_code = TextEdit.new()
	exit_code.text = "# Exit logic\npass"
	exit_code.custom_minimum_size = Vector2(280, 250)
	exit_tab.add_child(exit_code)
	
	# Set ports
	node.set_slot(0, true, 0, Color.DODGER_BLUE, true, 0, Color.DODGER_BLUE)
	
	graph_edit.add_child(node)
	print("✓ Added state: ", state_name)

func _on_node_input(event: InputEvent, node: GraphNode):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			selected_node = node
			_show_node_context_menu(node)

func _show_node_context_menu(node: GraphNode):
	var popup = PopupMenu.new()
	popup.add_item("Add Transition", 0)
	popup.add_item("Duplicate", 1)
	popup.add_separator()
	popup.add_item("Delete", 2)
	popup.id_pressed.connect(func(id):
		match id:
			0: _add_transition_from_node(node)
			1: _duplicate_node(node)
			2: node.queue_free()
		popup.queue_free()
	)
	main_panel.add_child(popup)
	popup.popup(Rect2(main_panel.get_global_mouse_position(), Vector2(150, 100)))

func _add_transition_from_node(node: GraphNode):
	print("Add transition from: ", node.title)

func _duplicate_node(node: GraphNode):
	var new_pos = node.position_offset + Vector2(50, 50)
	_create_state_node(node.title + "_copy", new_pos)

func _on_graph_popup(pos: Vector2):
	var popup = PopupMenu.new()
	popup.add_item("Add State Here", 0)
	popup.id_pressed.connect(func(id):
		if id == 0:
			_create_state_node("new_state", pos)
		popup.queue_free()
	)
	main_panel.add_child(popup)
	popup.popup(Rect2(main_panel.get_global_mouse_position(), Vector2(150, 50)))

func _on_graph_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Check if clicking on a connection line
			var mouse_pos = graph_edit.get_local_mouse_position()
			var clicked_connection = _get_connection_at_position(mouse_pos)
			if clicked_connection:
				_show_connection_context_menu(clicked_connection)

func _get_connection_at_position(pos: Vector2) -> Dictionary:
	# Check all connections to see if mouse is near any line
	var connections = graph_edit.get_connection_list()
	for conn in connections:
		var from_node = graph_edit.get_node(NodePath(conn.from_node))
		var to_node = graph_edit.get_node(NodePath(conn.to_node))
		if from_node and to_node:
			var from_pos = from_node.position_offset + Vector2(from_node.size.x, from_node.size.y / 2)
			var to_pos = to_node.position_offset + Vector2(0, to_node.size.y / 2)
			
			# Simple distance check to line
			var dist = _point_to_line_distance(pos, from_pos, to_pos)
			if dist < 10.0:  # 10 pixels threshold
				return conn
	return {}

func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	if line_len == 0:
		return point_vec.length()
	var t = clamp(point_vec.dot(line_vec) / (line_len * line_len), 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

func _show_connection_context_menu(connection: Dictionary):
	var from_node_obj = graph_edit.get_node(NodePath(connection.from_node))
	var to_node_obj = graph_edit.get_node(NodePath(connection.to_node))
	
	if not from_node_obj or not to_node_obj:
		return
	
	var from_title = from_node_obj.title
	var to_title = to_node_obj.title
	
	var popup = PopupMenu.new()
	popup.add_item("Edit Transition", 0)
	popup.add_item("Delete Transition", 1)
	popup.id_pressed.connect(func(id):
		match id:
			0:
				# Store connection info and show editor
				connection_from = from_title
				connection_to = to_title
				connection_from_id = connection.from_node
				connection_to_id = connection.to_node
				_show_transition_condition_dialog(from_title, to_title)
			1:
				# Delete the connection
				graph_edit.disconnect_node(connection.from_node,
				connection.from_port,
				connection.to_node,
				connection.to_port)
				var transition_key = from_title + "_to_" + to_title
				if transitions.has(transition_key):
					transitions.erase(transition_key)
					print("✓ Removed transition: ", from_title, " → ", to_title)
		popup.queue_free()
	)
	main_panel.add_child(popup)
	popup.popup(Rect2(main_panel.get_global_mouse_position(), Vector2(150, 60)))

func _on_connection_to_empty(_from_node: StringName, _from_port: int, _release_position: Vector2):
	pass  # Optional: could create new state at release position

func _on_connection_from_empty(_to_node: StringName, _to_port: int, _release_position: Vector2):
	pass  # Optional: could create new state at release position

func _show_blackboard_dialog():
	blackboard_dialog = Window.new()
	blackboard_dialog.title = "Blackboard Variables"
	blackboard_dialog.size = Vector2i(500, 400)
	
	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	blackboard_dialog.add_child(vb)
	
	vb.add_child(_create_label("Shared Variables (accessible by all states):"))
	
	# List existing variables
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 250)
	vb.add_child(scroll)
	
	var vars_list = VBoxContainer.new()
	scroll.add_child(vars_list)
	
	for var_name in config.blackboard_vars.keys():
		var item = HBoxContainer.new()
		vars_list.add_child(item)
		
		var lbl = Label.new()
		lbl.text = var_name + " = " + str(config.blackboard_vars[var_name])
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_child(lbl)
		
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.pressed.connect(func():
			config.blackboard_vars.erase(var_name)
			item.queue_free()
		)
		item.add_child(del_btn)
	
	# Add new variable
	vb.add_child(HSeparator.new())
	vb.add_child(_create_label("Add New Variable:"))
	
	var add_hbox = HBoxContainer.new()
	vb.add_child(add_hbox)
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Variable name"
	add_hbox.add_child(name_input)
	
	var type_option = OptionButton.new()
	type_option.add_item("bool", 0)
	type_option.add_item("int", 1)
	type_option.add_item("float", 2)
	type_option.add_item("String", 3)
	type_option.add_item("Vector3", 4)
	add_hbox.add_child(type_option)
	
	var value_input = LineEdit.new()
	value_input.placeholder_text = "Default value"
	add_hbox.add_child(value_input)
	
	var add_btn = Button.new()
	add_btn.text = "+ Add"
	add_btn.pressed.connect(func():
		if name_input.text != "":
			var val = value_input.text
			match type_option.selected:
				0: val = val.to_lower() == "true"
				1: val = int(val)
				2: val = float(val)
				4: val = Vector3.ZERO
			config.blackboard_vars[name_input.text] = val
			blackboard_dialog.hide()
			_show_blackboard_dialog()  # Refresh
	)
	add_hbox.add_child(add_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): blackboard_dialog.hide())
	vb.add_child(close_btn)
	
	main_panel.add_child(blackboard_dialog)
	blackboard_dialog.popup_centered()

func _show_templates():
	var popup = PopupMenu.new()
	var templates = ["Idle", "Patrol", "Chase", "Attack", "Cover", "Flee"]
	for i in range(templates.size()):
		popup.add_item(templates[i], i)
	popup.id_pressed.connect(func(id):
		_create_state_from_template(templates[id])
		popup.queue_free()
	)
	main_panel.add_child(popup)
	popup.popup(Rect2(main_panel.get_global_mouse_position(), Vector2(150, 200)))

func _create_state_from_template(template_name: String):
	_create_state_node(template_name.to_lower(), Vector2(randf_range(100, 400), randf_range(100, 300)))
	print("✓ Created from template: ", template_name)

func _on_connect(from_node, _from_port, to_node, _to_port):
	# Store both node IDs (for visual) and titles (for logic)
	connection_from_id = from_node  # GraphNode ID like "@GraphNode@22727"
	connection_to_id = to_node      # GraphNode ID like "@GraphNode@22792"
	
	var from_node_obj = graph_edit.get_node(NodePath(from_node))
	var to_node_obj = graph_edit.get_node(NodePath(to_node))
	
	if from_node_obj and to_node_obj:
		connection_from = from_node_obj.title if from_node_obj.title != "" else from_node
		connection_to = to_node_obj.title if to_node_obj.title != "" else to_node
	else:
		connection_from = from_node
		connection_to = to_node
	
	# Show advanced transition editor
	_show_transition_condition_dialog(connection_from, connection_to)

func _show_transition_condition_dialog(from_node_name: String, to_node_name: String):
	var dialog = Window.new()
	dialog.title = "Advanced Transition Editor"
	dialog.size = Vector2i(700, 650)
	dialog.min_size = Vector2i(700, 650)
	
	# Check if editing existing transition
	var trans_key = from_node_name + "_to_" + to_node_name
	var existing_trans = transitions.get(trans_key, {})
	var is_editing = not existing_trans.is_empty()
	
	if is_editing:
		dialog.title = "Edit Transition: " + from_node_name + " → " + to_node_name
	
	var main_vb = VBoxContainer.new()
	main_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vb.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	dialog.add_child(main_vb)
	
	# === HEADER ===
	var header = HBoxContainer.new()
	main_vb.add_child(header)
	
	var from_lbl = Label.new()
	from_lbl.text = from_node_name
	from_lbl.add_theme_font_size_override("font_size", 16)
	from_lbl.add_theme_color_override("font_color", Color.CORNFLOWER_BLUE)
	header.add_child(from_lbl)
	
	var arrow = Label.new()
	arrow.text = "  →  "
	arrow.add_theme_font_size_override("font_size", 20)
	header.add_child(arrow)
	
	var to_lbl = Label.new()
	to_lbl.text = to_node_name
	to_lbl.add_theme_font_size_override("font_size", 16)
	to_lbl.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	header.add_child(to_lbl)
	
	main_vb.add_child(HSeparator.new())
	
	# === TABS ===
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(tabs)
	
	# === TAB 1: CONDITIONS ===
	var conditions_tab = VBoxContainer.new()
	conditions_tab.name = "Conditions"
	tabs.add_child(conditions_tab)
	
	var cond_desc = Label.new()
	cond_desc.text = "Define when this transition should trigger"
	cond_desc.add_theme_font_size_override("font_size", 12)
	conditions_tab.add_child(cond_desc)
	
	# Condition Mode
	conditions_tab.add_child(_create_label("Condition Mode:"))
	var mode_option = OptionButton.new()
	mode_option.add_item("Simple Expression", 0)
	mode_option.add_item("Multiple Conditions (AND)", 1)
	mode_option.add_item("Multiple Conditions (OR)", 2)
	mode_option.add_item("Custom Script", 3)
	if is_editing:
		mode_option.selected = existing_trans.get("condition_mode", 0)
	conditions_tab.add_child(mode_option)
	
	# Simple Expression
	var simple_container = VBoxContainer.new()
	conditions_tab.add_child(simple_container)
	
	simple_container.add_child(_create_label("Expression:"))
	var condition_input = CodeEdit.new()
	condition_input.custom_minimum_size = Vector2(0, 80)
	condition_input.placeholder_text = "e.g., distance_to_player < 10.0 and can_see_player"
	condition_input.syntax_highlighter = _create_simple_highlighter()
	if is_editing and existing_trans.get("condition_mode", 0) == 0:
		condition_input.text = existing_trans.get("condition", "")
	simple_container.add_child(condition_input)
	
	# Quick Presets
	simple_container.add_child(_create_label("Quick Presets:"))
	var presets_grid = GridContainer.new()
	presets_grid.columns = 3
	simple_container.add_child(presets_grid)
	
	var preset_buttons = [
		{"text": "Player Detected", "code": "blackboard.get(\"player_detected\", false)"},
		{"text": "In Range", "code": "blackboard.get(\"distance_to_player\", 999) < 10.0"},
		{"text": "Health Low", "code": "blackboard.get(\"health\", 100) < 30"},
		{"text": "Can See Player", "code": "blackboard.get(\"can_see_player\", false)"},
		{"text": "Ammo Empty", "code": "blackboard.get(\"ammo\", 0) == 0"},
		{"text": "Timer Elapsed", "code": "blackboard.get(\"state_timer\", 0) > 5.0"},
		{"text": "Is Covering", "code": "blackboard.get(\"in_cover\", false)"},
		{"text": "Enemy Nearby", "code": "blackboard.get(\"enemies_nearby\", 0) > 0"},
		{"text": "Path Clear", "code": "blackboard.get(\"path_blocked\", true) == false"}
	]
	
	for preset in preset_buttons:
		var btn = Button.new()
		btn.text = preset.text
		btn.custom_minimum_size = Vector2(150, 0)
		btn.pressed.connect(func(): 
			if condition_input.text != "":
				condition_input.text += " and " + preset.code
			else:
				condition_input.text = preset.code
		)
		presets_grid.add_child(btn)
	
	# Multiple Conditions Container
	var multi_container = VBoxContainer.new()
	multi_container.visible = false
	conditions_tab.add_child(multi_container)
	
	var conditions_list = VBoxContainer.new()
	multi_container.add_child(conditions_list)
	
	var add_condition_btn = Button.new()
	add_condition_btn.text = "+ Add Condition"
	add_condition_btn.pressed.connect(func():
		var cond_item = HBoxContainer.new()
		conditions_list.add_child(cond_item)
		
		var var_input = LineEdit.new()
		var_input.placeholder_text = "variable"
		var_input.custom_minimum_size.x = 150
		cond_item.add_child(var_input)
		
		var op_option = OptionButton.new()
		op_option.add_item("==", 0)
		op_option.add_item("!=", 1)
		op_option.add_item("<", 2)
		op_option.add_item(">", 3)
		op_option.add_item("<=", 4)
		op_option.add_item(">=", 5)
		cond_item.add_child(op_option)
		
		var val_input = LineEdit.new()
		val_input.placeholder_text = "value"
		val_input.custom_minimum_size.x = 150
		cond_item.add_child(val_input)
		
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.pressed.connect(func(): cond_item.queue_free())
		cond_item.add_child(del_btn)
	)
	multi_container.add_child(add_condition_btn)
	
	# Custom Script Container
	var custom_container = VBoxContainer.new()
	custom_container.visible = false
	conditions_tab.add_child(custom_container)
	
	custom_container.add_child(_create_label("Custom Condition Script:"))
	var custom_hint = Label.new()
	custom_hint.text = "Write GDScript that returns true/false. You have access to 'owner' and 'blackboard'."
	custom_hint.add_theme_font_size_override("font_size", 10)
	custom_hint.add_theme_color_override("font_color", Color.GRAY)
	custom_container.add_child(custom_hint)
	
	var custom_script_editor = CodeEdit.new()
	custom_script_editor.custom_minimum_size = Vector2(0, 200)
	custom_script_editor.placeholder_text = "# Example:\nvar dist = owner.global_position.distance_to(owner.player.global_position)\nreturn dist < 10.0 and owner.bb_get(\"can_see_player\", false)"
	custom_script_editor.syntax_highlighter = _create_simple_highlighter()
	if is_editing and existing_trans.get("condition_mode", 0) == 3:
		custom_script_editor.text = existing_trans.get("condition", "")
	custom_container.add_child(custom_script_editor)
	
	# Mode switching
	mode_option.item_selected.connect(func(idx):
		simple_container.visible = (idx == 0)
		multi_container.visible = (idx == 1 or idx == 2)
		custom_container.visible = (idx == 3)
	)
	
	# Set initial visibility based on mode
	if is_editing:
		var mode = existing_trans.get("condition_mode", 0)
		simple_container.visible = (mode == 0)
		multi_container.visible = (mode == 1 or mode == 2)
		custom_container.visible = (mode == 3)
	
	# === TAB 2: PRIORITY & TIMING ===
	var priority_tab = VBoxContainer.new()
	priority_tab.name = "Priority & Timing"
	tabs.add_child(priority_tab)
	
	priority_tab.add_child(_create_label("Priority (0 = highest, 100 = lowest):"))
	var priority_input = SpinBox.new()
	priority_input.min_value = 0
	priority_input.max_value = 100
	priority_input.value = existing_trans.get("priority", 10) if is_editing else 10
	priority_input.step = 1
	priority_tab.add_child(priority_input)
	
	var priority_hint = Label.new()
	priority_hint.text = "Lower values check first. Use for critical transitions."
	priority_hint.add_theme_font_size_override("font_size", 10)
	priority_hint.add_theme_color_override("font_color", Color.GRAY)
	priority_tab.add_child(priority_hint)
	
	priority_tab.add_child(HSeparator.new())
	
	# Cooldown
	var cooldown_check = CheckBox.new()
	cooldown_check.text = "Enable Cooldown"
	if is_editing:
		cooldown_check.button_pressed = existing_trans.get("cooldown", 0.0) > 0
	priority_tab.add_child(cooldown_check)
	
	var cooldown_container = VBoxContainer.new()
	cooldown_container.visible = cooldown_check.button_pressed
	priority_tab.add_child(cooldown_container)
	
	cooldown_container.add_child(_create_label("Cooldown Duration (seconds):"))
	var cooldown_input = SpinBox.new()
	cooldown_input.min_value = 0.1
	cooldown_input.max_value = 60.0
	cooldown_input.step = 0.1
	cooldown_input.value = existing_trans.get("cooldown", 1.0) if is_editing else 1.0
	cooldown_container.add_child(cooldown_input)
	
	cooldown_check.toggled.connect(func(pressed): cooldown_container.visible = pressed)
	
	priority_tab.add_child(HSeparator.new())
	
	# Delay
	var delay_check = CheckBox.new()
	delay_check.text = "Enable Transition Delay"
	if is_editing:
		delay_check.button_pressed = existing_trans.get("delay", 0.0) > 0
	priority_tab.add_child(delay_check)
	
	var delay_container = VBoxContainer.new()
	delay_container.visible = delay_check.button_pressed
	priority_tab.add_child(delay_container)
	
	delay_container.add_child(_create_label("Delay Duration (seconds):"))
	var delay_input = SpinBox.new()
	delay_input.min_value = 0.1
	delay_input.max_value = 10.0
	delay_input.step = 0.1
	delay_input.value = existing_trans.get("delay", 0.5) if is_editing else 0.5
	delay_container.add_child(delay_input)
	
	delay_check.toggled.connect(func(pressed): delay_container.visible = pressed)
	
	# === TAB 3: ADVANCED ===
	var advanced_tab = VBoxContainer.new()
	advanced_tab.name = "Advanced"
	tabs.add_child(advanced_tab)
	
	# Interrupt
	var interrupt_check = CheckBox.new()
	interrupt_check.text = "Can Interrupt Current State"
	interrupt_check.button_pressed = existing_trans.get("can_interrupt", true) if is_editing else true
	advanced_tab.add_child(interrupt_check)
	
	var interrupt_hint = Label.new()
	interrupt_hint.text = "If disabled, transition only triggers when state naturally exits"
	interrupt_hint.add_theme_font_size_override("font_size", 10)
	interrupt_hint.add_theme_color_override("font_color", Color.GRAY)
	advanced_tab.add_child(interrupt_hint)
	
	advanced_tab.add_child(HSeparator.new())
	
	# Blend Time
	var blend_check = CheckBox.new()
	blend_check.text = "Enable Animation Blend"
	if is_editing:
		blend_check.button_pressed = existing_trans.get("blend_time", 0.0) > 0
	advanced_tab.add_child(blend_check)
	
	var blend_container = VBoxContainer.new()
	blend_container.visible = blend_check.button_pressed
	advanced_tab.add_child(blend_container)
	
	blend_container.add_child(_create_label("Blend Duration (seconds):"))
	var blend_input = SpinBox.new()
	blend_input.min_value = 0.0
	blend_input.max_value = 2.0
	blend_input.step = 0.05
	blend_input.value = existing_trans.get("blend_time", 0.2) if is_editing else 0.2
	blend_container.add_child(blend_input)
	
	blend_check.toggled.connect(func(pressed): blend_container.visible = pressed)
	
	advanced_tab.add_child(HSeparator.new())
	
	# Custom Code
	advanced_tab.add_child(_create_label("On Transition Code (optional):"))
	var custom_code = CodeEdit.new()
	custom_code.custom_minimum_size = Vector2(0, 100)
	custom_code.placeholder_text = "# Code to run when transitioning\npass"
	custom_code.syntax_highlighter = _create_simple_highlighter()
	if is_editing:
		custom_code.text = existing_trans.get("custom_code", "")
	advanced_tab.add_child(custom_code)
	
	# === TAB 4: DEBUG ===
	var debug_tab = VBoxContainer.new()
	debug_tab.name = "Debug"
	tabs.add_child(debug_tab)
	
	var debug_check = CheckBox.new()
	debug_check.text = "Enable Debug Logging"
	if is_editing:
		debug_check.button_pressed = existing_trans.get("debug_enabled", false)
	debug_tab.add_child(debug_check)
	
	debug_tab.add_child(_create_label("Debug Label (optional):"))
	var debug_label = LineEdit.new()
	debug_label.placeholder_text = "e.g., 'Patrol to Chase when player spotted'"
	if is_editing:
		debug_label.text = existing_trans.get("debug_label", "")
	debug_tab.add_child(debug_label)
	
	var debug_color_label = Label.new()
	debug_color_label.text = "Debug Color:"
	debug_tab.add_child(debug_color_label)
	
	var debug_color = ColorPickerButton.new()
	debug_color.color = existing_trans.get("debug_color", Color.YELLOW) if is_editing else Color.YELLOW
	debug_tab.add_child(debug_color)
	
	# === BUTTONS ===
	main_vb.add_child(HSeparator.new())
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	main_vb.add_child(btn_hbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): dialog.hide())
	btn_hbox.add_child(cancel_btn)
	
	var ok_btn = Button.new()
	ok_btn.text = "Create Transition"
	ok_btn.modulate = Color(0.5, 1, 0.5)
	ok_btn.pressed.connect(func():
		# Build final condition based on mode
		var final_condition = ""
		
		match mode_option.selected:
			0:  # Simple Expression
				final_condition = condition_input.text
			1, 2:  # Multiple Conditions (AND/OR)
				var conds = []
				for child in conditions_list.get_children():
					if child is HBoxContainer:
						var var_name = child.get_child(0).text
						var op_idx = child.get_child(1).selected
						var value = child.get_child(2).text
						var ops = ["==", "!=", "<", ">", "<=", ">="]
						if var_name != "" and value != "":
							conds.append(var_name + " " + ops[op_idx] + " " + value)
				if not conds.is_empty():
					var joiner = " and " if mode_option.selected == 1 else " or "
					final_condition = joiner.join(conds)
			3:  # Custom Script
				final_condition = custom_script_editor.text
		
		# Store transition with all settings
		var transition_key = connection_from + "_to_" + connection_to
		transitions[transition_key] = {
			"from": connection_from,
			"to": connection_to,
			"condition": final_condition,
			"condition_mode": mode_option.selected,  # Store mode for editing later
			"priority": int(priority_input.value),
			"cooldown": cooldown_input.value if cooldown_check.button_pressed else 0.0,
			"delay": delay_input.value if delay_check.button_pressed else 0.0,
			"can_interrupt": interrupt_check.button_pressed,
			"blend_time": blend_input.value if blend_check.button_pressed else 0.0,
			"custom_code": custom_code.text,
			"debug_enabled": debug_check.button_pressed,
			"debug_label": debug_label.text,
			"debug_color": debug_color.color
		}
		
		# Connect in graph using node IDs (not state names!)
		graph_edit.connect_node(connection_from_id, 0, connection_to_id, 0)
		
		var log_msg = "✓ Advanced Transition: " + connection_from + " → " + connection_to
		if final_condition != "":
			log_msg += " | Condition: " + final_condition
		log_msg += " | Priority: " + str(priority_input.value)
		print(log_msg)
		
		dialog.hide()
	)
	btn_hbox.add_child(ok_btn)
	
	main_panel.add_child(dialog)
	dialog.popup_centered()

func _create_simple_highlighter() -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	highlighter.add_keyword_color("and", Color.PINK)
	highlighter.add_keyword_color("or", Color.PINK)
	highlighter.add_keyword_color("not", Color.PINK)
	highlighter.add_keyword_color("true", Color.LIGHT_BLUE)
	highlighter.add_keyword_color("false", Color.LIGHT_BLUE)
	highlighter.add_color_region("#", "", Color.GRAY, true)
	return highlighter

func _on_disconnect(from_node, from_port, to_node, to_port):
	# Remove transition data
	var trans_key = from_node + "_to_" + to_node
	if transitions.has(trans_key):
		transitions.erase(trans_key)
		print("✓ Removed transition: ", from_node, " → ", to_node)
	
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_delete_nodes(nodes: Array):
	for node_name in nodes:
		var node = graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			var state_title = node.title if node.title != "" else node_name
			
			# Clean up transitions involving this node
			var keys_to_remove = []
			for trans_key in transitions.keys():
				var trans = transitions[trans_key]
				if trans.from == state_title or trans.to == state_title:
					keys_to_remove.append(trans_key)
			
			for key in keys_to_remove:
				transitions.erase(key)
				print("🧹 Removed transition: ", key)
			
			node.queue_free()
			print("✓ Deleted state: ", state_title)

func _validate():
	var states = []
	for c in graph_edit.get_children():
		if c is GraphNode:
			states.append(c)
	
	if states.is_empty():
		print("⚠ No states to validate")
		return
	
	print("✓ Validation passed! ", states.size(), " states found")

func _on_generate():
	print("============================================================")
	print("🚀 GENERATING STATE MACHINE: ", config.script_name)
	print("============================================================")
	
	var states = []
	for c in graph_edit.get_children():
		if c is GraphNode:
			states.append(c)
	
	if states.is_empty():
		print("⚠ No states to generate!")
		return
	
	# Clean up stale transitions (from deleted/renamed nodes)
	_cleanup_stale_transitions(states)
	
	# Validate before generation
	var warnings = _validate_before_generation(states)
	if not warnings.is_empty():
		print("\n⚠️ GENERATION WARNINGS:")
		for warning in warnings:
			print("  • ", warning)
		print("")
	
	var dir = DirAccess.open("res://")
	var path = "res://ai_states/" + config.script_name + "/"
	dir.make_dir_recursive(path)
	
	# Generate main FSM
	_generate_main_fsm(path, states)
	
	# Generate individual states
	for state in states:
		_generate_state_file(path, state)
	
	print("============================================================")
	print("✓ GENERATION COMPLETE!")
	print("📁 Location: ", path)
	print("📄 Main script: ", config.script_name, ".gd")
	print("📄 State files: ", states.size(), " files")
	print("============================================================")

func _cleanup_stale_transitions(states: Array):
	# Remove transitions that reference non-existent states
	var state_names = []
	for state in states:
		state_names.append(state.title)
	
	var keys_to_remove = []
	for trans_key in transitions.keys():
		var trans = transitions[trans_key]
		if not state_names.has(trans.from) or not state_names.has(trans.to):
			keys_to_remove.append(trans_key)
			print("🧹 Cleaning stale transition: ", trans.from, " → ", trans.to)
	
	for key in keys_to_remove:
		transitions.erase(key)

func _validate_before_generation(states: Array) -> Array:
	# Check for common issues and return warnings
	var warnings = []
	
	# Check for empty conditions
	var empty_condition_count = 0
	for trans_key in transitions.keys():
		var trans = transitions[trans_key]
		if trans.condition == "" or trans.condition == "true":
			empty_condition_count += 1
	
	if empty_condition_count > 0:
		warnings.append(str(empty_condition_count) + " transition(s) have empty conditions (will always trigger)")
	
	# Check for initial state
	var has_initial = false
	for state in states:
		var tabs = state.get_child(0) as TabContainer
		if tabs:
			var basic_tab = tabs.get_child(0)
			for child in basic_tab.get_children():
				if child is CheckBox and child.button_pressed:
					has_initial = true
					break
	
	if not has_initial:
		warnings.append("No initial state marked (FSM won't start)")
	
	# Check for unreachable states
	var reachable_states = []
	for trans_key in transitions.keys():
		var trans = transitions[trans_key]
		if not reachable_states.has(trans.to):
			reachable_states.append(trans.to)
	
	for state in states:
		if not reachable_states.has(state.title) and not has_initial:
			warnings.append("State '" + state.title + "' has no incoming transitions")
	
	return warnings

# ============================================================
# CODE FORMATTING HELPERS
# ============================================================

func _sanitize_code(code: String) -> String:
	# Remove markdown code blocks
	code = code.replace("```gdscript", "")
	code = code.replace("```", "")
	
	# Remove any stray backticks
	code = code.replace("`", "")
	
	# Normalize line endings
	code = code.replace("\r\n", "\n")
	code = code.replace("\r", "\n")
	
	return code

func _normalize_indentation(code: String) -> String:
	# Convert all indentation to tabs
	var lines = code.split("\n")
	var normalized_lines = []
	
	for line in lines:
		# Count leading spaces
		var leading_spaces = 0
		for i in range(line.length()):
			if line[i] == ' ':
				leading_spaces += 1
			elif line[i] == '\t':
				# Already has tabs, keep as is
				normalized_lines.append(line)
				break
			else:
				# Convert spaces to tabs (4 spaces = 1 tab)
				var tabs = "\t".repeat(leading_spaces / 4)
				var rest = line.substr(leading_spaces)
				normalized_lines.append(tabs + rest)
				break
		
		# Empty line
		if line.strip_edges() == "":
			normalized_lines.append("")
	
	return "\n".join(normalized_lines)

func _escape_quotes(text: String) -> String:
	# Escape double quotes for use in strings
	return text.replace("\"", "\\\"")

func _format_transition_dict(trans: Dictionary) -> String:
	# Format transition dictionary across multiple lines for readability
	var lines = []
	lines.append("{")
	lines.append("\t\t\t\t\t\"to\": \"" + trans.to + "\",")
	lines.append("\t\t\t\t\t\"priority\": " + str(trans.get("priority", 10)) + ",")
	lines.append("\t\t\t\t\t\"delay\": " + str(trans.get("delay", 0.0)) + ",")
	lines.append("\t\t\t\t\t\"blend_time\": " + str(trans.get("blend_time", 0.0)) + ",")
	lines.append("\t\t\t\t\t\"custom_code\": \"" + _escape_quotes(trans.get("custom_code", "")) + "\",")
	lines.append("\t\t\t\t\t\"debug_enabled\": " + str(trans.get("debug_enabled", false)).to_lower() + ",")
	lines.append("\t\t\t\t\t\"debug_label\": \"" + trans.get("debug_label", "") + "\",")
	lines.append("\t\t\t\t\t\"cooldown_key\": \"transition_cooldown_" + trans.from + "_to_" + trans.to + "\"")
	lines.append("\t\t\t\t}")
	return "\n".join(lines)

func _clean_user_code(code: String) -> String:
	# Clean user-provided code from state tabs
	code = _sanitize_code(code)
	
	# Remove leading/trailing whitespace from each line but preserve indentation structure
	var lines = code.split("\n")
	var cleaned_lines = []
	
	for line in lines:
		# Keep the line as-is if it has content, just remove trailing whitespace
		if line.strip_edges() != "":
			cleaned_lines.append(line.rstrip(" \t"))
		else:
			cleaned_lines.append("")
	
	return "\n".join(cleaned_lines)

func _generate_main_fsm(path: String, states: Array):
	var code = "# ============================================================\n"
	code += "# Auto-generated by OmniState AI - Professional FSM\n"
	code += "# Project: " + config.script_name + "\n"
	code += "# Generated: " + Time.get_datetime_string_from_system() + "\n"
	code += "# ============================================================\n\n"
	
	code += "extends " + config.base_class + "\n"
	code += "class_name " + config.script_name.capitalize().replace("_", "").replace(" ", "") + "\n\n"
	
	code += "# ============================================================\n"
	code += "# STATE MACHINE CORE\n"
	code += "# ============================================================\n\n"
	
	code += "# State management\n"
	code += "var current_state: RefCounted = null\n"
	code += "var previous_state: RefCounted = null\n"
	code += "var states: Dictionary = {}\n"
	code += "var state_history: Array[String] = []\n\n"
	
	code += "# Blackboard (shared data between states)\n"
	code += "var blackboard: Dictionary = {\n"
	for var_name in config.blackboard_vars.keys():
		var val = config.blackboard_vars[var_name]
		if val is String:
			code += "\t\"" + var_name + "\": \"" + str(val) + "\",\n"
		else:
			code += "\t\"" + var_name + "\": " + str(val) + ",\n"
	code += "}\n\n"
	
	code += "# References\n"
	code += "@onready var animation_player: AnimationPlayer = get_node_or_null(\"" + config.anim_player_path + "\")\n"
	code += "var player: Node = null\n"
	code += "var navigation_agent: NavigationAgent3D = null\n\n"
	
	code += "# ============================================================\n"
	code += "# INITIALIZATION\n"
	code += "# ============================================================\n\n"
	
	code += "func _ready() -> void:\n"
	code += "\t# Find player\n"
	code += "\tplayer = get_tree().get_first_node_in_group(\"player\")\n"
	code += "\tif not player:\n"
	code += "\t\tpush_warning(\"[FSM] Player not found in 'player' group\")\n\n"
	
	code += "\t# Setup navigation\n"
	code += "\tnavigation_agent = get_node_or_null(\"NavigationAgent3D\")\n\n"
	
	code += "\t# Initialize states\n"
	code += "\t_init_states()\n\n"
	
	# Find initial state
	var initial_state = null
	for state in states:
		var tabs = state.get_child(0) as TabContainer
		if tabs:
			var basic_tab = tabs.get_child(0)
			for child in basic_tab.get_children():
				if child is CheckBox and child.button_pressed:
					initial_state = state
					break
	
	if initial_state:
		code += "\t# Start with initial state\n"
		code += "\tchange_state(\"" + initial_state.title + "\")\n"
	else:
		code += "\t# No initial state defined\n"
		code += "\tpush_warning(\"[FSM] No initial state marked\")\n"
	code += "\n"
	
	code += "func _init_states() -> void:\n"
	code += "\t# Load all state scripts\n"
	for state in states:
		code += "\tstates[\"" + state.title + "\"] = load(\"" + path + state.title + "_state.gd\").new()\n"
	code += "\n"
	
	code += "# ============================================================\n"
	code += "# STATE MACHINE LOGIC\n"
	code += "# ============================================================\n\n"
	
	code += "func _physics_process(delta: float) -> void:\n"
	code += "\tif not current_state:\n"
	code += "\t\treturn\n\n"
	
	code += "\t# Update current state\n"
	code += "\tif current_state.has_method(\"update\"):\n"
	code += "\t\tcurrent_state.update(delta, self)\n\n"
	
	code += "\t# Check transitions\n"
	code += "\t_check_transitions()\n\n"
	
	code += "func _check_transitions() -> void:\n"
	code += "\t# Check all transitions from current state\n"
	code += "\tif not current_state:\n"
	code += "\t\treturn\n\n"
	
	code += "\tvar current_state_name = _get_state_name(current_state)\n"
	code += "\tvar possible_transitions: Array = []\n"
	code += "\tvar current_time = Time.get_ticks_msec() / 1000.0\n\n"
	
	code += "\t# Gather all transitions from current state\n"
	for trans_key in transitions.keys():
		var trans = transitions[trans_key]
		code += "\tif current_state_name == \"" + trans.from + "\":\n"
		
		# Check cooldown
		if trans.get("cooldown", 0.0) > 0:
			code += "\t\tvar cooldown_key = \"transition_cooldown_" + trans_key + "\"\n"
			code += "\t\tvar last_time = blackboard.get(cooldown_key, 0.0)\n"
			code += "\t\tif current_time - last_time < " + str(trans.cooldown) + ":\n"
			code += "\t\t\tpass  # Cooldown active\n"
			code += "\t\telse:\n"
			code += "\t\t\t"
		else:
			code += "\t\t"
		
		# Check condition with escaped quotes
		var condition = _escape_quotes(trans.condition)
		code += "if _evaluate_condition(\"" + condition + "\"):\n"
		
		# Check interrupt
		if not trans.get("can_interrupt", true):
			code += "\t\t\t\tif blackboard.get(\"state_can_exit\", true):\n"
			code += "\t\t\t\t\t"
		else:
			code += "\t\t\t\t"
		
		# Add to possible transitions using formatted dict
		code += "possible_transitions.append(\n"
		code += _format_transition_dict(trans)
		code += "\n\t\t\t\t)\n"
		
		if trans.get("cooldown", 0.0) > 0:
			code += "\t\t\t\tblackboard.set(cooldown_key, current_time)\n"
		
		code += "\n"
	
	code += "\t# Sort by priority and take highest\n"
	code += "\tif not possible_transitions.is_empty():\n"
	code += "\t\tpossible_transitions.sort_custom(func(a, b): return a.priority < b.priority)\n"
	code += "\t\tvar selected = possible_transitions[0]\n\n"
	
	code += "\t\t# Handle delay\n"
	code += "\t\tif selected.delay > 0:\n"
	code += "\t\t\tvar delay_key = \"transition_delay_\" + selected.to\n"
	code += "\t\t\tif not blackboard.has(delay_key):\n"
	code += "\t\t\t\tblackboard.set(delay_key, current_time)\n"
	code += "\t\t\telse:\n"
	code += "\t\t\t\tif current_time - blackboard.get(delay_key, 0.0) >= selected.delay:\n"
	code += "\t\t\t\t\tblackboard.erase(delay_key)\n"
	code += "\t\t\t\t\t_execute_transition(selected)\n"
	code += "\t\telse:\n"
	code += "\t\t\t_execute_transition(selected)\n\n"
	
	code += "func _execute_transition(trans_data: Dictionary) -> void:\n"
	code += "\t# Execute a transition with all its settings\n"
	code += "\t# Debug logging\n"
	code += "\tif trans_data.get(\"debug_enabled\", false):\n"
	code += "\t\tvar label = trans_data.get(\"debug_label\", \"\")\n"
	code += "\t\tif label != \"\":\n"
	code += "\t\t\tprint(\"[FSM DEBUG] \", label)\n"
	code += "\t\telse:\n"
	code += "\t\t\tprint(\"[FSM DEBUG] Transitioning to: \", trans_data.to)\n\n"
	
	code += "\t# Execute custom code\n"
	code += "\tvar custom = trans_data.get(\"custom_code\", \"\")\n"
	code += "\tif custom != \"\" and custom != \"pass\":\n"
	code += "\t\t# Custom transition code would go here\n"
	code += "\t\tpass\n\n"
	
	code += "\t# Handle blend time\n"
	code += "\tvar blend = trans_data.get(\"blend_time\", 0.0)\n"
	code += "\tif blend > 0 and animation_player:\n"
	code += "\t\tblackboard.set(\"blend_time\", blend)\n\n"
	
	code += "\t# Change state\n"
	code += "\tchange_state(trans_data.to)\n\n"
	
	code += "func _evaluate_condition(condition: String) -> bool:\n"
	code += "\t# Evaluate transition condition\n"
	code += "\tif condition == \"\" or condition == \"true\":\n"
	code += "\t\treturn true\n\n"
	
	code += "\t# Try to evaluate as expression\n"
	code += "\tvar expression = Expression.new()\n"
	code += "\tvar error = expression.parse(condition)\n"
	code += "\tif error == OK:\n"
	code += "\t\tvar result = expression.execute([], self)\n"
	code += "\t\tif not expression.has_execute_failed():\n"
	code += "\t\t\treturn bool(result)\n\n"
	
	code += "\treturn false\n\n"
	
	code += "func change_state(new_state_name: String) -> void:\n"
	code += "\t# Change to a new state\n"
	code += "\tif not states.has(new_state_name):\n"
	code += "\t\tpush_error(\"[FSM] State not found: \" + new_state_name)\n"
	code += "\t\treturn\n\n"
	
	code += "\t# Exit current state\n"
	code += "\tif current_state:\n"
	code += "\t\tif current_state.has_method(\"exit\"):\n"
	code += "\t\t\tcurrent_state.exit(self)\n"
	code += "\t\tprevious_state = current_state\n"
	code += "\t\tstate_history.append(_get_state_name(current_state))\n\n"
	
	code += "\t# Enter new state\n"
	code += "\tcurrent_state = states[new_state_name]\n"
	code += "\tif current_state.has_method(\"enter\"):\n"
	code += "\t\tcurrent_state.enter(self)\n\n"
	
	code += "\tprint(\"[FSM] \" + new_state_name + \" (from: \" + (previous_state.get_script().get_path().get_file().get_basename() if previous_state else \"none\") + \")\")\n\n"
	
	code += "# ============================================================\n"
	code += "# HELPER FUNCTIONS\n"
	code += "# ============================================================\n\n"
	
	code += "func _get_state_name(state: RefCounted) -> String:\n"
	code += "\t# Get state name from state object\n"
	code += "\tfor state_name in states.keys():\n"
	code += "\t\tif states[state_name] == state:\n"
	code += "\t\t\treturn state_name\n"
	code += "\treturn \"\"\n\n"
	
	code += "func get_current_state_name() -> String:\n"
	code += "\t# Get current state name\n"
	code += "\treturn _get_state_name(current_state) if current_state else \"\"\n\n"
	
	code += "func force_state(state_name: String) -> void:\n"
	code += "\t# Force change to state (ignores conditions)\n"
	code += "\tchange_state(state_name)\n\n"
	
	code += "# ============================================================\n"
	code += "# BLACKBOARD HELPERS\n"
	code += "# ============================================================\n\n"
	
	code += "func bb_set(key: String, value) -> void:\n"
	code += "\t# Set blackboard value\n"
	code += "\tblackboard[key] = value\n\n"
	
	code += "func bb_get(key: String, default = null):\n"
	code += "\t# Get blackboard value\n"
	code += "\treturn blackboard.get(key, default)\n\n"
	
	code += "func bb_has(key: String) -> bool:\n"
	code += "\t# Check if blackboard has key\n"
	code += "\treturn blackboard.has(key)\n"
	
	var file = FileAccess.open(path + config.script_name + ".gd", FileAccess.WRITE)
	file.store_string(code)
	file.close()
	print("✓ Generated professional main FSM with transitions and blackboard")

func _generate_state_file(path: String, state_node: GraphNode):
	var state_name = state_node.title
	var tabs = state_node.get_child(0) as TabContainer
	if not tabs:
		return
	
	# Get animation
	var anim_name = ""
	var basic_tab = tabs.get_child(0)
	for child in basic_tab.get_children():
		if child is OptionButton and child.selected > 0:
			anim_name = child.get_item_text(child.selected)
	
	# Get code blocks and clean them
	var enter_code = "pass"
	var update_code = "pass"
	var exit_code = "pass"
	
	if tabs.get_child_count() > 1:
		var enter_tab = tabs.get_child(1)
		for child in enter_tab.get_children():
			if child is TextEdit:
				enter_code = _clean_user_code(child.text)
	
	if tabs.get_child_count() > 2:
		var update_tab = tabs.get_child(2)
		for child in update_tab.get_children():
			if child is TextEdit:
				update_code = _clean_user_code(child.text)
	
	if tabs.get_child_count() > 3:
		var exit_tab = tabs.get_child(3)
		for child in exit_tab.get_children():
			if child is TextEdit:
				exit_code = _clean_user_code(child.text)
	
	# Generate state script
	var code = "# State: " + state_name + "\n"
	code += "extends RefCounted\n\n"
	
	if anim_name != "":
		code += "const ANIMATION = \"" + anim_name + "\"\n\n"
	
	# Determine if parameters are used
	var enter_uses_owner = enter_code.contains("owner") or anim_name != ""
	var update_uses_delta = update_code.contains("delta")
	var update_uses_owner = update_code.contains("owner")
	var exit_uses_owner = exit_code.contains("owner")
	
	# Generate enter function
	var enter_param = "owner" if enter_uses_owner else "_owner"
	code += "func enter(" + enter_param + "):\n"
	if anim_name != "":
		code += "\tif owner.animation_player:\n"
		code += "\t\towner.animation_player.play(ANIMATION)\n"
	
	# Add user code with proper indentation
	if enter_code.strip_edges() != "" and enter_code.strip_edges() != "pass":
		var enter_lines = enter_code.split("\n")
		for line in enter_lines:
			if line.strip_edges() != "":
				# Ensure line starts with tab
				if not line.begins_with("\t"):
					code += "\t" + line + "\n"
				else:
					code += line + "\n"
	else:
		code += "\t# Enter logic\n"
		code += "\tpass\n"
	code += "\n"
	
	# Generate update function
	var update_delta_param = "delta" if update_uses_delta else "_delta"
	var update_owner_param = "owner" if update_uses_owner else "_owner"
	code += "func update(" + update_delta_param + ", " + update_owner_param + "):\n"
	
	# Add user code with proper indentation
	if update_code.strip_edges() != "" and update_code.strip_edges() != "pass":
		var update_lines = update_code.split("\n")
		for line in update_lines:
			if line.strip_edges() != "":
				# Ensure line starts with tab
				if not line.begins_with("\t"):
					code += "\t" + line + "\n"
				else:
					code += line + "\n"
	else:
		code += "\t# Update logic\n"
		code += "\tpass\n"
	code += "\n"
	
	# Generate exit function
	var exit_param = "owner" if exit_uses_owner else "_owner"
	code += "func exit(" + exit_param + "):\n"
	
	# Add user code with proper indentation
	if exit_code.strip_edges() != "" and exit_code.strip_edges() != "pass":
		var exit_lines = exit_code.split("\n")
		for line in exit_lines:
			if line.strip_edges() != "":
				# Ensure line starts with tab
				if not line.begins_with("\t"):
					code += "\t" + line + "\n"
				else:
					code += line + "\n"
	else:
		code += "\t# Exit logic\n"
		code += "\tpass\n"
	code += "\n"
	
	var file = FileAccess.open(path + state_name + "_state.gd", FileAccess.WRITE)
	file.store_string(code)
	file.close()
	print("✓ Generated state: ", state_name)
