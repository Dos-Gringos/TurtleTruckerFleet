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

  local home = state.getHome()
  if not home then
    print("[TURTLE] Error: No home position set!")
    return false
  end

  print("[TURTLE] Moving to home at: " .. home.x .. ", " .. home.y .. ", " .. home.z)
  nav.moveTo(home)

  if nav.atHome() then
    print("[TURTLE] Successfully returned home.")
    return true
  else
    print("[TURTLE] Failed to reach home.")
    return false
  end
end

return goHome
