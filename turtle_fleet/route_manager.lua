-- route_manager.lua (polling mode + individual routes)
-- central route assignment + dashboard with persistent route cycling and per-turtle route mapping

rednet.open("right") -- adjust as needed

local route_dir = "routes"
local assigned = {}
local turtles = {}
local route_queue = {} -- FIFO queue of route filenames
local persistent_routes = {}

-- map specific turtles to specific routes
local routeMap = {
  miner1 = "mine_loop.txt",
  hauler2 = "depot_run.txt",
  -- add more label = route mappings here
}

-- === load route names from /routes folder ===
for _, file in ipairs(fs.list(route_dir)) do
  persistent_routes[file] = true
  table.insert(route_queue, file)
end

print("Route Manager Server Started\n")

while true do
  local id, msg, proto = rednet.receive()

  if type(msg) == "string" and msg == "turtle_hello" then
    rednet.send(id, "server_ack")
  end

  if type(msg) == "string" and msg == "dashboard_hello" then
    rednet.send(id, "server_ready")
  end  

  if type(msg) == "string" and msg == "dashboard_request" then
    rednet.send(id, {
      turtles = turtles,
      assigned = assigned,
      queueLength = #route_queue
    }, "dashboard_update")
  end

  if type(msg) == "table" and msg.label then
    turtles[id] = turtles[id] or {}
    for k, v in pairs(msg) do
      turtles[id][k] = v
    end
    turtles[id].lastSeen = os.clock()

    turtles[id].history = turtles[id].history or {}
    table.insert(turtles[id].history, {
      status = msg.status,
      time = os.clock()
    })

    if msg.status == "idle" and not assigned[id] then
      local routeName = routeMap[turtles[id].label]
      if not routeName and #route_queue > 0 then
        routeName = table.remove(route_queue, 1)
      end

      if routeName then
        turtles[id].route = routeName
        assigned[id] = routeName

        -- send route file contents
        local routePath = route_dir .. "/" .. routeName
        if not fs.exists(routePath) then
          print("Route file not found: " .. routePath)
        else
          local f = fs.open(routePath, "r")
          local lines = {}
          while true do
            local line = f.readLine()
            if not line then break end
            table.insert(lines, line)
          end
          f.close()
        
          local deliveryQuantity = nil

          -- set quantity if this is a delivery route
          if routeName:find("delivery") then -- crude tag detection
            deliveryQuantity = 129 -- or whatever default you want
          end
          
          rednet.send(id, {
            route = routeName,
            waypoints = lines,
            quantityRequested = deliveryQuantity
          }, "route_assign")
          
        
          print("Assigned route " .. routeName .. " to turtle " .. msg.label)
        end
        

        rednet.send(id, {
          route = routeName,
          waypoints = lines
        }, "route_assign")

        print("Assigned route " .. routeName .. " to turtle " .. msg.label)
      end
    end

    if msg.status == "complete" then
      assigned[id] = nil
      print("Turtle " .. msg.label .. " completed its route.")
      local finishedRoute = turtles[id].route
      -- re-add the route back to the queue if not a mapped route
      if finishedRoute and persistent_routes[finishedRoute] and not routeMap[turtles[id].label] then
        table.insert(route_queue, finishedRoute)
      end
    end
  end

  -- check for new routes in route_dir
  for _, file in ipairs(fs.list(route_dir)) do
    if not persistent_routes[file] then
      persistent_routes[file] = true
      table.insert(route_queue, file)
      print("New route detected and queued: " .. file)
    end
  end

  -- refresh simple terminal dashboard
  term.clear()
  term.setCursorPos(1, 1)
  print("TURTLE STATUS:")
  for id, data in pairs(turtles) do
    local tag = assigned[id] and ("running " .. assigned[id]) or data.status
    print(string.format("[%d] %s | fuel: %d | %s", id, data.label, data.fuel or 0, tag))
  end
  print("\nRoutes remaining in queue: " .. #route_queue)
end
