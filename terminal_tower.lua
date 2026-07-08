local Event = require("event")
local config = require("config")
local math2d = require("math2d")
local FCE = require("fluid_connected_entities")
local ui = require("ui")
local gui = require("terminal-gui")
local Airport = require("airport")
local TerminalLoader = require("terminal_loader")

Event.on_init(function()
    ---@type TerminalTower[]
    storage.terminal_tower = {}
end)

---@class TerminalTower: TerminalLoaderOwner
---@field airport Airport
---@field entity LuaEntity
---@field terminal_fce FCE
local TerminalTower = {}
TerminalTower.__index = TerminalTower
script.register_metatable("TerminalTower", TerminalTower)

---@param entity LuaEntity?
---@return TerminalTower?
function TerminalTower.create(entity)
    if not (entity and entity.valid and entity.unit_number) then
        return nil
    end
    local self = setmetatable({}, TerminalTower)
    self.entity = entity
    storage.terminal_tower[entity.unit_number] = self
    self.terminal_fce = FCE.register(entity, 1)
    self.airport = Airport.new(self)

    self.loaders = {
        TerminalLoader.create(self,{-1,2},defines.direction.south),
        TerminalLoader.create(self,{0,2},defines.direction.south),
        TerminalLoader.create(self,{1,2},defines.direction.south),
    }
    return self
end

function TerminalTower:destroy()
    self.airport:destroy()
    for _, l in ipairs(self.loaders) do
        TerminalLoader.destroy(l)
    end
    self.terminal_fce:unregister()
    storage.terminal_tower[self.entity.unit_number] = nil
    game.print(self.entity.unit_number .. " is destroyed")
end

---@param unit_number integer?
---@return TerminalTower?
function TerminalTower.get(unit_number)
    return storage.terminal_tower[unit_number]
end

function TerminalTower:get_airport()
    return self.airport
end

Event.entity(config.name.terminal_tower)
    .on_event(Event.on_entity_build, function(event)
        ---@cast event EventBuildData
        local entity = event.entity
        TerminalTower.create(entity)
    end)
    .on_event(
        Event.on_entity_destory,
        function(event)
            ---@cast event EventDestotyData
            local e = TerminalTower.get(event.entity.unit_number)
            if e then
                e:destroy()
            end
        end)
    .on_event(defines.events.on_gui_opened, function(e)
        ---@cast e EventData.on_gui_opened
        local player = game.get_player(e.player_index)
        if player then
            player.opened = nil
            local terminal = TerminalTower.get(e.entity.unit_number)
            assert(terminal, "Terminal data not found for unit number: " .. e.entity.unit_number)
            player.opened = ui.create(player.gui.screen, gui(terminal.airport))
        end
    end)

return TerminalTower