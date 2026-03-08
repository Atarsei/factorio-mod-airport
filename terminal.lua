local event = require("event")
local config = require("config")
local math2d = require("math2d")
local ui = require("ui")
local gui = require("terminal-gui")

---@class Terminal
---@field entity LuaEntity
---@field container LuaEntity
---@field loader LuaEntity
---@field airport_id integer?

---@type Terminal[]
storage.terminal = storage.terminal or {}
---@class Airport
---@field id integer
---@field terminal Terminal
---@field active_slot integer
---@field slot SlotData[]
---@class SlotData
---@field item PrototypeWithQuality?
---@field mode SwitchState
---@field priority integer
---@field threshold number
local Airport = {}
---@return SlotData
function Airport.default_slot()
    return {
        item = nil,
        mode = "left",
        priority = 100,
        threshold = 0.5
    }
end

---@type Airport[]
storage.airport = storage.airport or {}

event.entity(config.name.terminal)
    .on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(e)
        ---@cast e EventData.on_built_entity|EventData.on_robot_built_entity
        local entity = e.entity
        if entity.name ~= config.prefix 'terminal' then
            return
        end
        local surface = entity.surface
        local position = entity.position
        local opposite_direction = util.oppositedirection(entity.direction)
        local opposite_vector = util.direction_vectors[opposite_direction]
        local container = surface.create_entity {
            name = config.prefix 'terminal-container',
            position = math2d.position.add(position, opposite_vector),
            force = entity.force,
            create_build_effect_smoke = false
        }
        local loader = surface.create_entity {
            name = config.prefix 'terminal-loader',
            position = math2d.position.add(position, math2d.position.multiply_scalar(opposite_vector, 2)),
            force = entity.force,
            create_build_effect_smoke = false,
            direction = opposite_direction
        }
        assert(container and loader, "Failed to create terminal container or loader")
        local unit_number = entity.unit_number
        assert(unit_number, "Terminal entity has no unit number")
        ---@type Terminal
        local terminal = {
            entity = entity,
            container = container,
            loader = loader,
        }
        local airport_id = #storage.airport + 1
        ---@type Airport
        local airport = {
            id = airport_id,
            terminal = terminal,
            active_slot = 3,
            slot = { Airport.default_slot(), Airport.default_slot(), Airport.default_slot() }
        }
        terminal.airport_id = airport_id
        table.insert(storage.airport, airport)
        storage.terminal[unit_number] = terminal
    end)
    .on_event(
    { defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity },
        function(e)
            ---@cast e EventData.on_entity_died|EventData.on_player_mined_entity|EventData.on_robot_mined_entity
            local entity = e.entity
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
        end)
    .on_event(defines.events.on_gui_opened, function(e)
        ---@cast e EventData.on_gui_opened
        local player = game.get_player(e.player_index)
        if player then
            player.opened = nil
            local terminal = storage.terminal[e.entity.unit_number]
            assert(terminal, "Terminal data not found for unit number: " .. e.entity.unit_number)
            player.opened = ui.create(player.gui.screen,gui(terminal.airport_id))
        end
    end)
