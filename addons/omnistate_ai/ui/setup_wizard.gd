@tool
extends ConfirmationDialog

var script_name_input: LineEdit
var enemy_scene_input: LineEdit
var player_scene_input: LineEdit
var animation_player_path_input: LineEdit
var base_class_option: OptionButton
var auto_detect_animations_check: CheckBox

var detected_animations: Array = []

func _init():
	title = "OmniState AI - Initial Setup Wizard"
	min_size = Vector2(500, 450)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 400)
	add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "Configure your AI State Machine"
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Target Script Name
	var script_label = Label.new()
	script_label.text = "Main AI Script Name:"
	vbox.add_child(script_label)
	
	script_name_input = LineEdit.new()
	script_name_input.text = "enemy_fsm"
	script_name_input.placeholder_text = "e.g., enemy_ai, guard_fsm"
	vbox.add_child(script_name_input)
	
	vbox.add_child(HSeparator.new())
	
	# Base Class Selection
	var base_class_label = Label.new()
	base_class_label.text = "Base Class Type:"
	vbox.add_child(base_class_label)
	
	base_class_option = OptionButton.new()
	base_class_option.add_item("CharacterBody3D", 0)
	base_class_option.add_item("CharacterBody2D", 1)
	base_class_option.add_item("Node3D", 2)
	base_class_option.add_item("Node2D", 3)
	base_class_option.add_item("Node", 4)
	base_class_option.selected = 0
	vbox.add_child(base_class_option)
	
	vbox.add_child(HSeparator.new())
	
	# Enemy Scene
	var enemy_label = Label.new()
	enemy_label.text = "Enemy Scene Path (optional):"
	vbox.add_child(enemy_label)
	
	var enemy_hbox = HBoxContainer.new()
	vbox.add_child(enemy_hbox)
	
	enemy_scene_input = LineEdit.new()
	enemy_scene_input.placeholder_text = "res://scenes/enemies/enemy.tscn"
	enemy_scene_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_scene_input.text_changed.connect(_on_enemy_scene_changed)
	enemy_hbox.add_child(enemy_scene_input)
	
	var browse_enemy_btn = Button.new()
	browse_enemy_btn.text = "Browse"
	browse_enemy_btn.pressed.connect(_on_browse_enemy_pressed)
	enemy_hbox.add_child(browse_enemy_btn)
	
	# Player Scene
	var player_label = Label.new()
	player_label.text = "Player Scene Path (optional):"
	vbox.add_child(player_label)
	
	var player_hbox = HBoxContainer.new()
	vbox.add_child(player_hbox)
	
	player_scene_input = LineEdit.new()
	player_scene_input.placeholder_text = "res://scenes/player/player.tscn"
	player_scene_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(player_scene_input)
	
	vbox.add_child(HSeparator.new())
	
	# AnimationPlayer Path
	var anim_label = Label.new()
	anim_label.text = "AnimationPlayer Node Path (in enemy scene):"
	vbox.add_child(anim_label)
	
	animation_player_path_input = LineEdit.new()
	animation_player_path_input.placeholder_text = "AnimationPlayer or Model/AnimationPlayer"
	animation_player_path_input.text = "AnimationPlayer"
	vbox.add_child(animation_player_path_input)
	
	# Auto-detect animations
	auto_detect_animations_check = CheckBox.new()
	auto_detect_animations_check.text = "Auto-detect animations from enemy scene"
	auto_detect_animations_check.button_pressed = true
	vbox.add_child(auto_detect_animations_check)
	
	var detect_btn = Button.new()
	detect_btn.text = "Detect Animations Now"
	detect_btn.pressed.connect(_on_detect_animations_pressed)
	vbox.add_child(detect_btn)

func _on_browse_enemy_pressed():
	# TODO: Open file dialog for scene selection
	pass

func _on_enemy_scene_changed(new_text: String):
	if auto_detect_animations_check.button_pressed and new_text != "":
		_detect_animations_from_scene(new_text)

func _on_detect_animations_pressed():
	if enemy_scene_input.text != "":
		_detect_animations_from_scene(enemy_scene_input.text)

func _detect_animations_from_scene(scene_path: String):
	detected_animations.clear()
	
	if not ResourceLoader.exists(scene_path):
		print("Scene not found: ", scene_path)
		return
	
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		var anim_player = instance.get_node_or_null(animation_player_path_input.text)
		
		if anim_player and anim_player is AnimationPlayer:
			var anim_list = anim_player.get_animation_list()
			for anim_name in anim_list:
				detected_animations.append(anim_name)
			print("Detected animations: ", detected_animations)
		else:
			print("AnimationPlayer not found at path: ", animation_player_path_input.text)
		
		instance.queue_free()

func get_base_class_name() -> String:
	match base_class_option.selected:
		0: return "CharacterBody3D"
		1: return "CharacterBody2D"
		2: return "Node3D"
		3: return "Node2D"
		_: return "Node"