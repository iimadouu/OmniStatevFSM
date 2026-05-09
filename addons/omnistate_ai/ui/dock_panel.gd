@tool
extends Control

var selected_state_label: Label
var properties_container: VBoxContainer

func _init():
	custom_minimum_size = Vector2(250, 300)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "State Properties"
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Selected state
	selected_state_label = Label.new()
	selected_state_label.text = "No state selected"
	vbox.add_child(selected_state_label)
	
	vbox.add_child(HSeparator.new())
	
	# Properties
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	properties_container = VBoxContainer.new()
	scroll.add_child(properties_container)

func update_for_state(state_node):
	selected_state_label.text = "State: " + state_node.get_state_name()
	
	# Clear existing properties
	for child in properties_container.get_children():
		child.queue_free()
	
	# Add property displays
	_add_property("Animation", state_node.get_selected_animation())
	_add_property("Initial State", "Yes" if state_node.is_initial_state() else "No")
	_add_property("Behaviors", str(state_node.behaviors.size()))
	_add_property("Transitions", str(state_node.transitions.size()))

func _add_property(label: String, value: String):
	var hbox = HBoxContainer.new()
	properties_container.add_child(hbox)
	
	var label_node = Label.new()
	label_node.text = label + ":"
	label_node.custom_minimum_size.x = 100
	hbox.add_child(label_node)
	
	var value_node = Label.new()
	value_node.text = value
	hbox.add_child(value_node)
