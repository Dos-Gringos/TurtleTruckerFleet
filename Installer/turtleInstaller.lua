-- wipe old files
if fs.exists("nav") then fs.delete("nav") end
print("nav/ deleted")
if fs.exists("pathfinding.lua") then fs.delete("pathfinding.lua") end
print("pathfinding deleted")
if not fs.exists("waypoints.txt") then
    local f = fs.open("waypoints.txt", "w")
    f.close()
  end
  
-- make new nav dir
fs.makeDir("nav")

-- download nav files
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_fuel.lua nav/fuel.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_move.lua nav/move.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/nav_state.lua nav/state.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/main/turtle_fleet/nav/init.lua nav/init.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/nav/detect_direction.lua nav/detect_direction.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/savewp.lua savewp")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/nav/home_return.lua nav/home_return.lua")
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet/refs/heads/main/turtle_fleet/nav/idle_watch.lua nav/dle_watch.lua")

-- download pathfinding
shell.run("wget https://raw.githubusercontent.com/Dos-Gringos/TurtleTruckerFleet//main/turtle_fleet/pathfinding.lua pathfinding.lua")

print("Install complete.")
