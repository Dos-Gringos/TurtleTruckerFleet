-- nav/init.lua
local state = require("nav/state")
local move = require("nav/move")
local fuel = require("nav/fuel")
state.load()
 
return {
  moveTo = move.moveTo,
  checkFuel = fuel.checkFuel,
  refuelIfNeeded = fuel.refuelIfNeeded,
  emergencyReturn = fuel.emergencyReturn,
  atHome = function() return state.getPos():equals(state.getHome()) end,
  getPos = state.getPos,
  face = move.face,
  home = state.getHome()
}
 