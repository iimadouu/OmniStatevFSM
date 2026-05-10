# OmniState Visual FSM

**Version 1.0.1** | **Released: May 9, 2026** | **Godot 4.6.x**

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue.svg)
![Version 1.0.1](https://img.shields.io/badge/Version-1.0.1-orange.svg)
![Quality: AAA](https://img.shields.io/badge/Quality-AAA-gold.svg)

---

OmniState AI is a professional visual state machine plugin for Godot 4.x. Build powerful enemy, NPC, and boss AI using a node-based editor and AAA code generation—with auto-recovery, bidirectional sync, and advanced transitions.

---

## 🚀 Key Highlights

- Visual drag-and-drop state machine editor
- AAA transition system: cooldowns, delays, priorities, blending
- Never lose work with auto-save & auto-recovery
- Smart merge: preserve custom code
- Bidirectional sync (editor or code)
- Animation & blackboard integration

---

## 📦 Installation

1. Enable “OmniState Visual AI” in Project → Project Settings → Plugins.
2. Or copy `addons/omnistate_ai/` to your project, then enable.

---

## 🛠️ Quick Start

1. Enable plugin and open “OmniState AI” panel.
2. Click ⚙ Setup, set script name, base class, and detect animations.
3. Add blackboard variables:  
   - `player_detected` (bool), `distance_to_player` (float), etc.
4. Create states: Patrol (initial), Chase, Attack.

```gdscript
# Patrol State (Update tab)
if owner.player:
    var d = owner.global_position.distance_to(owner.player.global_position)
    owner.bb_set("distance_to_player", d)
    owner.bb_set("player_detected", d < 20.0)
```

5. Add a transition from Patrol→Chase  
   Condition: `blackboard.get("player_detected", false)`
6. Click 💾 Generate, attach script, run game!

---

## 📝 Example

```gdscript
# Patrol → Chase transition:
Condition: blackboard.get("player_detected", false)
```

---

## 📚 More Documentation

- [Full Feature Guide](FULL_DOCUMENTATION.md)
- [Transition System](TRANSITION_SYSTEM.md)
- [Blackboard Guide](BLACKBOARD_GUIDE.md)
- [Quickstart](QUICKSTART.md)
- [Examples](EXAMPLES.md)
- [Changelog](CHANGELOG.md)
- [Release Notes](RELEASE_NOTES_v1.0.1.md)

---

## 💬 Support / License

- MIT License (see LICENSE).
- Open issues for bugs or feature requests.
- Star the repo if you find it helpful!
