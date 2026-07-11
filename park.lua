local config = require("config")
local FCE = require("fluid_connected_entities")

---@class Park
---@field entity LuaEntity
---@field taxiway_fce FCE
---@field prev_group_id number?

local Park = {}
Park.__index = Park
script.register_metatable("Park", Park)

---@param entity LuaEntity
function Park.create(entity)
    local self = setmetatable({}, Park)
    self.entity = entity
    self.taxiway_fce = FCE.register(entity,1)
    return self
end

function Park:destroy()
    self.taxiway_fce:unregister()
    storage.terminal_sub[self.entity.unit_number] = nil
end

local Event = require("event")
Event.on_init(function()
    ---@type table<uint, Park>
    storage.park={}
end)
Event.entity(config.name.park)
    .on_event(Event.on_entity_build, function(event)
    ---@cast event EventBuildData
    local entity = event.entity
    local park = Park.create(entity)
    storage.park[entity.unit_number] = park
    
    local neigh = entity.get_fluid_box_neighbours(2)
    if neigh and #neigh == 1 then
        local neighbor = neigh[1].entity
        local m = storage.managers[config.name.terminal_connection] --[[@as TerminalManager]]
        local neighbor_fce = m.lookup[neighbor.unit_number]
        local net_id = neighbor_fce:get_group_id()
        m.parks[net_id] = m.parks[net_id] or {}
        m.parks[net_id][neighbor.unit_number] = entity
        park.prev_group_id = net_id
    end
end)
.on_event(Event.on_entity_destory, function(event)
    ---@cast event EventDestotyData
    local entity = event.entity
    local park = storage.park[entity.unit_number]
    local m = storage.managers[config.name.terminal_connection] --[[@as TerminalManager]]
    if park.prev_group_id and m.parks[park.prev_group_id] then
        m.parks[park.prev_group_id][entity.unit_number] = nil
        if next(m.parks[park.prev_group_id]) == nil then
            m.parks[park.prev_group_id] = nil
        end
    end
    park:destroy()
end)