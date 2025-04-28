-- wipe old files
if fs.exists("nav") then fs.delete("nav") end
print("nav/ deleted")
sleep(1)
if fs.exists("pathfinding.lua") then fs.delete("pathfinding.lua") end
print("pathfinding deleted")
sleep(1)
if fs.exists("waypoints.txt") then fs.open("waypoints.txt") end

-- make new nav dir
fs.makeDir("nav")

-- download nav files
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_fuel.lua nav/fuel.lua")
sleep(1)
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_move.lua nav/move.lua")
sleep(1)
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_state.lua nav/state.lua")
sleep(1)
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/init.lua nav/init.lua")
sleep(1)
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/nav/detect_direction.lua nav/detect_direction.lua")
sleep(1)
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/savewp.lua savewp")
sleep(1)

-- download pathfinding
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet//main/turtle_fleet/pathfinding.lua pathfinding.lua")
sleep(1)

print("Install complete.")
