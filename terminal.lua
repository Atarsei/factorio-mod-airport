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
        slot = {Airport.default_slot(), Airport.default_slot(), Airport.default_slot()}
    }
    terminal.airport_id = airport_id
    table.insert(storage.airport, airport)
    storage.terminal[unit_number] = terminal
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

--- auto close
--- @param player LuaPlayer
--- @param airport_id integer
function Gui_airport(player,airport_id)
    assert(airport_id, "Airport ID is required to open the GUI")
    local airport = storage.airport[airport_id]
    local frame = player.gui.screen.add{type="frame", caption="Hello World", direction="vertical",style="inset_frame_container_frame",name = config.prefix"airport_gui"}
    frame.auto_center = true
    player.opened = frame
    local entity = airport.terminal.entity
    local camera = frame.add{type="entity-preview"}
    camera.entity = entity
    camera.style.minimal_height = 190
    camera.style.horizontally_stretchable = true
    local checkbox = frame.add{type="checkbox",  caption="Allow aircrafts move to other airports", state=false}
    frame.add{type="line", direction="horizontal"}
    local flow = frame.add{type="flow", direction="vertical"}
    for index, _ in ipairs(airport.slot) do
        Gui_airport_slot(flow, airport, index)
    end
end
---@param elm LuaGuiElement
---@param airport Airport
---@param slot_index integer 
function Gui_airport_slot(elm, airport, slot_index)
    local slot = airport.slot[slot_index]
    local wrap = elm.add{type="frame",direction="horizontal",style="bordered_frame"}
    local button = wrap.add{type="choose-elem-button",elem_type ='item-with-quality',name=config.prefix"airport_slot_item",tags = {airport_id = airport.id, slot_index = slot_index}}
    button.elem_value = slot.item
    wrap.style.vertical_align = "center"

    local bar = wrap.add{type="flow",direction="vertical"}
    
    local priority_group = bar.add{type="flow",direction="horizontal"}
    local switch = priority_group.add{type="switch", left_label_caption="Supply", right_label_caption="Demand",allow_none_state=true}
    switch.switch_state  = slot.mode
    priority_group.style.vertical_align = "center"
    priority_group.add{type="label", caption="Priority:"}
    priority_group.add{type="textfield",numeric=true,text=tostring(slot.priority),style="short_slider_value_textfield"}

    local progress_table = bar.add{type="table", column_count=2}
    progress_table.add{type="label", caption="Expected"}
    local progress = progress_table.add{type="progressbar"}
    progress.style.color = {r=0.3,g=0.3,b=1}
    progress.value = 0.8
    progress_table.add{type="label", caption="In Store"}
    local progress2 = progress_table.add{type="progressbar",value=0.3}
    
    progress_table.add{type="label", caption="Threshold"}
    local slider = progress_table.add{type="slider", minimum_value = 0, maximum_value = 1, value = slot.threshold, value_step = 0.1,style="notched_slider"}
    slider.style.horizontally_stretchable = true
    return wrap
end

event.on_event(defines.events.on_gui_elem_changed, function(e)
    ---@cast e EventData.on_gui_elem_changed
    if e.element.name == config.prefix"airport_slot_item" then
        local item = e.element.elem_value
        local tag = e.element.tags
        game.print(helpers.table_to_json(tag))
        local airport = storage.airport[tag.airport_id]
        local slot_index = tag.slot_index
        ---@cast item PrototypeWithQuality?
        airport.slot[slot_index].item = item
        game.print(helpers.table_to_json(airport.slot))
    end
end)
