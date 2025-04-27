local nav = require("nav")

print("=== NAV DIAGNOSTIC ===")

-- display current state
local pos = nav.getPos()
print(string.format("Current Position: %d %d %d", pos.x, pos.y, pos.z))
print(string.format("Home Position: %d %d %d", nav.home.x, nav.home.y, nav.home.z))
print(string.format("Fuel Level: %d", turtle.getFuelLevel()))

-- manual move test
print("Enter destination X Y Z:")
local input = read()
local x, y, z = input:match("(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)")
local dest = vector.new(tonumber(x), tonumber(y), tonumber(z))

print("Moving to destination...")
nav.moveTo(dest)
print("Arrived at destination.")

-- state re-check
pos = nav.getPos()
print(string.format("Updated Position: %d %d %d", pos.x, pos.y, pos.z))

-- fuel test
print("Fuel Level: " .. turtle.getFuelLevel())
if not nav.checkFuel() then
  print("Low fuel detected. Attempting refuel at home.")
  if nav.atHome() then
    nav.refuelIfNeeded()
    print("Post-refuel Fuel Level: " .. turtle.getFuelLevel())
  else
    print("Not at home. Triggering emergencyReturn.")
    if nav.emergencyReturn() then
      print("Returned to base and refueled.")
    else
      print("No emergency action needed.")
    end
  end
else
  print("Fuel sufficient, no refuel needed.")
end

-- persistence test
print("Now reboot the turtle and re-run this script.")
