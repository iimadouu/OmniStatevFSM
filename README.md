# OmniState Visual FSM

**Version 1.0.2** | **Released: May 8, 2026** | **Updated: May 12, 2026** | **Godot 4.6.x**

OmniState Visual FSM is a visual state machine editor for Godot 4.6.x. It combines a simple node-based interface with a robust transition system, blackboard variables, animation blending, and automatic recovery features.

## Highlights

- Visual state machine editor with drag-and-drop workflow
- Transition system with cooldowns, delays, blending, and custom code
- Auto-save, auto-load, and recovery from generated code
- Sync between visual editor and generated .gd files
- Merge preserves custom functions and properties
- Blackboard variables for shared AI state
- Animation detection and playback integration
- State templates for faster behavior creation
- Clean code generation with type hints and organized structure


## Installation

### Method 1: Enable in this project
1. Open Godot
2. Go to `Project → Project Settings → Plugins`
3. Enable **OmniState**
4. Open the **OmniState** panel at the bottom of the editor

### Method 2: Install in another project
1. Copy the entire `addons/omnistate_ai/` folder
2. Paste it into the target project’s `addons/` directory
3. Enable it in Project Settings → Plugins


## More Documentation

- `FEATURES.md` — full feature breakdown, including transition system and blackboard usage
- `EXAMPLES.md` — example state machines
- `CHANGELOG.md` — version history
- `RELEASE_NOTES_v1.0.1.md` — release notes

---

*The generated files may contain few syntax errors, espicially indentation issues, but the code logic is accurate
