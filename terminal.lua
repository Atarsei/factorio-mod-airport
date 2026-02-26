local event = require("event")
local config = require("config")
local math2d = require("math2d")

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

local function direction4_to_vector(direction)
    if direction == 0 then
        return { x = 0, y = -1 }
    elseif direction == 4 then
        return { x = 1, y = 0 }
    elseif direction == 8 then
        return { x = 0, y = 1 }
    elseif direction == 12 then
        return { x = -1, y = 0 }
    end
end

event.on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(e)
    ---@cast e EventData.on_built_entity|EventData.on_robot_built_entity
    local entity = e.entity
    if entity.name ~= config.prefix 'terminal' then
        return
    end
    local surface = entity.surface
    local position = entity.position
    local opposite_direction = (entity.direction + 8) % 16
    local opposite_vector = direction4_to_vector(opposite_direction)
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
end, {
    { filter = "name", name = config.prefix 'terminal' }
})

event.on_event(
{ defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity },
    function(e)
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

event.on_event(defines.events.on_gui_opened, function(e)
    ---@cast e EventData.on_gui_opened
    if e.entity and e.entity.name == config.prefix 'terminal' then
        local player = game.get_player(e.player_index)
        if player then
            player.opened = nil
            local terminal = storage.terminal[e.entity.unit_number]
            assert(terminal, "Terminal data not found for unit number: " .. e.entity.unit_number)
            Gui_airport(player, terminal.airport_id)
        end
    end
end)

event.on_event(defines.events.on_gui_closed, function(e)
    ---@cast e EventData.on_gui_closed
    if e.gui_type == defines.gui_type.custom and e.element and e.element.name == config.prefix "airport_gui" then
        e.element.destroy()
    end
end)

local ui = require("ui")
--- @param player LuaPlayer
--- @param airport_id integer
function Gui_airport(player, airport_id)
    assert(airport_id, "Airport ID is required to open the GUI")
    local airport = storage.airport[airport_id]
    local entity = airport.terminal.entity

    ui.create(player.gui.screen,{
        type = "frame", caption = "Hello World", direction = "vertical", style = "inset_frame_container_frame", name = config.prefix "airport_gui",
        on_created = function(e) e.auto_center = true end,
        children = {
            { type = "entity-preview" ,on_created =function (e)
                e.entity = entity
                e.style.minimal_height = 190
                e.style.horizontally_stretchable = true
            end},
            {type = "checkbox", caption = "Allow aircrafts move to other airports", state = false},
            { type = "line", direction = "horizontal" },
            { type = "flow", direction = "vertical" ,on_created=function (e)
                for index, _ in ipairs(airport.slot) do
                    Gui_airport_slot(e, airport, index)
                end
            end}
        }
    })
end


local choose_item = ui.define_handlers("airport-choose-item",{
    [defines.events.on_gui_elem_changed] = function (e)
        local item = e.element.elem_value
        local tag = e.element.tags
        game.print(helpers.table_to_json(tag))
        local airport = storage.airport[tag.airport_id]
        local slot_index = tag.slot_index
        ---@cast item PrototypeWithQuality?
        airport.slot[slot_index].item = item
        game.print(helpers.table_to_json(airport.slot))
    end
})
---@param elm LuaGuiElement
---@param airport Airport
---@param slot_index integer
function Gui_airport_slot(elm, airport, slot_index)
    local slot = airport.slot[slot_index]

    return ui.create(elm, {
        type = "frame",direction = "horizontal",style = "bordered_frame",
        on_created = function(e) e.style.vertical_align = "center" end,
        children = {
            {
                type = "choose-elem-button", elem_type = 'item-with-quality',
                on_created = function (e)
                    e.elem_value = slot.item
                end,
                tags = { airport_id = airport.id, slot_index = slot_index },
                handlers = choose_item
            },
            {
                type = "flow", direction = "vertical",
                on_created = function (e)
                    e.style.vertical_align = "center"
                end,
                children = {
                    { type = "flow", direction = "horizontal" ,children={
                        { type = "switch", left_label_caption = "Supply", right_label_caption = "Demand", allow_none_state = true ,switch_state=slot.mode},
                        { type = "label", caption = "Priority:" },
                        { type = "textfield", numeric = true, text = tostring(slot.priority), style = "short_slider_value_textfield" }
                    }},
                    { type = "table", column_count = 2,children={
                        { type = "label", caption = "Expected" },
                        { type = "progressbar" ,value=0.8,on_created=function (e)
                            e.style.color = { r = 0.3, g = 0.3, b = 1 }
                        end},
                        { type = "label", caption = "In Store" },
                        { type = "progressbar", value = 0.3 },
                        { type = "label", caption = "Threshold" },
                        { type = "slider", minimum_value = 0, maximum_value = 1, value = slot.threshold, value_step = 0.1, style = "notched_slider" ,on_created=function (e)
                            e.style.horizontally_stretchable = true
                        end}
                    } }
                    
                }
            }
        },

    })
end
