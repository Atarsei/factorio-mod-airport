local Event = require("event")
local config = require("config")
local math2d = require("math2d")
local FCE = require("fluid_connected_entities")
require("util")

Event.on_init(function()
    ---@type TerminalSub[]
    storage.terminal_sub = {}
end)

---@class TerminalSub
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
    local opposite_direction = util.oppositedirection(entity.direction)
    local opposite_vector = util.direction_vectors[opposite_direction]
    local loader = entity.surface.create_entity {
        name = config.prefix 'terminal-loader',
        position = math2d.position.add(entity.position, math2d.position.multiply_scalar(opposite_vector, 2)),
        force = entity.force,
        create_build_effect_smoke = false,
        direction = opposite_direction
    }
    if loader then
        self.loader = loader
    else
        return nil
    end
    storage.terminal_sub[entity.unit_number] = self
    self.terminal_fce = FCE.register(entity,1)
    return self
end

function TerminalSub:destroy()
    self.loader.destroy()
    self.terminal_fce:unregister()
    storage.terminal_sub[self.entity.unit_number] = nil
    game.print(self.entity.unit_number .. " is destroyed")
end

---@param unit_number integer?
---@return TerminalSub?
function TerminalSub.get(unit_number)
    return storage.terminal_sub[unit_number]
end

Event.entity(config.name.terminal_sub)
    .on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(event)
        ---@cast event EventData.on_built_entity|EventData.on_robot_built_entity
        local entity = event.entity
        TerminalSub.create(entity)
        game.print("id:" .. entity.fluidbox.get_fluid_segment_id(1))
    end)
    .on_event(
        { defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity },
        function(event)
            ---@cast event EventData.on_entity_died|EventData.on_player_mined_entity|EventData.on_robot_mined_entity
            local e = TerminalSub.get(event.entity.unit_number)
            if e then
                e:destroy()
            end
        end)