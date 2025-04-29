-- nav/state.lua
local posFile = "nav_pos.txt"
local pos, dir
local homePads = {}

-- === save position + direction ===
local function saveState()
  local f = fs.open(posFile, "w")
  f.writeLine(pos.x)
  f.writeLine(pos.y)
  f.writeLine(pos.z)
  f.writeLine(dir)
  -- save home pads if any
  for _, pad in ipairs(homePads) do
    f.writeLine(pad.x)
    f.writeLine(pad.y)
    f.writeLine(pad.z)
  end
  f.close()
end

-- === load or initialize state ===
local function loadState()
  local x, y, z = gps.locate(2)
  if not x then
    error("gps failed, can't initialize position")
  end
  pos = vector.new(x, y, z)

  if fs.exists(posFile) then
    local f = fs.open(posFile, "r")
    local _x = tonumber(f.readLine())
    local _y = tonumber(f.readLine())
    local _z = tonumber(f.readLine())
    local d = tonumber(f.readLine())
    pos = vector.new(_x, _y, _z)
    dir = d or 0

    -- read remaining lines as home pads
    while true do
      local hx = f.readLine()
      if not hx then break end
      local hy = f.readLine()
      local hz = f.readLine()
      if hx and hy and hz then
        table.insert(homePads, vector.new(tonumber(hx), tonumber(hy), tonumber(hz)))
      end
    end
    f.close()
  else
    dir = 0
  end

  -- if no pads loaded, assume starting pos is only pad
  if #homePads == 0 then
    table.insert(homePads, vector.new(pos.x, pos.y, pos.z))
  end

  saveState()
end

-- === accessors ===
return {
  load = loadState,
  save = saveState,
  getPos = function() return pos end,
  setPos = function(p) pos = p saveState() end,
  getDir = function() return dir end,
  setDir = function(d) dir = d % 4 saveState() end,
  listHomePads = function() return homePads end,
  addHomePad = function(pad) table.insert(homePads, pad) saveState() end,
  getHome = function() return homePads[1] end -- legacy compat (first pad = "home")
}
