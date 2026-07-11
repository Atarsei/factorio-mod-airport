local config = require("config")
local FCE = require("fluid_connected_entities")

---@class Taxiway
---@field entity LuaEntity
---@field taxiway_fce FCE

local Taxiway = {}
Taxiway.__index = Taxiway
script.register_metatable("Taxiway", Taxiway)

---@param entity LuaEntity
function Taxiway.create(entity)
    local self = setmetatable({}, Taxiway)
    self.entity = entity
    self.taxiway_fce = FCE.register(entity,1)
    return self
end

function Taxiway:destroy()
    self.taxiway_fce:unregister()
    storage.terminal_sub[self.entity.unit_number] = nil
end

local Event = require("event")
Event.on_init(function()
    ---@type table<uint, Taxiway>
    storage.taxiway={}
end)

Event.entity(config.name.taxiway)
    .on_event(Event.on_entity_build, function(event)
    ---@cast event EventBuildData
    local entity = event.entity
    storage.taxiway[entity.unit_number] = Taxiway.create(entity)
end)
.on_event(Event.on_entity_destory, function(event)
    ---@cast event EventDestotyData
    local entity = event.entity
    local taxiway = storage.taxiway[entity.unit_number]
    taxiway:destroy()
end)
Event.entity(config.name.taxiway_3x3)
    .on_event(Event.on_entity_build, function(event)
    ---@cast event EventBuildData
    local entity = event.entity
    storage.taxiway[entity.unit_number] = Taxiway.create(entity)
end)
.on_event(Event.on_entity_destory, function(event)
    ---@cast event EventDestotyData
    local entity = event.entity
    local taxiway = storage.taxiway[entity.unit_number]
    taxiway:destroy()
end)
