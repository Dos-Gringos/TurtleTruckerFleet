-- === TURTLE SIDE ===
-- dynamic_patrol.lua
-- turtle behavior to fetch and run assigned route from server

print("PWD:", shell.dir())
print("FILES:", textutils.serialize(fs.list(".")))
print("NAV FILES:", textutils.serialize(fs.list("nav")))
sleep(5)

local nav = require("nav")
local goHome = require("nav/home_return")
local idleWatch = require("nav/idle_watch")

rednet.open("right") -- adjust to your modem side
shell.run("sync_waypoints.lua")

local function loadWaypoints()
  local wp = {}
  if not fs.exists("waypoints.txt") then
    error("[WAYPOINTS] waypoints.txt not found")
  end

  local f = fs.open("waypoints.txt", "r")
  while true do
    local line = f.readLine()
    if not line then break end

    -- trim leading/trailing whitespace
    line = line:match("^%s*(.-)%s*$")

    -- parse
    local name, x, y, z = line:match("^(%S+)%s*(-?%d+)%s*(-?%d+)%s*(-?%d+)$")
    if name and x and y and z then
      wp[name] = vector.new(tonumber(x), tonumber(y), tonumber(z))
      print("[WAYPOINT LOADED]", name, x, y, z)
    else
      error("[WAYPOINTS] Malformed line: '" .. line .. "'")
    end
  end
  f.close()
  return wp
end

local function sendStatus(status, pathInfo)
  local msg = {
    id = os.getComputerID(),
    label = os.getComputerLabel() or "unnamed",
    status = status,
    fuel = turtle.getFuelLevel(),
    pos = nav.getPos()
  }
  if pathInfo then
    msg.current = pathInfo.current
    msg.total = pathInfo.total
    msg.direction = pathInfo.direction
    msg.waypoint = pathInfo.waypoint
    msg.extra = pathInfo.extra
  end
  rednet.broadcast(msg, "turtle_status")
end

local function findChest()
  for i = 1, 4 do
    local success, data = turtle.inspect()
    if success and data.name and data.name:lower():find("chest") then
      print("[CHEST DETECTED] Facing chest.")
      return true
    end
    turtle.turnRight()
  end
  print("[CHEST NOT FOUND] No chest adjacent.")
  return false
end

local function pickupItems()
  for slot = 2, 16 do
    turtle.select(slot)
    turtle.suck()
  end
  turtle.select(1)
end

local function dropItems()
  for slot = 2, 16 do
    turtle.select(slot)
    turtle.drop()
  end
  turtle.select(1)
end

local function countCargo()
  local count = 0
  for slot = 2, 16 do
    count = count + turtle.getItemCount(slot)
  end
  return count
end

-- === DELIVERY RUNNER ===
local function runDelivery(path, pickupIdx, dropoffIdx, quantityRequested)
  local remaining = quantityRequested
  print("[DELIVERY] Starting delivery loop. Total requested:", remaining)

  while remaining > 0 do
    -- travel to pickup point
    local pickupPos = path[pickupIdx]
    print(string.format("[DELIVERY] Moving to pickup waypoint %d: %d %d %d", pickupIdx, pickupPos.x, pickupPos.y, pickupPos.z))
    sendStatus("moving", {current = pickupIdx, total = #path, direction = "to_pickup", waypoint = pickupPos})
    if nav.emergencyReturn() then return false end
    nav.moveTo(pickupPos)
    idleWatch.resetTimer()
    sleep(0.2)

    -- verify chest and pickup
    if not findChest() then
      print("[ERROR] No chest found for pickup/dropoff!")
      return false
    end
    print("[DELIVERY] At pickup. Attempting to load cargo...")
    pickupItems()
    local pickedUp = countCargo()
    print("[DELIVERY] Picked up", pickedUp, "items.")

    sendStatus("picked_up", {extra = pickedUp})

    -- travel to dropoff point
    local dropoffPos = path[dropoffIdx]
    print(string.format("[DELIVERY] Moving to dropoff waypoint %d: %d %d %d", dropoffIdx, dropoffPos.x, dropoffPos.y, dropoffPos.z))
    sendStatus("moving", {current = dropoffIdx, total = #path, direction = "to_dropoff", waypoint = dropoffPos})
    if nav.emergencyReturn() then return false end
    nav.moveTo(dropoffPos)
    idleWatch.resetTimer()
    sleep(0.2)

    -- verify chest and drop
    if not findChest() then
      print("[ERROR] No chest found for pickup/dropoff!")
      return false
    end
    print("[DELIVERY] At dropoff. Dropping cargo...")
    dropItems()
    sendStatus("dropped_off", {extra = pickedUp})

    remaining = remaining - pickedUp
    if remaining < 0 then remaining = 0 end

    print("[DELIVERY] Remaining items to deliver:", remaining)

    -- return home if needed
    if not nav.atHome() then
      goHome()
    end

    idleWatch.checkIdle()
    sleep(1)
  end

  return true
end

-- === PATROL RUNNER ===
local function runPath(path)
  -- forward
  for i = 1, #path do
    sendStatus("moving", {current = i, total = #path, direction = "forward", waypoint = path[i]})
    if nav.emergencyReturn() then return false end
    nav.moveTo(path[i])
    idleWatch.resetTimer()
    sleep(0.2)
  end

  -- reverse trip back
  for i = #path - 1, 1, -1 do
    sendStatus("moving", {current = i, total = #path, direction = "return", waypoint = path[i]})
    if nav.emergencyReturn() then return false end
    nav.moveTo(path[i])
    idleWatch.resetTimer()
    sleep(0.2)
  end

  if not nav.atHome() then
    goHome()
  end

  return true
end

-- === MAIN LOOP ===
while true do
  if nav.atHome() then
    sendStatus("idle")
    print("Waiting for route assignment...")

    local id, msg, proto = rednet.receive("route_assign")
    if msg and msg.waypoints then
      print("Received route:", msg.route or "unknown")
      local waypoints = loadWaypoints()

      local path = {}
      for _, name in ipairs(msg.waypoints) do
        local vec = waypoints[name]
        if vec and type(vec) == "table" and vec.x and vec.y and vec.z then
          table.insert(path, vec)
        else
          error("[WAYPOINT ERROR] '" .. name .. "' is missing or not a valid vector!")
        end
      end

      if not findChest() then
        print("[ERROR] No chest found for pickup/dropoff!")
        return false
      end
      
      local success = false

      if msg.quantityRequested then
        print("[DELIVERY] Delivery mode detected. Quantity requested:", msg.quantityRequested)
        local pickupIdx = 1
        local dropoffIdx = #path
        success = runDelivery(path, pickupIdx, dropoffIdx, msg.quantityRequested)
      else
        print("[PATROL] Patrol mode detected.")
        success = runPath(path)
      end

      -- refuel if at home and needed
      if nav.atHome() and not nav.checkFuel() then
        turtle.select(1)
        turtle.suck()
        turtle.refuel()
      end

      idleWatch.checkIdle()

      sendStatus(success and "complete" or "aborted")
      print("Route", success and "complete" or "aborted due to emergency.")

      if goHome() then
        print("Turtle:", os.getComputerLabel(), "returning home")
      end
    end
  end
  sleep(2)
end
