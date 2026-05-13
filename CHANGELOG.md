# Changelog

All notable changes to OmniState Visual AI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.0.2] - 2026-05-12

### 🐛 Critical Bug Fixes
- **CRITICAL FIX**:  I upgraded the _generate_main_fsm function. Before, it was blindly deleting and recreating the main FSM script from scratch. Now, before it generates the new file, it reads the existing one, actively searches for any custom functions or custom variables, saves them in memory, and safely injects them at the bottom of the newly generated script!
- Now, whenever you click the "Generate Code" button, it checks to see if the FSM directory and files already exist. If they do, it will immediately pause and show a pop-up dialog that says: "Warning: Overwrite Files" "Do you want to proceed? This action will overwrite your state files. Your manual edits inside state update/enter functions may be lost. Please click 'Sync from Files' first to save manual edits."

### ✨ New Features 

- new confirmation window whenever you click the "Generate Code" button, it checks to see if the FSM directory and files already exist which should prevent blind code overwriting.

  

## [1.0.1] - 2026-05-09

### 🐛 Critical Bug Fixes

#### Fixed: Graph State Not Persisting
- **CRITICAL FIX**: Visual graph state is now saved and persists between Godot sessions
- Previously, all state nodes, connections, and code would disappear when closing Godot
- Graph data now saved to `res://ai_states/[fsm_name]/[fsm_name]_graph.json`
- Auto-save on exit - Graph automatically saves when closing Godot
- Auto-load on startup - Graph automatically loads when opening the plugin
- Manual save/load buttons now fully functional

### ✨ New Features

#### Auto-Recovery System
- **NEW**: 🔍 Auto-recovery from generated code files
- Automatically detects and recovers FSM if graph JSON is missing
- Scans `res://ai_states/` folder for generated FSM files
- Reconstructs visual graph from code files:
  - Extracts state names, code blocks, and animations
  - Rebuilds transitions and connections
  - Recovers FSM configuration (base class, script name)
- Good for:
  - Addon reinstallation scenarios
  - Lost or deleted graph JSON files
  - Version control workflows (graph JSON in .gitignore)
  - Team collaboration (share code, auto-recover graph)
  - Project migration between machines
- Auto-arranges recovered nodes in clean grid layout
- Automatically saves recovered graph for future use

#### Two-way Sync System
- **NEW**: 🔄 "Sync from Files" button - Import code changes from generated files back to visual editor
- Edit generated `.gd` files in your IDE and sync changes back to visual nodes
- Keeps workflow flexibility - edit in visual editor OR code editor
- Smart code extraction from `enter()`, `update()`, and `exit()` functions
- Auto-sync on startup - Automatically syncs from files when loading graph
- Confirmation dialog prevents accidental overwrites
- Detailed sync report shows success/failure for each state


#### Smart Merge Generation
- **NEW**: Custom code preservation during regeneration
- Add helper functions to generated files - they're preserved on regenerate
- Add custom properties (var, @export, @onready) - they're preserved
- Only `enter()`, `update()`, `exit()` functions are regenerated
- Standard functions (`get_state_name()`, `get_transitions()`) are regenerated
- Custom functions automatically detected and preserved at end of file
- Custom properties automatically detected and preserved after class declaration
- Clear header comments indicate what's safe to edit vs what's regenerated
- No more lost code when regenerating!

### 🔧 Changes

#### Updated File Headers
- Generated state files now have clear documentation headers
- Indicates which sections are safe to edit
- Shows what gets regenerated on save
- Helps prevent accidental edits to auto-generated sections

#### Enhanced Console Output
- Better logging for save/load operations
- Sync operations show detailed progress
- Recovery process shows step-by-step progress
- Clear success/failure messages
- Helpful debugging information

### 📚 Documentation

#### Updated Documentation
- README.md updated with new features
- Workflow examples updated
- Best practices added

### 🎯 Impact

These updates transform the workflow from:
```
❌ OLD: Visual Editor → Generate → Lost on close → Start over
```

To:
```
✅ NEW: Visual Editor ⟷ Generated Files ⟷ Persistent Storage
         Edit anywhere, sync everywhere, never lose work!
         Even if graph is deleted, auto-recover from code files!
```

### 🔄 Migration Notes

- Existing projects will automatically benefit from persistence
- No action required - features work transparently
- First regeneration will enable smart merge for existing files
- Auto-recovery triggers automatically if graph JSON is missing
- Recommended: Commit your project to Git before updating

### 🚀 Recovery Scenarios

The auto-recovery system handles these scenarios automatically:

1. **Addon Reinstallation**: Delete addon → Reinstall → Auto-recovers from files ✓
2. **Lost Graph JSON**: graph.json deleted → Opens addon → Reconstructs from code ✓
3. **Version Control**: Clone project → graph.json in .gitignore → Auto-recovers ✓
4. **Team Collaboration**: Receive code files → Open addon → Graph reconstructed ✓
5. **Project Migration**: Copy ai_states folder → Open addon → Full recovery ✓

---

## [1.0.0] - 2026-05-09

### 🎉 Initial Release

First public release of OmniState Visual AI - Visual state machine editor for Godot 4.x!

### ✨ Features

#### Visual Editor
- **GraphEdit-based canvas** - Intuitive node-based workflow
- **Drag-and-drop states** - Easy state placement and organization
- **Visual connections** - Draw transition arrows between states
- **Resizable nodes** - Adjust node size to fit content
- **Color-coded ports** - Blue connection points for clarity
- **Delete options** - Close button (×), Delete key, or right-click menu
- **Context menus** - Right-click for quick actions

#### State Nodes
- **4-tab interface** - Basic, Enter, Update, Exit tabs
- **Animation dropdown** - Auto-populated from enemy scene
- **Syntax highlighting** - GDScript code coloring
- **Initial state marker** - Checkbox to mark starting state
- **Color picker** - Customize node colors
- **Behavior system** - Add custom behavior functions

#### Transition System
- **4-tab editor**:
  - **Conditions Tab** - 3 modes (Simple, AND, OR) + 9 quick presets
  - **Priority & Timing Tab** - Priority (0-100), Cooldowns (0.1-60s), Delays (0.1-10s)
  - **Advanced Tab** - Interrupt control, Animation blending (0-2s), Custom code
  - **Debug Tab** - Debug logging, Custom labels, Color picker

- **9 Quick Presets**:
  1. Player Detected
  2. In Range
  3. Health Low
  4. Can See Player
  5. Ammo Empty
  6. Timer Elapsed
  7. Is Covering
  8. Enemy Nearby
  9. Path Clear

- **Cooldown System** - Prevent rapid state switching (0.1-60s)
- **Delay System** - Add deliberate transition delays (0.1-10s)
- **Interrupt Control** - Protect animations that must complete
- **Animation Blending** - Smooth transitions (0-2s)
- **Custom Code** - Execute GDScript on transitions
- **Debug Logging** - Per-transition logging with colors
- **Syntax Highlighting** - Code editors

#### Blackboard System
- **Visual editor** - Manage variables through UI (📊 button)
- **Type support** - bool, int, float, String, Vector3
- **Default values** - Set initial values
- **Helper functions** - bb_set(), bb_get(), bb_has()
- **Unlimited variables** - No restrictions

#### Code Generation
- **Clean structure** - Organized output
- **Type hints** - Full type annotations
- **Error handling** - Warnings and error messages
- **Helper functions** - Utility methods included
- **Transition logic** - Cooldowns, delays, blending
- **Debug integration** - Logging code generation

#### State Templates
Pre-built behaviors for faster development:
1. **Idle** - Waiting and looking around
2. **Patrol** - Following waypoints
3. **Chase** - Pursuing player
4. **Attack** - Combat behavior
5. **Cover** - Tactical positioning
6. **Flee** - Escape and retreat

#### Animation Integration
- **Auto-detection** - Scan enemy scene for animations
- **Dropdown selection** - Choose per state
- **Flexible paths** - Any AnimationPlayer location
- **Automatic playback** - Plays on state enter
- **Blend support** - Smooth animation transitions

#### Setup Wizard
- **Configuration dialog** - One-time setup
- **Base class selection** - CharacterBody3D, CharacterBody2D, Node3D, Node2D, Node
- **Scene paths** - Link enemy and player scenes
- **AnimationPlayer path** - Specify location
- **Animation detection** - 🔍 Auto-detect all animations

#### Validation System
- **State count** - Verify states exist
- **Initial state check** - Ensure one marked
- **Connection validation** - Check for disconnected states
- **Name validation** - Detect unnamed/duplicate states
- **Transition validation** - Verify targets exist
- **Comprehensive reporting** - Detailed error messages

### 📚 Documentation
- **README.md** - Complete documentation (1200+ lines)
- **QUICKSTART.md** - 5-minute getting started guide
- **EXAMPLES.md** - Multiple complete example state machines
- **BLACKBOARD_GUIDE.md** - Complete Blackboard tutorial
- **QUICK_START_BLACKBOARD.md** - 5-minute Blackboard guide
- **TRANSITION_SYSTEM.md** - Advanced transition system guide
- **CHANGELOG.md** - This file

### 🎯 Quality
- **AAA game engine level** - Matches Unreal Engine 5/6 quality
- **Professional code** - Type hints, error handling, clean structure
- **Production-ready** - Tested and working
- **Performant** - Minimal overhead
- **Scalable** - Works with large state machines

### 🎮 Use Cases
- FPS enemy AI (patrol, chase, attack, cover)
- Boss battles with phase transitions
- Stealth game guards
- NPC behaviors
- Racing AI
- RTS units
- Puzzle game AI
- Sports game AI

### 📄 License
- **MIT License** - Free for commercial use

---

## Future Releases

See [README.md](README.md) for the roadmap and planned features.

---

**Legend:**
- ✨ Features - New features
- 🐛 Bug Fixes - Bug fixes
- 🔧 Changes - Changes to existing features
- 🗑️ Removed - Removed features
- 📚 Documentation - Documentation updates
- ⚡ Performance - Performance improvements
