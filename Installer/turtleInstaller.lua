-- wipe old files
if fs.exists("nav") then fs.delete("nav") end
if fs.exists("pathfinding.lua") then fs.delete("pathfinding.lua") end

-- make new nav dir
fs.makeDir("nav")

-- download nav files
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_fuel.lua nav/fuel")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_move.lua nav/move")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_state.lua nav/state")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/init.lua nav/init")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/nav/detect_direction.lua nav/detect_direction")

-- download pathfinding
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet//main/turtle_fleet/pathfinding.lua pathfinding")

print("Install complete.")
