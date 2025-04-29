-- === TURTLE SIDE ===
-- dynamic_patrol.lua
-- turtle behavior to fetch and run assigned route from server

local nav = require("nav")
local goHome = require("nav/home_return")
local idleWatch = require("nav/idle_watch")

rednet.open("right") -- adjust to your modem side
shell.run("sync_waypoints.lua")

-- === internal helpers ===

local function loadWaypoints()
  local wp = {}
  if not fs.exists("waypoints.txt") then
    error("[WAYPOINTS] waypoints.txt not found")
  end

  local f = fs.open("waypoints.txt", "r")
  while true do
    local line = f.readLine()
    if not line then break end
    line = line:match("^%s*(.-)%s*$")
    local name, x, y, z = line:match("^(%S+)%s*(-?%d+)%s*(-?%d+)%s*(-?%d+)$")
    if name and x and y and z then
      wp[name] = vector.new(tonumber(x), tonumber(y), tonumber(z))
    else
      error("[WAYPOINTS] Malformed line: '" .. line .. "'")
    end
  end
  f.close()
  return wp
end

local function sendStatus(status, extra)
  local msg = {
    id = os.getComputerID(),
    label = os.getComputerLabel() or "unnamed",
    status = status,
    fuel = turtle.getFuelLevel(),
    pos = nav.getPos()
  }
  if extra then
    for k, v in pairs(extra) do
      msg[k] = v
    end
  end
  rednet.broadcast(msg, "turtle_status")
end

local function pickupItems()
  for slot = 2, 16 do
    turtle.select(slot)
    turtle.suck()
  end
  turtle.select(1) -- reselect fuel slot
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

-- === delivery runner ===
local function runDelivery(path, pickupIdx, dropoffIdx, quantityRequested)
  local remaining = quantityRequested

  while remaining > 0 do
    -- go to pickup
    for i = 1, pickupIdx do
      sendStatus("moving", {current = i, total = #path, direction = "to_pickup", waypoint = path[i]})
      if nav.emergencyReturn() then return false end
      nav.moveTo(path[i])
      idleWatch.resetTimer()
      sleep(0.2)
    end

    -- pickup
    pickupItems()
    local pickedUp = countCargo()
    sendStatus("picked_up", {picked = pickedUp})

    -- go to dropoff
    for i = pickupIdx + 1, dropoffIdx do
      sendStatus("moving", {current = i, total = #path, direction = "to_dropoff", waypoint = path[i]})
      if nav.emergencyReturn() then return false end
      nav.moveTo(path[i])
      idleWatch.resetTimer()
      sleep(0.2)
    end

    -- drop
    dropItems()
    sendStatus("dropped_off", {dropped = pickedUp})

    remaining = remaining - pickedUp
    if remaining < 0 then remaining = 0 end

    -- go home
    if not nav.atHome() then
      goHome()
    end

    idleWatch.checkIdle()
    sleep(1) -- chill briefly before new loop
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
      print("Received route: " .. (msg.route or "unknown"))
      local waypoints = loadWaypoints()

      -- parse waypoint names to vectors
      local path = {}
      for _, name in ipairs(msg.waypoints) do
        local vec = waypoints[name]
        if vec and type(vec) == "table" and vec.x and vec.y and vec.z then
          table.insert(path, vec)
        else
          error("[WAYPOINT ERROR] '" .. name .. "' is missing or not a valid vector!")
        end
      end

      local success = false

      if msg.quantityRequested then
        -- delivery mode
        local pickupIdx = 1
        local dropoffIdx = #path
        success = runDelivery(path, pickupIdx, dropoffIdx, msg.quantityRequested)
      else
        -- patrol mode (legacy)
        for i = 1, #path do
          sendStatus("moving", {current = i, total = #path, direction = "patrol", waypoint = path[i]})
          if nav.emergencyReturn() then break end
          nav.moveTo(path[i])
          idleWatch.resetTimer()
          sleep(0.2)
        end
        if not nav.atHome() then
          goHome()
        end
        success = true
      end

      sendStatus(success and "complete" or "aborted")
      print("Route " .. (success and "complete" or "aborted due to emergency."))

    end
  end
  sleep(2)
end
