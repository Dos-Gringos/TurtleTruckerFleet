-- nav/fuel.lua
local move = require("nav/move")
local state = require("nav/state")

-- === fuel check ===
local function checkFuel()
  return turtle.getFuelLevel() >= 20
end

-- === refuel at home ===
local function refuelIfNeeded()
  if state.getPos():equals(state.getHome()) and not checkFuel() then
    turtle.select(1)
    turtle.suck()
    turtle.refuel()
  end
end

-- === emergency return ===
local function emergencyReturn()
  if turtle.getFuelLevel() < 10 and not state.getPos():equals(state.getHome()) then
    print("EMERGENCY: returning to base")
    move.moveTo(state.getHome())
    turtle.select(1)
    turtle.suck()
    turtle.refuel()
    if turtle.getFuelLevel() < 10 then
      error("CRITICAL: refueling failed")
    end
    return true
  end
  return false
end

return {
  checkFuel = checkFuel,
  refuelIfNeeded = refuelIfNeeded,
  emergencyReturn = emergencyReturn
}
