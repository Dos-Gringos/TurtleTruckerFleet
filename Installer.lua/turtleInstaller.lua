-- wipe old files
if fs.exists("nav") then fs.delete("nav") end
if fs.exists("pathfinding.lua") then fs.delete("pathfinding.lua") end

-- make new nav dir
fs.makeDir("nav")

-- download nav files
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_fuel.lua nav/fuel.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_move.lua nav/move.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_state.lua nav/state.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/init.lua nav/init.lua")
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/detect_direction.lua nav/detect_direction.lua")

-- download pathfinding
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet//main/turtle_fleet/pathfinding.lua pathfinding")

print("Install complete.")
