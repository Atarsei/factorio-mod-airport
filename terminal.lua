local event = require("event")
local config = require("config")
local math2d = require("math2d")

---@class TerminalStorage
---@field terminal LuaEntity
---@field container LuaEntity
---@field loader LuaEntity
---@type TerminalStorage[]
storage.terminal = storage.terminal or {}

local function direction4_to_vector(direction)
    if direction == 0 then
        return {x=0, y=-1}
    elseif direction == 4 then
        return {x=1, y=0}
    elseif direction == 8 then
        return {x=0, y=1}
    elseif direction == 12 then
        return {x=-1, y=0}
    end
end

event.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(e)
    ---@cast e EventData.on_built_entity|EventData.on_robot_built_entity
    local entity = e.entity
    if entity.name ~= config.prefix 'terminal' then
        return
    end
    local surface = entity.surface
    local position = entity.position
    local opposite_direction = (entity.direction + 8) % 16
    local opposite_vector = direction4_to_vector(opposite_direction)
    local container = surface.create_entity{
        name = config.prefix 'terminal-container',
        position = math2d.position.add(position, opposite_vector),
        force = entity.force,
        create_build_effect_smoke = false
    }
    local loader = surface.create_entity{
        name = config.prefix 'terminal-loader',
        position = math2d.position.add(position, math2d.position.multiply_scalar(opposite_vector, 2)),
        force = entity.force,
        create_build_effect_smoke = false,
        direction = opposite_direction
    }
    assert(container and loader, "Failed to create terminal container or loader")
    local unit_number = entity.unit_number
    assert(unit_number, "Terminal entity has no unit number")
    storage.terminal[unit_number] = {
        terminal = entity,
        container = container,
        loader = loader
    }
end, {
    { filter = "name", name = config.prefix 'terminal' }
})

event.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, function(e)
    ---@cast e EventData.on_entity_died|EventData.on_player_mined_entity|EventData.on_robot_mined_entity
    local entity = e.entity
    if entity.name ~= config.prefix 'terminal' then
        return
    end
    local unit_number = entity.unit_number
    if not unit_number then return end
    local data = storage.terminal[unit_number]
    if not data then return end
    if data.container and data.container.valid then
        data.container.destroy()
    end
    if data.loader and data.loader.valid then
        data.loader.destroy()
    end
    storage.terminal[unit_number] = nil
end, {
    { filter = "name", name = config.prefix 'terminal' }
})
