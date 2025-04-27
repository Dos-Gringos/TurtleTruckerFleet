-- nav/move.lua
local state = require("nav/state")

-- === face a direction (0=N,1=E,2=S,3=W) ===
local function face(targetDir)
  local dir = state.getDir()
  while dir ~= targetDir do
    turtle.turnRight()
    dir = (dir + 1) % 4
    state.setDir(dir)
  end
end

-- === axis-based movement ===
local function moveAxis(axis, delta)
  local steps = math.abs(delta)
  local fn
  if axis == "x" then
    face(delta > 0 and 1 or 3)
    fn = turtle.forward
  elseif axis == "z" then
    face(delta > 0 and 2 or 0)
    fn = turtle.forward
  elseif axis == "y" then
    fn = delta > 0 and turtle.up or turtle.down
  end

  for _ = 1, steps do
    while not fn() do
      sleep(0.5)
    end
    local pos = state.getPos()
    if axis == "x" then
      pos = pos + vector.new(delta > 0 and 1 or -1, 0, 0)
    elseif axis == "y" then
      pos = pos + vector.new(0, delta > 0 and 1 or -1, 0)
    elseif axis == "z" then
      pos = pos + vector.new(0, 0, delta > 0 and 1 or -1)
    end
    state.setPos(pos)
  end
end

-- === moveTo target vector ===
local function moveTo(dest)
  local current = state.getPos()
  local dx = dest.x - current.x
  local dy = dest.y - current.y
  local dz = dest.z - current.z

  moveAxis("y", dy)
  moveAxis("x", dx)
  moveAxis("z", dz)
end

return {
  moveTo = moveTo,
  face = face
}
