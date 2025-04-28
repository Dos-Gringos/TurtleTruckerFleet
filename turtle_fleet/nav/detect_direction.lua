-- nav/detect_direction.lua

local state = require("nav/state")

local function detectDirection()
  local x1, y1, z1 = gps.locate(2)
  if not x1 then error("GPS failed to locate position") end

  if not turtle.forward() then error("Cannot move forward to detect direction") end

  local x2, y2, z2 = gps.locate(2)
  if not x2 then error("GPS failed to locate after moving") end

  local dx = x2 - x1
  local dz = z2 - z1

  -- move back to original position
  turtle.back()

  local dir
  if dx == 1 then dir = 1 -- east
  elseif dx == -1 then dir = 3 -- west
  elseif dz == 1 then dir = 2 -- south
  elseif dz == -1 then dir = 0 -- north
  else error("Unable to determine direction") end

  return vector.new(x1, y1, z1), dir
end

return detectDirection
