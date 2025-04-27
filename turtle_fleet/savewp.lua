-- savewp.lua
-- saves the turtle's current position to waypoints.txt with a user-defined name

-- === input ===
if not ... then
    print("usage: savewp <name>")
    return
  end
  
  local name = ...
  local posFile = "nav_pos.txt"
  local wpFile = "waypoints.txt"
  
  -- === get current position from nav_pos.txt ===
  if not fs.exists(posFile) then
    print("error: no nav_pos.txt found (run patrol/nav first?)")
    return
  end
  
  local f = fs.open(posFile, "r")
  local x, y, z = gps.locate()
    if not x then
      print("GPS failed, unable to set waypoint")
      return
    end
  f.close()
  
  -- === append to waypoints.txt ===
  local out = fs.open(wpFile, "a")
  out.writeLine(string.format("%s %d %d %d", name, x, y, z))
  out.close()
  
  print(string.format("waypoint '%s' saved at %d %d %d", name, x, y, z))
  