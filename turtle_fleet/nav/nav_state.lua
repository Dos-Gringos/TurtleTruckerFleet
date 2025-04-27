-- nav/state.lua
local posFile = "nav_pos.txt"
local pos, dir, home

-- === save position + direction ===
local function saveState()
    local f = fs.open(posFile, "w")
    f.writeLine(pos.x)
    f.writeLine(pos.y)
    f.writeLine(pos.z)
    f.writeLine(dir)
    f.close()
  end  

-- === load or initialize state ===
local function loadState()
  if fs.exists(posFile) then
    local f = fs.open(posFile, "r")
    local x, y, z, d = tonumber(f.readLine()), tonumber(f.readLine()), tonumber(f.readLine()), tonumber(f.readLine())
    f.close()
    if x and y and z and d then
      pos = vector.new(x, y, z)
      dir = d
    else
      error("invalid nav_pos.txt data")
    end
  else
    local detectDirection = require("nav/detect_direction")
    local p, d = detectDirection()
    pos = p
    dir = d
    home = vector.new(pos.x, pos.y, pos.z)
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
  getHome = function() return home end
}
