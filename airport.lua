local config = require "config"
---@class SlotData
---@field item PrototypeWithQuality?
---@field container LuaEntity?
---@field mode SwitchState
---@field priority integer
---@field threshold number

---@class Airport
---@field id integer
---@field tower TerminalTower
---@field active_slots integer
---@field slots SlotData[]
local Airport = {}
Airport.__index = Airport
script.register_metatable("Airport", Airport)

---@return SlotData
function Airport:default_slots()
    return {
        item = nil,
        mode = "left",
        priority = 100,
        threshold = 0.5,
        container = self.tower.entity.surface.create_entity {
            name = config.name.terminal_container,
            position = self.tower.entity.position
        }
    }
end

---@param tower TerminalTower
---@return Airport
function Airport.new(tower)
    local airport_id = #storage.airport + 1
    local airport = {
        id = airport_id,
        active_slots = 0,
        slots = {},
        tower = tower
    }
    setmetatable(airport, Airport)
    airport:resize_slots()
    table.insert(storage.airport, airport)
    return airport
end

function Airport:destroy()
    for index, s in ipairs(self.slots) do
        s.container.destroy()
    end
end

function Airport:resize_slots()
    local size = self.tower.terminal_fce:net_size()
    local slot_level = config.airport_level(size)
    local expand_size = slot_level - #self.slots
    for i = 1, expand_size, 1 do
        table.insert(self.slots, self:default_slots())
    end
    self.active_slot = slot_level
end

---@param slot SlotData
function Airport.get_slot_content(slot)
    if not (slot.item and slot.container) then
        return 0
    end
    local inv = slot.container.get_inventory(defines.inventory.chest) --[[@as LuaInventory]]
    local full = inv.get_item_count(slot.item.name)
    local empty = inv.get_insertable_count(slot.item.name)
    return full / (full + empty)
end

require("event").on_init(function()
    ---@type Airport[]
    storage.airport = {}
end)

return Airport
