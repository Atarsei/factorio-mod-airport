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

event.on_event(defines.events.on_gui_opened, function(e)
    ---@cast e EventData.on_gui_opened
    if e.entity and e.entity.name == config.prefix 'terminal' then
        local player = game.get_player(e.player_index)
        if player then
            player.opened = nil
            helloworld_gui(player, e.entity)
        end
    end
end)

event.on_event(defines.events.on_gui_closed, function(e)
    ---@cast e EventData.on_gui_closed
    if e.gui_type == defines.gui_type.custom and e.element and e.element.name == "helloworld_frame" then
        e.element.destroy()
    end
end)

--- auto close
function helloworld_gui(player,entity)
    local frame = player.gui.screen.add{type="frame", name="helloworld_frame", caption="Hello World", direction="vertical",style="inset_frame_container_frame"}
    frame.auto_center = true
    player.opened = frame
    local camera = frame.add{type="entity-preview", name="helloworld_camera", entity=entity}
    camera.entity = entity
    camera.style.minimal_height = 190
    camera.style.horizontally_stretchable = true
    local checkbox = frame.add{type="checkbox", name="helloworld_checkbox", caption="Allow aircrafts move to other airports", state=false}
    frame.add{type="line", direction="horizontal"}
    local flow = frame.add{type="flow", direction="vertical"}
    item_gui(flow)
    --frame.add{type="line", direction="horizontal"}
    --item_gui(flow)

end
---@param elm LuaGuiElement
function item_gui(elm)
    local wrap = elm.add{type="flow",direction="horizontal"}
    wrap.add{type="choose-elem-button",elem_type ='item'}
    wrap.style.vertical_align = "center"

    local bar = wrap.add{type="flow",direction="vertical"}
    
    local priority_group = bar.add{type="flow",direction="horizontal"}
    priority_group.add{type="switch", left_label_caption="Supply", right_label_caption="Demand",allow_none_state=true}
    priority_group.style.vertical_align = "center"
    priority_group.add{type="label", caption="Priority:"}
    priority_group.add{type="textfield",numeric=true,text="100",style="short_slider_value_textfield"}

    local progress = bar.add{type="progressbar"}
    progress.value = 0.8
    local progress2 = bar.add{type="progressbar",value=0.3}
    progress2.style.color = {r=0.3,g=0.3,b=1}
    local slider = bar.add{type="slider",name="hello_slider", minimum_value = 0, maximum_value = 1, value = 0.4, value_step = 0.1,style="notched_slider"}
    slider.style.horizontally_stretchable = true
    return wrap
end

