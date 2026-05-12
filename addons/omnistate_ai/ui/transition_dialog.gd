@tool
extends ConfirmationDialog

var from_state_option: OptionButton
var to_state_option: OptionButton
var condition_input: LineEdit
var condition_templates: OptionButton

# Priority & Timing
var priority_input: SpinBox
var delay_input: SpinBox
var cooldown_input: SpinBox

# Advanced
var interrupt_check: CheckBox
var blend_input: SpinBox
var custom_code_input: TextEdit

# Debug
var debug_log_check: CheckBox
var debug_label_input: LineEdit

var _ui_built: bool = false

func _init():
	title = "Add / Edit Transition"
	min_size = Vector2(520, 580)

func _ready():
	if not _ui_built:
		_build_ui()

func _build_ui():
	if _ui_built:
		return
	_ui_built = true

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 530)
	
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# ── FROM / TO ──────────────────────────────────────────
	var from_label = Label.new()
	from_label.text = "From State:"
	vbox.add_child(from_label)

	from_state_option = OptionButton.new()
	vbox.add_child(from_state_option)

	vbox.add_child(HSeparator.new())

	var to_label = Label.new()
	to_label.text = "To State:"
	vbox.add_child(to_label)

	to_state_option = OptionButton.new()
	vbox.add_child(to_state_option)

	vbox.add_child(HSeparator.new())

	# ── CONDITION ──────────────────────────────────────────
	var cond_header = Label.new()
	cond_header.text = "Condition:"
	cond_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(cond_header)

	condition_input = LineEdit.new()
	condition_input.placeholder_text = "e.g., player_detected, health < 30"
	vbox.add_child(condition_input)

	var template_label = Label.new()
	template_label.text = "Quick presets:"
	template_label.add_theme_color_override("font_color", Color.GRAY)
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
	condition_templates.add_item("is_covering", 8)
	condition_templates.add_item("enemy_nearby", 9)
	condition_templates.add_item("path_clear", 10)
	condition_templates.item_selected.connect(_on_template_selected)
	vbox.add_child(condition_templates)

	var examples = Label.new()
	examples.text = "Examples:  player_detected  |  health < 30  |  distance_to_player < 10.0  |  can_see_player and not is_reloading"
	examples.add_theme_font_size_override("font_size", 10)
	examples.add_theme_color_override("font_color", Color.GRAY)
	examples.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(examples)

	vbox.add_child(HSeparator.new())

	# ── PRIORITY & TIMING ──────────────────────────────────
	var timing_header = Label.new()
	timing_header.text = "Priority & Timing:"
	timing_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(timing_header)

	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)

	var prio_lbl = Label.new()
	prio_lbl.text = "Priority (0 = highest):"
	grid.add_child(prio_lbl)

	priority_input = SpinBox.new()
	priority_input.min_value = 0
	priority_input.max_value = 100
	priority_input.value = 10
	priority_input.step = 1
	priority_input.tooltip_text = "Lower number = higher priority. 0 is the highest (e.g. death)."
	grid.add_child(priority_input)

	var delay_lbl = Label.new()
	delay_lbl.text = "Delay (seconds):"
	grid.add_child(delay_lbl)

	delay_input = SpinBox.new()
	delay_input.min_value = 0.0
	delay_input.max_value = 10.0
	delay_input.value = 0.0
	delay_input.step = 0.1
	delay_input.tooltip_text = "Wait this long after condition is true before transitioning."
	grid.add_child(delay_input)

	var cooldown_lbl = Label.new()
	cooldown_lbl.text = "Cooldown (seconds):"
	grid.add_child(cooldown_lbl)

	cooldown_input = SpinBox.new()
	cooldown_input.min_value = 0.0
	cooldown_input.max_value = 60.0
	cooldown_input.value = 0.0
	cooldown_input.step = 0.5
	cooldown_input.tooltip_text = "Minimum time before this transition can fire again."
	grid.add_child(cooldown_input)

	vbox.add_child(HSeparator.new())

	# ── ADVANCED ───────────────────────────────────────────
	var adv_header = Label.new()
	adv_header.text = "Advanced:"
	adv_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(adv_header)

	var adv_grid = GridContainer.new()
	adv_grid.columns = 2
	vbox.add_child(adv_grid)

	var interrupt_lbl = Label.new()
	interrupt_lbl.text = "Can Interrupt:"
	adv_grid.add_child(interrupt_lbl)

	interrupt_check = CheckBox.new()
	interrupt_check.button_pressed = true
	interrupt_check.tooltip_text = "If unchecked, the current state must finish before transitioning."
	adv_grid.add_child(interrupt_check)

	var blend_lbl = Label.new()
	blend_lbl.text = "Anim Blend (seconds):"
	adv_grid.add_child(blend_lbl)

	blend_input = SpinBox.new()
	blend_input.min_value = 0.0
	blend_input.max_value = 2.0
	blend_input.value = 0.0
	blend_input.step = 0.05
	blend_input.tooltip_text = "Smooth animation blend time when transitioning."
	adv_grid.add_child(blend_input)

	var code_lbl = Label.new()
	code_lbl.text = "Custom Code on Transition:"
	vbox.add_child(code_lbl)

	custom_code_input = TextEdit.new()
	custom_code_input.custom_minimum_size = Vector2(0, 60)
	custom_code_input.placeholder_text = "# Optional GDScript executed when this transition fires"
	vbox.add_child(custom_code_input)

	vbox.add_child(HSeparator.new())

	# ── DEBUG ──────────────────────────────────────────────
	var dbg_header = Label.new()
	dbg_header.text = "Debug:"
	dbg_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(dbg_header)

	var dbg_grid = GridContainer.new()
	dbg_grid.columns = 2
	vbox.add_child(dbg_grid)

	var dbg_log_lbl = Label.new()
	dbg_log_lbl.text = "Log this transition:"
	dbg_grid.add_child(dbg_log_lbl)

	debug_log_check = CheckBox.new()
	debug_log_check.button_pressed = false
	debug_log_check.tooltip_text = "Print to console whenever this transition fires."
	dbg_grid.add_child(debug_log_check)

	var dbg_label_lbl = Label.new()
	dbg_label_lbl.text = "Debug label:"
	dbg_grid.add_child(dbg_label_lbl)

	debug_label_input = LineEdit.new()
	debug_label_input.placeholder_text = "Optional label for logs"
	dbg_grid.add_child(debug_label_input)


func setup_with_states(states: Array):
	if not _ui_built:
		_build_ui()

	from_state_option.clear()
	to_state_option.clear()

	# [ANY] means "add this transition to every state"
	from_state_option.add_item("[ANY]")
	to_state_option.add_item("[ANY]")

	for state in states:
		var state_name = state.get_state_name()
		from_state_option.add_item(state_name)
		to_state_option.add_item(state_name)

	# Reset fields to defaults
	condition_input.text = ""
	condition_templates.selected = 0
	priority_input.value = 10
	delay_input.value = 0.0
	cooldown_input.value = 0.0
	interrupt_check.button_pressed = true
	blend_input.value = 0.0
	custom_code_input.text = ""
	debug_log_check.button_pressed = false
	debug_label_input.text = ""


func get_transition_data() -> Dictionary:
	return {
		"from_state": from_state_option.get_item_text(from_state_option.selected),
		"to_state": to_state_option.get_item_text(to_state_option.selected),
		"condition": condition_input.text.strip_edges(),
		"priority": int(priority_input.value),
		"delay": delay_input.value,
		"cooldown": cooldown_input.value,
		"can_interrupt": interrupt_check.button_pressed,
		"blend_time": blend_input.value,
		"custom_code": custom_code_input.text.strip_edges(),
		"debug_log": debug_log_check.button_pressed,
		"debug_label": debug_label_input.text.strip_edges(),
	}


func _on_template_selected(index: int):
	match index:
		1: condition_input.text = "player_detected"
		2: condition_input.text = "player_in_range"
		3: condition_input.text = "health_low"
		4: condition_input.text = "can_see_player"
		5: condition_input.text = "is_under_fire"
		6: condition_input.text = "ammo_empty"
		7: condition_input.text = "timer_expired"
		8: condition_input.text = "is_covering"
		9: condition_input.text = "enemy_nearby"
		10: condition_input.text = "path_clear"
