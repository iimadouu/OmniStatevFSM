# OmniState Visual AI - Version 1.0.1 Release Notes

**Release Date:** May 9, 2026

## 🎉 Major Update: Persistence & Smart Merge

This release fixes the **critical bug** where all your work would disappear when closing Godot, and introduces powerful new features for a seamless workflow between visual editor and code files.

---

## 🔥 What's New

### 1. 💾 Graph Persistence (CRITICAL FIX)

**The Problem:**
- Creating states, adding code, setting up transitions
- Close Godot
- Reopen → Everything gone! 😱

**The Solution:**
- ✅ Auto-save on exit
- ✅ Auto-load on startup  
- ✅ Manual save/load buttons
- ✅ JSON-based storage
- ✅ Never lose work again!

**How it works:**
Your visual graph is automatically saved to:
```
res://ai_states/[your_fsm_name]/[your_fsm_name]_graph.json
```

When you reopen Godot, it automatically loads your last saved state. Everything is exactly as you left it!

---

### 2. 🔄 Bidirectional Sync

**The Problem:**
- Generate code from visual editor
- Edit `.gd` files in IDE to add complex logic
- Want to update visual editor → No way to sync back! 😞

**The Solution:**
New **"🔄 Sync from Files"** button that:
- ✅ Reads generated state files
- ✅ Extracts code from `enter()`, `update()`, `exit()` functions
- ✅ Updates visual node code blocks
- ✅ Preserves your workflow flexibility

**Workflow:**
```
1. Design states visually
2. Generate code
3. Edit complex logic in your IDE
4. Click "🔄 Sync from Files"
5. Visual editor updates with your changes!
6. Continue editing visually or in IDE
```

**Features:**
- Auto-sync on startup
- Confirmation dialog (prevents accidents)
- Detailed sync report
- Smart code extraction

---

### 3. 🧠 Smart Merge Generation

**The Problem:**
- Generate initial code
- Add helper functions in IDE
- Edit visual editor and regenerate
- Helper functions deleted! 😭

**The Solution:**
Smart merge that **preserves your custom code**:
- ✅ Custom functions preserved
- ✅ Custom properties preserved
- ✅ Only standard functions regenerated
- ✅ Clear headers show what's safe to edit

**Example:**

Add custom code to generated file:
```gdscript
# Custom Properties
var attack_cooldown: float = 2.0
@export var damage: float = 10.0

# ... standard functions ...

# Custom Functions
func calculate_damage() -> float:
    return damage * randf_range(0.8, 1.2)

func is_attack_ready() -> bool:
    return Time.get_ticks_msec() > attack_cooldown
```

Regenerate from visual editor → **Custom code preserved!** ✅

**What gets regenerated:**
- `enter()`, `update()`, `exit()` functions
- `get_state_name()`, `get_transitions()`
- `ANIMATION_NAME` constant
- Header comments

**What gets preserved:**
- Your custom functions
- Your custom properties
- Your helper methods
- Your utility code

---

## 🎯 Why This Matters

### Before v1.0.1:
```
❌ Work disappears on close
❌ Can't sync code back to visual editor
❌ Custom code lost on regenerate
❌ Forced to choose: visual OR code editing
```

### After v1.0.1:
```
✅ Work persists forever
✅ Edit anywhere, sync everywhere
✅ Custom code always preserved
✅ Best of both worlds: visual AND code editing
```

---

## 📊 Complete Feature Matrix

| Feature | v1.0.0 | v1.0.1 |
|---------|--------|--------|
| Visual state editor | ✅ | ✅ |
| Code generation | ✅ | ✅ |
| Graph persistence | ❌ | ✅ |
| Auto-save/load | ❌ | ✅ |
| Sync from files | ❌ | ✅ |
| Smart merge | ❌ | ✅ |
| Custom code preservation | ❌ | ✅ |
| Bidirectional workflow | ❌ | ✅ |

---

## 🚀 Getting Started

### For New Users:
1. Install the addon
2. Open OmniState panel
3. Click "⚙ Setup Wizard"
4. Create states visually
5. Click "💾 Save & Generate"
6. Your work is automatically saved!

### For Existing Users:
1. Update to v1.0.1
2. Open your project
3. Your existing work will be auto-saved going forward
4. Regenerate states to enable smart merge
5. Start using bidirectional sync!

---

## 📚 Documentation
- **[CHANGELOG.md](CHANGELOG.md)** - Full version history
- **[README.md](README.md)** - Updated with new features

---

## 🔧 Technical Details

### File Structure:
```
res://ai_states/
└── your_fsm/
    ├── your_fsm_graph.json      ← NEW: Visual graph state
    ├── your_fsm.gd               ← Main FSM controller
    ├── idle_state.gd             ← State files (smart merge)
    ├── patrol_state.gd           ← State files (smart merge)
    └── ...
```

### Auto-Save Triggers:
- Closing Godot
- Clicking "💾 Save & Generate"
- After "🔄 Sync from Files"

### Auto-Load Triggers:
- Opening Godot
- Opening OmniState panel

---

## ⚠️ Breaking Changes

**None!** This is a fully backward-compatible update.

Existing projects will automatically benefit from:
- Persistence (starts working immediately)
- Smart merge (enabled on first regeneration)
- Sync (available when you need it)

---

## 🐛 Bug Fixes

### Critical:
- **Fixed:** Graph state not persisting between sessions
- **Fixed:** All work lost when closing Godot

### Minor:
- Improved error messages
- Better console logging
- Enhanced file handling

---

## 🎁 Bonus Features

### Enhanced Headers:
Generated files now have clear documentation:
```gdscript
# ✅ SAFE TO EDIT:
# • Add custom functions - they will be preserved
# • Add custom properties - they will be preserved
# • Edit enter/update/exit in visual editor, not here
#
# ⚠️ REGENERATED ON SAVE:
# • enter(), update(), exit() functions
# • get_state_name(), get_transitions()
# • ANIMATION_NAME constant
```

### Better Console Output:
```
🔄 Auto-loading saved graph...
✓ Graph loaded from: res://ai_states/enemy_ai/enemy_ai_graph.json
🔄 Auto-syncing from generated files...
✓ Synced: idle
✓ Synced: patrol
✓ Synced: chase
💾 Auto-saved graph after sync
```

---

## 🙏 Thank You

Thank you for using OmniState Visual AI! This update addresses the most critical issues and sets the foundation for an even more powerful workflow.

If you encounter any issues or have suggestions, please let us know!

---

## 📈 What's Next?

### Planned for v1.1.0:
- Visual debugging tools
- State machine preview/simulation
- Performance profiling
- More state templates
- Enhanced validation

### Planned for v1.2.0:
- Multi-FSM support
- Hierarchical state machines
- State machine inheritance
- Visual scripting integration

---

**Happy State Machine Building!** 🎉

---

**Version:** 1.0.1  
**Release Date:** May 9, 2026  
**License:** MIT  
**Author:** Imad Eddine Aris
