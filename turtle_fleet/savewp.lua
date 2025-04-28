-- savewp.lua
-- saves turtle's current GPS or nav position to waypoints.txt with user-defined name

if not ... then
  print("usage: savewp <name>")
  return
end

local name = ...
local wpFile = "waypoints.txt"
local posFile = "nav_pos.txt"

local x, y, z

-- try GPS first
x, y, z = gps.locate(2)
if x then
  print("GPS located:", x, y, z)
else
  -- fallback to nav_pos.txt
  if not fs.exists(posFile) then
    print("error: no gps or nav_pos.txt found")
    return
  end
  local f = fs.open(posFile, "r")
  x = tonumber(f.readLine())
  y = tonumber(f.readLine())
  z = tonumber(f.readLine())
  f.close()
  print("Using nav_pos.txt position:", x, y, z)
end

-- append to waypoints
local out = fs.open(wpFile, "a")
out.writeLine(string.format("%s %d %d %d", name, x, y, z))
out.close()

print(string.format("waypoint '%s' saved at %d %d %d", name, x, y, z))
