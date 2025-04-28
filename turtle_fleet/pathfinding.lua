-- === TURTLE SIDE ===
-- dynamic_patrol.lua
-- turtle behavior to fetch and run assigned route from server

local nav = require("nav")
local goHome = require("nav/home_return")
local idleWatch = require("nav/idle_watch")

rednet.open("right") -- adjust to your modem side
shell.run("sync_waypoints.lua")

local function loadWaypoints(path)
  local wp = {}
  if not fs.exists(path) then error("waypoints.txt missing") end
  local f = fs.open(path, "r")
  while true do
    local line = f.readLine()
    if not line then break end
    local name, x, y, z = line:match("(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)")
    if name and x and y and z then
      wp[name] = vector.new(tonumber(x), tonumber(y), tonumber(z))
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
    end

    rednet.broadcast(msg, "turtle_status")

  end  



 -- ===PATROL RUNNER===
local function runPath(path)
    --forward
    for i = 1, #path do
        sendStatus("moving", {current = i, total = #path, direction = "forward", waypoint = path[i]})
        if nav.emergencyReturn() then return false end
        nav.moveTo(path[i])
        idleWatch.resetTimer()
        sleep(0.2)
    end

    --reverse
    for i = #path - 1, 1, -1 do
      sendStatus("moving", {current = i, total = #path, direction = "return", waypoint = path[i]})
      if nav.emergencyReturn() then return false end
      nav.moveTo(path[i])
      idleWatch.resetTimer()
      sleep(0.2)
    end    
    -- reverse trip back home
    for i = #path - 1, 1, -1 do
      local wpName = path[i]
      local targetPos = waypoints[wpName]
      if targetPos then
        sendStatus("moving", {current = i, total = #path, direction = "return", waypoint = wpName})
        if nav.emergencyReturn() then return false end
        nav.moveTo(targetPos)
        idleWatch.resetTimer()
        sleep(0.2)
      end
    end
    -- once back at starting point
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
      print("Received route: " .. (msg.route or "unknown"))
      local waypoints = loadWaypoints("waypoints.txt")

      -- parse waypoint names to vectors
      local path = {}
      for _, name in ipairs(msg.waypoints) do
        if waypoints[name] then
          table.insert(path, waypoints[name])
        else
          error("waypoint not found: " .. name)
        end
      end

      local success = runPath(path)

      -- refuel if at home and needed
      if nav.atHome() and not nav.checkFuel() then
        turtle.select(1)
        turtle.suck()
        turtle.refuel()
      end

      idleWatch.checkIdle()

      sendStatus(success and "complete" or "aborted")
      print("Route " .. (success and "complete" or "aborted due to emergency."))

      if goHome() then
        print("Turtle: " .. os.getComputerLabel() .. " returning home")
      end
    end
  end
  sleep(2)
end
