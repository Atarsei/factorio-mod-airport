local Event = require("event")
local config = require("config")
local math2d = require("math2d")
local FCE = require("fluid_connected_entities")
local TerminalLoader = require("terminal_loader")
local TerminalTower = require("terminal_tower")

Event.on_init(function()
    ---@type TerminalSub[]
    storage.terminal_sub = {}
end)

---@class TerminalSub:TerminalLoaderOwner
---@field entity LuaEntity
---@field loader LuaEntity
---@field terminal_fce FCE
local TerminalSub = {}
TerminalSub.__index = TerminalSub
script.register_metatable("TerminalSub", TerminalSub)

---@param entity LuaEntity?
---@return TerminalSub?
function TerminalSub.create(entity)
    if not (entity and entity.valid and entity.unit_number) then
        return nil
    end
    local self = setmetatable({}, TerminalSub)
    self.entity = entity
    self.terminal_fce = FCE.register(entity, 1)
    local loader = TerminalLoader.create(self,{0,2},defines.direction.south)
    if loader then
        self.loader = loader
    else
        return nil
    end
    storage.terminal_sub[entity.unit_number] = self
    return self
end

function TerminalSub:destroy()
    TerminalLoader.destroy(self.loader)
    self.terminal_fce:unregister()
    storage.terminal_sub[self.entity.unit_number] = nil
    game.print(self.entity.unit_number .. " is destroyed")
end

---@param unit_number integer?
---@return TerminalSub?
function TerminalSub.get(unit_number)
    return storage.terminal_sub[unit_number]
end

---@impl TerminalLoaderOwner
---@return Airport?
function TerminalSub:get_airport()
    local group = self.terminal_fce:get_manager() --[[@as TerminalManager]]
    local tower = group.tower[self.terminal_fce.prev_group_id --[[@as integer]]]
    if tower then
        return TerminalTower.get(tower.unit_number).airport
    end
end

Event.entity(config.name.terminal_sub)
    .on_event(Event.on_entity_build, function(event)
        ---@cast event EventBuildData
        local entity = event.entity
        TerminalSub.create(entity)
    end)
    .on_event(
        Event.on_entity_destory,
        function(event)
            ---@cast event EventDestotyData
            local e = TerminalSub.get(event.entity.unit_number)
            if e then
                e:destroy()
            end
        end)
