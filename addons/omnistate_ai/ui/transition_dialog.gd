@tool
extends ConfirmationDialog

var from_state_option: OptionButton
var to_state_option: OptionButton
var condition_input: LineEdit
var condition_templates: OptionButton

func _init():
	title = "Add Transition"
	min_size = Vector2(450, 300)
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# From State
	var from_label = Label.new()
	from_label.text = "From State:"
	vbox.add_child(from_label)
	
	from_state_option = OptionButton.new()
	vbox.add_child(from_state_option)
	
	vbox.add_child(HSeparator.new())
	
	# To State
	var to_label = Label.new()
	to_label.text = "To State:"
	vbox.add_child(to_label)
	
	to_state_option = OptionButton.new()
	vbox.add_child(to_state_option)
	
	vbox.add_child(HSeparator.new())
	
	# Condition
	var condition_label = Label.new()
	condition_label.text = "Transition Condition:"
	vbox.add_child(condition_label)
	
	condition_input = LineEdit.new()
	condition_input.placeholder_text = "e.g., player_detected, health < 30"
	vbox.add_child(condition_input)
	
	# Condition Templates
	var template_label = Label.new()
	template_label.text = "Or use a template:"
	vbox.add_child(template_label)
	
	condition_templates = OptionButton.new()
	condition_templates.add_item("(Custom)", 0)
	condition_templates.add_item("player_detected", 1)
	condition_templates.add_item("player_in_range", 2)
	condition_templates.add_item("health_low", 3)
	condition_templates.add_item("can_see_player", 4)
	condition_templates.add_item("is_under_fire", 5)
	condition_templates.add_item("ammo_empty", 6)
	condition_templates.add_item("timer_expired", 7)
	condition_templates.item_selected.connect(_on_template_selected)
	vbox.add_child(condition_templates)
	
	# Examples
	var examples = Label.new()
	examples.text = "Examples:\n• player_detected\n• health < 30\n• distance_to_player < 10.0\n• can_see_player and not is_reloading"
	examples.add_theme_font_size_override("font_size", 10)
	vbox.add_child(examples)

func setup_with_states(states: Array):
	from_state_option.clear()
	to_state_option.clear()
	
	for state in states:
		var state_name = state.get_state_name()
		from_state_option.add_item(state_name)
		to_state_option.add_item(state_name)

func _on_template_selected(index: int):
	match index:
		1: condition_input.text = "player_detected"
		2: condition_input.text = "player_in_range"
		3: condition_input.text = "health_low"
		4: condition_input.text = "can_see_player"
		5: condition_input.text = "is_under_fire"
		6: condition_input.text = "ammo_empty"
		7: condition_input.text = "timer_expired"
