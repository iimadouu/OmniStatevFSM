@tool
extends EditorPlugin

var main_panel: Control

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
