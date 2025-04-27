-- wipe old files
if fs.exists("nav") then fs.delete("nav") end
if fs.exists("pathfinding.lua") then fs.delete("pathfinding.lua") end

-- make new nav dir
fs.makeDir("nav")

-- download nav files
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/fuel.lua nav/fuel.lua")
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/move.lua nav/move.lua")
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/state.lua nav/state.lua")
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/init.lua nav/init.lua")
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/nav/detect_direction.lua nav/detect_direction.lua")

-- download pathfinding
shell.run("wget https://raw.githubusercontent.com/YOU/turtle-fleet/main/pathfinding.lua pathfinding.lua")

print("Install complete.")
