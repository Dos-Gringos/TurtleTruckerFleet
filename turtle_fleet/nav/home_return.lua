-- home_return.lua
-- turtle 'go home' behavior using nav

local nav = require("nav")
local state = require("nav/state")

local function goHome()
  print("[TURTLE] Initiating return to home...")

  if nav.atHome() then
    print("[TURTLE] Already at home.")
    return true
  end

  if not nav.checkFuel(50) then -- ensure we have enough fuel margin
    print("[TURTLE] Warning: low fuel before homing!")
    if not nav.refuelIfNeeded() then
      print("[TURTLE] Critical: unable to refuel before homing!")
      return false
    end
  end

  local pads = state.listHomePads()
  if #pads == 0 then
    print("[TURTLE] Error: No home pads available!")
    return false
  end

  -- pick random pad to target
  local targetPad = pads[math.random(#pads)]

  print(string.format("[TURTLE] Moving to home pad at: %d %d %d", targetPad.x, targetPad.y, targetPad.z))
  nav.moveTo(targetPad)

  -- re-check
  local pos = nav.getPos()
  for _, pad in ipairs(pads) do
    if pos:equals(pad) then
      print("[TURTLE] Successfully returned to a home pad.")
      return true
    end
  end

  print("[TURTLE] Failed to reach any home pad.")
  return false
end

return goHome
