-- === TURTLE SIDE ===
-- dynamic_patrol.lua
-- turtle behavior to fetch and run assigned route from server

print("PWD:", shell.dir())
print("FILES:", textutils.serialize(fs.list(".")))
print("NAV FILES:", textutils.serialize(fs.list("nav")))
sleep(1)

local nav = require("nav")
local goHome = require("nav/home_return")
local idleWatch = require("nav/idle_watch")
local detectDirection = require("nav/detect_direction")
local state = require("nav/state")

rednet.open("right") -- adjust to your modem side
shell.run("sync_waypoints.lua")

local function returnFromWaypointToPad(padVec)
  local currentPos = nav.getPos()
  local dx = padVec.x - currentPos.x
  local dz = padVec.z - currentPos.z

  -- move up one to avoid chest collisions etc
  if turtle.up() then
    local elevated = vector.new(currentPos.x, currentPos.y + 1, currentPos.z)
    state.setPos(elevated) -- update internal state
  end

  -- face toward pad
  if math.abs(dx) > math.abs(dz) then
    nav.face(dx > 0 and 1 or 3)
  else
    nav.face(dz > 0 and 2 or 0)
  end

  nav.moveTo(padVec)
end

local function departFromPad(targetVec)
  local currentPos = nav.getPos()
  local dx = targetVec.x - currentPos.x
  local dz = targetVec.z - currentPos.z

  -- face toward the factory1home waypoint
  if math.abs(dx) > math.abs(dz) then
    nav.face(dx > 0 and 1 or 3) -- east/west
  else
    nav.face(dz > 0 and 2 or 0) -- south/north
  end

  nav.moveTo(targetVec)
end

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

-- === smarter delivery loop ===
local function runDelivery(path, quantityRequested)
  local remaining = quantityRequested
  print("[DELIVERY] Starting delivery. Target:", remaining)

  while remaining > 0 do
    for i = 1, #path do
      local waypoint = path[i]
      sendStatus("moving", {current = i, total = #path, direction = "forward", waypoint = waypoint})
      if nav.emergencyReturn() then return false end

      nav.moveTo(waypoint)
      idleWatch.resetTimer()
      sleep(0.2)

      local name = msg.waypoints[i]:lower()
      if name:find("pickup") then
        print("[DELIVERY] Reached pickup:", name)
        if not findChest() then print("[ERROR] No pickup chest."); return false end
        pickupItems()
        local picked = countCargo()
        remaining = remaining - picked
        print("[DELIVERY] Picked up", picked, "items. Remaining:", remaining)
        sendStatus("picked_up", {extra = picked})
      elseif name:find("dropoff") then
        print("[DELIVERY] Reached dropoff:", name)
        if not findChest() then print("[ERROR] No dropoff chest."); return false end
        dropItems()
        print("[DELIVERY] Dropped off cargo.")
        sendStatus("dropped_off")
      end
    end

    if not nav.atHome() then goHome() end
    idleWatch.checkIdle()
    sleep(1)
  end

  if nav.atHome() then
    print("[DEPARTURE] Detecting direction...")
    local pos, dir = detectDirection()
    local state = require("nav/state")
    state.setPos(pos)
    state.setDir(dir)
    print(string.format("[DIR DETECT] Facing %d (0=N,1=E,2=S,3=W)", dir))
  
    local pads = state.listHomePads()
    local pad = pads[math.random(#pads)] -- later you'll want smarter assignment
    print("[DEPARTURE] Moving from home pad to first waypoint.")
    departFromPad(path[1])
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

      if nav.atHome() then
        local pads = state.listHomePads()
        local pad = pads[math.random(#pads)] -- or smarter selection
        print("[DEPARTURE] Moving from home pad to depot start.")
        returnFromWaypointToPad(path[1]) -- move toward first waypoint (factory1home)
      end

      print("[DEPARTURE] Moving from home pad to depot start")
      departFromPad(path[1]) --move to the first waypoint

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
