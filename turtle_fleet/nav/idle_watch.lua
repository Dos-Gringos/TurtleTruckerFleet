-- idle_watch.lua
-- monitor turtle idle time, return home if needed

local nav = require("nav")
local goHome = require("home_return")

local timeout = 300 -- seconds (5 minutes idle)

local lastMove = os.clock()

local function resetTimer()
  lastMove = os.clock()
end

local function checkIdle()
  if os.clock() - lastMove >= timeout then
    print("[IDLE WATCH] Timeout reached. Returning home...")
    if not nav.atHome() then
      goHome()
    end
    resetTimer()
  end
end

return {
  resetTimer = resetTimer,
  checkIdle = checkIdle
}
