local math2d = require "math2d"
local utils = require "utils"
---@class Lane
---@field side LuaEntity[]
---@field direction "v"|"h"
---@type Lane[]
storage.lanes = storage.lanes or {}
---@class Block
---@field entity LuaEntity
---@field lane_id integer?

---@type Block[]
storage.blocks = storage.blocks or {}

script.on_event(defines.events.on_built_entity, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    ---@type Block
    local block = {
        entity = entity,
    }
    local area
    local direction
    if entity.direction == defines.direction.north or entity.direction == defines.direction.south then
        area = {
            math2d.position.add(entity.position, { x = 0, y = -5 }),
            math2d.position.add(entity.position, { x = 0, y = 5 })
        }
        direction = "v"
    else
        area = {
            math2d.position.add(entity.position, { x = -5, y = 0 }),
            math2d.position.add(entity.position, { x = 5, y = 0 })
        }
        direction = "h"
    end
    local nearby_blocks = entity.surface.find_entities_filtered({ area = area, name = "block5" })
    for _, nearby_entity in ipairs(nearby_blocks) do
        if nearby_entity.unit_number == entity.unit_number  then
            goto continue
        end
        if nearby_entity.direction ==defines.direction.north or nearby_entity.direction == defines.direction.south then
            if direction == "h" then
                goto continue
            end
        else
            if direction == "v" then
                goto continue
            end
        end
        if utils.manhattan_distance(entity.position, nearby_entity.position) > 5 then
            goto continue
        end
        local nearby_block = storage.blocks[nearby_entity.unit_number]
        assert(nearby_block, "Block not found in storage.")
        if nearby_block.lane_id then
            local lane = storage.lanes[nearby_block.lane_id]
            local side1 = lane.side[1]
            local side2 = lane.side[2]
            if side1.unit_number == nearby_entity.unit_number then
                lane.side[1] = entity
            else
                assert(side2.unit_number == nearby_entity.unit_number, "Nearby entity not found in lane.")
                lane.side[2] = entity
            end
            block.lane_id = nearby_block.lane_id
        else
            ---@type Lane
            local lane = {
                side = { nearby_entity, entity },
                direction = direction
            }
            table.insert(storage.lanes, lane)
            block.lane_id = #storage.lanes
            nearby_block.lane_id = #storage.lanes
        end
        ::continue::
    end
    storage.blocks[entity.unit_number] = block
end, { { filter = "name", name = "block5" } })

--[[ gizmo ]]
local gizmo_ticks = 15
script.on_nth_tick(gizmo_ticks, function(event)
    for _, value in ipairs(storage.lanes) do
        if #value.side == 2 then
            rendering.draw_circle {
                color = { r = 0, g = 1, b = 0 },
                radius = 0.5,
                filled = true,
                target = value.side[1],
                surface = value.side[1].surface,
                time_to_live = gizmo_ticks
            }
            rendering.draw_circle {
                color = { r = 0, g = 1, b = 0 },
                radius = 0.5,
                filled = true,
                target = value.side[2],
                surface = value.side[2].surface,
                time_to_live = gizmo_ticks
            }
            rendering.draw_line {
                color = { r = 1, g = 0, b = 0 },
                width = 2,
                from = value.side[1].position,
                to = value.side[2].position,
                surface = value.side[1].surface,
                time_to_live = gizmo_ticks
            }
        end
    end
end)
