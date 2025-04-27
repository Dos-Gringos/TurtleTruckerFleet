# Turtle Fleet Automation

A Computercraft-powered logistics automation system for Minecraft turtles, designed like a modular Factorio train system.

## Overview
This setup allows turtles to operate in a fleet, running predefined routes between waypoints, returning home to refuel, and repeating. Includes a central route manager, per-turtle route assignment, and a dashboard interface.

## Features
- Modular navigation system (nav/)
- Central route assignment server (route_manager.lua)
- Touchscreen dashboard (route_dashboard.lua)
- Per-turtle route configuration
- Reverse route automation
- Refuel at home after route completion

## File Structure
```
/turtle-fleet/
├── nav/
│   ├── fuel.lua         # Fuel logic and emergency return
│   ├── move.lua         # Axis-based movement and facing
│   ├── state.lua        # Persistent position/direction tracking
│   └── init.lua         # Entry point for nav functions
├── pathfinding.lua      # Turtle-side route execution
├── route_manager.lua    # Server-side route assignment and management
├── route_dashboard.lua  # Monitor UI for tracking turtles and routes
├── savewp.lua           # Save current position as named waypoint
├── routes/
│   ├── mine_loop.txt    # Example route: list of waypoint names
│   └── depot_run.txt
```

## Setup Instructions
1. **Install Computercraft: Tweaked**
2. **Deploy Files:**
   - Upload all files to your turtle and server computers.
   - Keep nav/ folder intact.
3. **Set Turtle Labels:**
   ```
   label set miner1
   ```
4. **Configure routeMap in route_manager.lua:**
   ```lua
   local routeMap = {
     miner1 = "mine_loop.txt",
     hauler2 = "depot_run.txt"
   }
   ```
5. **Create routes/**
   - Add .txt files with waypoint names, one per line.
6. **Run Order:**
   - Start `route_manager.lua`
   - Start turtles with `pathfinding.lua`
   - Start `route_dashboard.lua`

## Dependencies
- Computercraft: Tweaked
- GPS (for waypoint saving, optional if using manual nav)

## TODO
- Manual dispatch override
- Persistent state saving

## Author
- [Dos Gringos]
