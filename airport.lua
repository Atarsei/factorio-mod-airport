local Event = require("event")

---@class Airport
---@field tower TerminalTower
local Airport = {}
Airport.__index = Airport
script.register_metatable("Airport", Airport)

Event.on_init(function()
    ---@type table<integer,Airport?>
    storage.airports = {}
end)

---@param tower TerminalTower
---@return Airport
function Airport.create(tower)
    local self = {
        tower = tower
    }
    setmetatable(self,Airport)
    local net_id = tower.terminal_fce:get_group_id()
    return self
end
