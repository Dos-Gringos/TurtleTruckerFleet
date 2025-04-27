-- route_dashboard.lua
-- touchscreen UI for route_manager status and turtle controls (polling mode)

rednet.open("right") -- adjust if needed

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
monitor.clear()

local turtles = {}
local assigned = {}
local queueLength = 0

-- track button positions for later interaction
local buttons = {}

-- wait for server ready
local function waitForServer()
  monitor.clear()
  monitor.setCursorPos(1, 1)
  monitor.write("Waiting for route manager...")

  while true do
    rednet.broadcast("dashboard_hello")
    local id, msg = rednet.receive(2)
    if msg == "server_ready" then
      monitor.clear()
      monitor.setCursorPos(1, 1)
      monitor.write("Connected to route manager.")
      sleep(1)
      break
    end
    sleep(2)
  end
end

waitForServer()

-- draw initial UI
local function drawUI()
  monitor.clear()
  monitor.setCursorPos(1, 1)
  monitor.write("ROUTE MANAGER STATUS")

  monitor.setCursorPos(1, 3)
  monitor.write("Routes in queue: " .. queueLength)

  monitor.setCursorPos(1, 5)
  monitor.write("Turtles:")

  local col1 = 1
  local col2 = 20
  local row = 7
  local count = 0
  buttons = {}

  for id, data in pairs(turtles) do
    local label = string.format("[%d] %s", id, data.label)
    local posX = count % 2 == 0 and col1 or col2
    monitor.setCursorPos(posX, row)
    monitor.write(label)

    table.insert(buttons, {
      id = id,
      label = label,
      x = posX,
      y = row,
      w = #label,
      h = 1
    })

    if count % 2 == 1 then
      row = row + 2
    end
    count = count + 1
  end

  monitor.setCursorPos(1, row + 2)
  monitor.write("Tap turtle for details")
end

-- handle touch event
local function handleTouch(x, y)
  for _, btn in ipairs(buttons) do
    if x >= btn.x and x <= btn.x + btn.w and y == btn.y then
      print("Touched: " .. btn.label)
      -- future: show route info, allow actions
    end
  end
end

-- listen for monitor touches
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.write("Polling route manager...")

while true do
  -- poll route manager
  rednet.broadcast("dashboard_request")
  local id, msg = rednet.receive("dashboard_update", 1)
  if msg then
    turtles = msg.turtles or {}
    assigned = msg.assigned or {}
    queueLength = msg.queueLength or 0
    drawUI()
  end

  -- handle touch
  local event, side, x, y = os.pullEvent("monitor_touch")
  handleTouch(x, y)
end
