@tool
extends GraphNode
class_name OmniStateNode

# UI Elements
var state_name_input: LineEdit
var anim_input: OptionButton
var is_initial_state_check: CheckBox
var state_color_picker: ColorPickerButton
var code_input: CodeEdit
var enter_code_input: CodeEdit
var exit_code_input: CodeEdit
var conditions_container: VBoxContainer
var behaviors_container: VBoxContainer

# State Data
var state_id: String = ""
var transitions: Array = []  # Array of {to_state: String, condition: String}
var behaviors: Array = []  # Array of behavior names
var state_color: Color = Color.CORNFLOWER_BLUE

# Signals
signal state_selected(state_node: OmniStateNode)
signal state_data_changed()

func _init():
	title = "New State"
	resizable = true
	draggable = true
	custom_minimum_size = Vector2(350, 400)
	state_id = str(Time.get_ticks_msec()) + "_" + str(randi())
	
	# Create ports for connections
	_setup_ui()
	
	# Add close button to titlebar after UI is set up
	call_deferred("_add_close_button")
	
	# Context menu
	gui_input.connect(_on_gui_input)

func _add_close_button():
	var titlebar = get_titlebar_hbox()
	
	# Add transition counter badge
	var trans_badge = Label.new()
	trans_badge.name = "TransitionBadge"
	trans_badge.text = "→0"
	trans_badge.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	trans_badge.add_theme_font_size_override("font_size", 10)
	trans_badge.tooltip_text = "Number of outgoing transitions"
	titlebar.add_child(trans_badge)
	
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(func(): queue_free())
	titlebar.add_child(close_btn)

func _setup_ui():
	# Main container with tabs
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(330, 350)
	add_child(tab_container)
	
	# === TAB 1: Basic Settings ===
	var basic_tab = VBoxContainer.new()
	basic_tab.name = "Basic"
	tab_container.add_child(basic_tab)
	
	# State Name
	var name_label = Label.new()
	name_label.text = "State Name:"
	basic_tab.add_child(name_label)
	
	state_name_input = LineEdit.new()
	state_name_input.placeholder_text = "e.g., Patrol, Cover, Attack"
	state_name_input.text_changed.connect(_on_state_name_changed)
	basic_tab.add_child(state_name_input)
	
	# Initial State Checkbox
	is_initial_state_check = CheckBox.new()
	is_initial_state_check.text = "Initial State"
	is_initial_state_check.toggled.connect(on_initial_state_toggled)
	basic_tab.add_child(is_initial_state_check)
	
	# State Color
	var color_hbox = HBoxContainer.new()
	basic_tab.add_child(color_hbox)
	
	var color_label = Label.new()
	color_label.text = "Node Color:"
	color_hbox.add_child(color_label)
	
	state_color_picker = ColorPickerButton.new()
	state_color_picker.color = state_color
	state_color_picker.color_changed.connect(_on_color_changed)
	color_hbox.add_child(state_color_picker)
	
	# Animation Selection
	var anim_label = Label.new()
	anim_label.text = "Animation:"
	basic_tab.add_child(anim_label)
	
	anim_input = OptionButton.new()
	anim_input.add_item("(None)", 0)
	anim_input.item_selected.connect(_on_animation_selected)
	basic_tab.add_child(anim_input)
	
	# Dynamic Animation Checkbox
	var dynamic_anim_check = CheckBox.new()
	dynamic_anim_check.name = "DynamicAnimCheck"
	dynamic_anim_check.text = "Set animation dynamically in Enter code"
	dynamic_anim_check.tooltip_text = "Enable this if you need to choose animation at runtime based on conditions"
	dynamic_anim_check.toggled.connect(_on_dynamic_anim_toggled)
	basic_tab.add_child(dynamic_anim_check)
	
	# Behaviors Section
	var behaviors_label = Label.new()
	behaviors_label.text = "Behaviors:"
	basic_tab.add_child(behaviors_label)
	
	behaviors_container = VBoxContainer.new()
	basic_tab.add_child(behaviors_container)
	
	var add_behavior_btn = Button.new()
	add_behavior_btn.text = "+ Add Behavior"
	add_behavior_btn.pressed.connect(_on_add_behavior_pressed)
	basic_tab.add_child(add_behavior_btn)
	
	# === TAB 2: Enter Code ===
	var enter_tab = VBoxContainer.new()
	enter_tab.name = "Enter"
	tab_container.add_child(enter_tab)
	
	var enter_label = Label.new()
	enter_label.text = "Code executed when entering this state:"
	enter_tab.add_child(enter_label)
	
	enter_code_input = CodeEdit.new()
	enter_code_input.custom_minimum_size = Vector2(310, 280)
	enter_code_input.syntax_highlighter = _create_syntax_highlighter()
	enter_code_input.text = "# Enter state logic\npass"
	enter_tab.add_child(enter_code_input)
	
	# === TAB 3: Update Code ===
	var update_tab = VBoxContainer.new()
	update_tab.name = "Update"
	tab_container.add_child(update_tab)
	
	var update_label = Label.new()
	update_label.text = "Code executed every frame (_physics_process):"
	update_tab.add_child(update_label)
	
	code_input = CodeEdit.new()
	code_input.custom_minimum_size = Vector2(310, 280)
	code_input.syntax_highlighter = _create_syntax_highlighter()
	code_input.text = "# Update state logic\npass"
	update_tab.add_child(code_input)
	
	# === TAB 4: Exit Code ===
	var exit_tab = VBoxContainer.new()
	exit_tab.name = "Exit"
	tab_container.add_child(exit_tab)
	
	var exit_label = Label.new()
	exit_label.text = "Code executed when exiting this state:"
	exit_tab.add_child(exit_label)
	
	exit_code_input = CodeEdit.new()
	exit_code_input.custom_minimum_size = Vector2(310, 280)
	exit_code_input.syntax_highlighter = _create_syntax_highlighter()
	exit_code_input.text = "# Exit state logic\npass"
	exit_tab.add_child(exit_code_input)
	
	# === TAB 5: Transitions ===
	var transitions_tab = VBoxContainer.new()
	transitions_tab.name = "Transitions"
	tab_container.add_child(transitions_tab)
	
	var trans_label = Label.new()
	trans_label.text = "Transition Conditions:"
	transitions_tab.add_child(trans_label)
	
	conditions_container = VBoxContainer.new()
	transitions_tab.add_child(conditions_container)
	
	# Set up connection ports
	set_slot(0, true, 0, state_color, true, 0, state_color)

func _create_syntax_highlighter() -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	
	# Keywords
	var keywords = ["func", "var", "if", "else", "elif", "for", "while", "return", "pass", 
					"true", "false", "null", "and", "or", "not", "in", "is", "extends", 
					"class_name", "signal", "await", "self"]
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color.PINK)
	
	# Types
	var types = ["int", "float", "String", "bool", "Vector2", "Vector3", "Node", "CharacterBody3D"]
	for type in types:
		highlighter.add_keyword_color(type, Color.LIGHT_BLUE)
	
	# Comments
	highlighter.add_color_region("#", "", Color.DIM_GRAY, true)
	
	# Strings
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)
	
	return highlighter

func _on_state_name_changed(new_name: String):
	title = new_name if new_name != "" else "New State"
	state_data_changed.emit()

func on_initial_state_toggled(pressed: bool):
	if pressed:
		modulate = Color(1.2, 1.2, 1.0)
	else:
		modulate = Color.WHITE
	state_data_changed.emit()

func _on_color_changed(color: Color):
	state_color = color
	set_slot(0, true, 0, state_color, true, 0, state_color)
	state_data_changed.emit()

func _on_animation_selected(index: int):
	state_data_changed.emit()

func _on_dynamic_anim_toggled(pressed: bool):
	# Disable animation dropdown when dynamic mode is enabled
	anim_input.disabled = pressed
	if pressed:
		anim_input.select(0)  # Set to (None)
	state_data_changed.emit()

func _on_add_behavior_pressed():
	var behavior_dialog = AcceptDialog.new()
	behavior_dialog.title = "Add Behavior"
	behavior_dialog.min_size = Vector2(300, 150)
	
	var vbox = VBoxContainer.new()
	behavior_dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Behavior name (e.g., 'is_covering', 'can_see_player'):"
	vbox.add_child(label)
	
	var input = LineEdit.new()
	input.placeholder_text = "behavior_name"
	vbox.add_child(input)
	
	behavior_dialog.confirmed.connect(func():
		if input.text != "":
			_add_behavior(input.text)
		behavior_dialog.queue_free()
	)
	
	add_child(behavior_dialog)
	behavior_dialog.popup_centered()

func _add_behavior(behavior_name: String):
	behaviors.append(behavior_name)
	
	var behavior_item = HBoxContainer.new()
	behaviors_container.add_child(behavior_item)
	
	var label = Label.new()
	label.text = "• " + behavior_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	behavior_item.add_child(label)
	
	var remove_btn = Button.new()
	remove_btn.text = "X"
	remove_btn.pressed.connect(func():
		behaviors.erase(behavior_name)
		behavior_item.queue_free()
		state_data_changed.emit()
	)
	behavior_item.add_child(remove_btn)
	
	state_data_changed.emit()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			state_selected.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu()

func _show_context_menu():
	var popup = PopupMenu.new()
	popup.add_item("Add Transition", 0)
	popup.add_item("Duplicate State", 1)
	popup.add_separator()
	popup.add_item("Delete State", 2)
	
	popup.id_pressed.connect(_on_context_menu_selected)
	add_child(popup)
	popup.popup(Rect2(get_global_mouse_position(), Vector2(150, 100)))

func _on_context_menu_selected(id: int):
	match id:
		0:  # Add Transition
			print("Add transition from: ", title)
		1:  # Duplicate
			print("Duplicate state: ", title)
		2:  # Delete
			queue_free()

func add_animation_option(anim_name: String):
	anim_input.add_item(anim_name)

func get_selected_animation() -> String:
	if anim_input.selected == 0:
		return ""
	return anim_input.get_item_text(anim_input.selected)

func is_dynamic_animation() -> bool:
	var check = get_node_or_null("TabContainer/Basic/DynamicAnimCheck")
	return check != null and check.button_pressed

func get_state_name() -> String:
	return state_name_input.text if state_name_input.text != "" else "unnamed_state"

func is_initial_state() -> bool:
	return is_initial_state_check.button_pressed

func add_transition_condition(to_state: String, condition: String, settings: Dictionary = {}):
	var entry = {
		"to_state": to_state,
		"condition": condition,
		"priority": settings.get("priority", 10),
		"delay": settings.get("delay", 0.0),
		"cooldown": settings.get("cooldown", 0.0),
		"can_interrupt": settings.get("can_interrupt", true),
		"blend_time": settings.get("blend_time", 0.0),
		"custom_code": settings.get("custom_code", ""),
		"debug_log": settings.get("debug_log", false),
		"debug_label": settings.get("debug_label", ""),
	}
	transitions.append(entry)
	refresh_transitions_display()

func refresh_transitions_display():
	# Clear existing
	for child in conditions_container.get_children():
		child.queue_free()
	
	# Add each transition
	for i in range(transitions.size()):
		var trans = transitions[i]
		var trans_item = HBoxContainer.new()
		conditions_container.add_child(trans_item)
		
		var label = Label.new()
		var priority_str = " [P:%d]" % trans.get("priority", 10)
		var delay_str = " [D:%.1fs]" % trans.get("delay", 0.0) if trans.get("delay", 0.0) > 0 else ""
		var cooldown_str = " [CD:%.1fs]" % trans.get("cooldown", 0.0) if trans.get("cooldown", 0.0) > 0 else ""
		label.text = "→ %s  when: %s%s%s%s" % [trans.to_state, trans.condition, priority_str, delay_str, cooldown_str]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 10)
		trans_item.add_child(label)
		
		# Edit button
		var edit_btn = Button.new()
		edit_btn.text = "✏"
		edit_btn.flat = true
		edit_btn.custom_minimum_size = Vector2(28, 24)
		edit_btn.tooltip_text = "Edit this transition"
		var idx = i  # capture for lambda
		edit_btn.pressed.connect(func(): _edit_transition(idx))
		trans_item.add_child(edit_btn)
		
		# Remove button
		var remove_btn = Button.new()
		remove_btn.text = "×"
		remove_btn.flat = true
		remove_btn.custom_minimum_size = Vector2(24, 24)
		remove_btn.pressed.connect(func():
			transitions.remove_at(idx)
			refresh_transitions_display()
			state_data_changed.emit()
		)
		trans_item.add_child(remove_btn)
	
	# Update transition counter badge in title
	_update_transition_badge()

func _edit_transition(index: int):
	if index < 0 or index >= transitions.size():
		return
	
	var trans = transitions[index]
	
	# Load the transition dialog
	var TransitionDialogClass = load("res://addons/omnistate_ai/ui/transition_dialog.gd")
	var dlg = TransitionDialogClass.new()
	add_child(dlg)
	
	# Populate with all states — we need the parent graph to get state names
	# Build a simple list from the parent graph_edit
	var state_names: Array = []
	var graph = _find_graph_edit()
	if graph:
		for node in graph.get_children():
			if node is OmniStateNode:
				state_names.append(node.get_state_name())
	
	# Manually populate the dropdowns since we don't have OmniStateNode refs here
	dlg.from_state_option.clear()
	dlg.to_state_option.clear()
	dlg.from_state_option.add_item("[ANY]")
	dlg.to_state_option.add_item("[ANY]")
	for sn in state_names:
		dlg.from_state_option.add_item(sn)
		dlg.to_state_option.add_item(sn)
	
	# Pre-select from = this state, to = trans.to_state
	var my_name = get_state_name()
	for i in range(dlg.from_state_option.item_count):
		if dlg.from_state_option.get_item_text(i) == my_name:
			dlg.from_state_option.selected = i
			break
	for i in range(dlg.to_state_option.item_count):
		if dlg.to_state_option.get_item_text(i) == trans.to_state:
			dlg.to_state_option.selected = i
			break
	
	# Fill in all fields
	dlg.condition_input.text = trans.get("condition", "")
	dlg.priority_input.value = trans.get("priority", 10)
	dlg.delay_input.value = trans.get("delay", 0.0)
	dlg.cooldown_input.value = trans.get("cooldown", 0.0)
	dlg.interrupt_check.button_pressed = trans.get("can_interrupt", true)
	dlg.blend_input.value = trans.get("blend_time", 0.0)
	dlg.custom_code_input.text = trans.get("custom_code", "")
	dlg.debug_log_check.button_pressed = trans.get("debug_log", false)
	dlg.debug_label_input.text = trans.get("debug_label", "")
	
	dlg.confirmed.connect(func():
		var data = dlg.get_transition_data()
		# Replace the entry at index in-place
		transitions[index] = {
			"to_state": data.to_state,
			"condition": data.condition,
			"priority": data.priority,
			"delay": data.delay,
			"cooldown": data.cooldown,
			"can_interrupt": data.can_interrupt,
			"blend_time": data.blend_time,
			"custom_code": data.custom_code,
			"debug_log": data.debug_log,
			"debug_label": data.debug_label,
		}
		refresh_transitions_display()
		state_data_changed.emit()
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _find_graph_edit() -> GraphEdit:
	# Walk up the tree to find the GraphEdit that contains this node
	var p = get_parent()
	while p:
		if p is GraphEdit:
			return p
		p = p.get_parent()
	return null

func _update_transition_badge():
	"""Update the transition counter badge in the titlebar"""
	var titlebar = get_titlebar_hbox()
	var badge = titlebar.get_node_or_null("TransitionBadge")
	if badge:
		var count = transitions.size()
		badge.text = "→" + str(count)
		# Color code: green if has transitions, gray if none
		if count > 0:
			badge.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			badge.add_theme_color_override("font_color", Color.GRAY)
