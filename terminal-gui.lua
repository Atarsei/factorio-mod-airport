local ui = require("ui")

local airport_gui = ui.define_handlers("airport-gui", {
    [defines.events.on_gui_closed] = function(e)
        e.element.destroy()
    end
})

local airport_handlers = ui.batch_handlers("airport")


local choose_item = airport_handlers.define("airport-choose-item", {
    [defines.events.on_gui_elem_changed] = function(e,tag)
        local item = e.element.elem_value
        local airport = storage.airport[tag.airport_id]
        local slot_index = tag.slot_index
        ---@cast item PrototypeWithQuality?
        airport.slot[slot_index].item = item
    end
})
local change_slot_state = airport_handlers.define("change_slot_state",{
    [defines.events.on_gui_switch_state_changed]=function (e, tag)
        local airport = storage.airport[tag.airport_id]
        airport.slot[tag.slot_index].mode = e.element.switch_state
    end
})
local change_slider = airport_handlers.define("change_slider",{
    [defines.events.on_gui_value_changed]=function (e, tag)
        local airport = storage.airport[tag.airport_id]
        airport.slot[tag.slot_index].threshold = e.element.slider_value
    end
})
local change_priority = airport_handlers.define("change_priority",{
    [defines.events.on_gui_text_changed]=function (e, tag)
        local airport = storage.airport[tag.airport_id]
        local slot = airport.slot[tag.slot_index]
        slot.priority= tonumber(e.text) or slot.priority
    end
})

---@param airport Airport
---@param slot_index integer
---@return GuiDef
local function Gui_airport_slot(airport, slot_index)
    local slot = airport.slot[slot_index]

    return {
        type = "frame",
        direction = "horizontal",
        style = "bordered_frame",
        on_created = function(e) e.style.vertical_align = "center" end,
        children = {
            {
                type = "choose-elem-button",
                elem_type = 'item-with-quality',
                on_created = function(e)
                    e.elem_value = slot.item
                end,
                tags = { airport_id = airport.id, slot_index = slot_index },
                handlers = choose_item
            },
            {
                type = "flow",
                direction = "vertical",
                on_created = function(e)
                    e.style.vertical_align = "center"
                end,
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            { type = "switch",    left_label_caption = "Supply", right_label_caption = "Demand", allow_none_state = true,               switch_state = slot.mode ,
                            tags = { airport_id = airport.id, slot_index = slot_index },
                            handlers = change_slot_state
                            },
                            { type = "label",     caption = "Priority:" },
                            { type = "textfield", numeric = true,                text = tostring(slot.priority), style = "short_slider_value_textfield",
                            tags = { airport_id = airport.id, slot_index = slot_index },
                            handlers=change_priority
                            }
                        }
                    },
                    {
                        type = "table",
                        column_count = 2,
                        children = {
                            { type = "label",       caption = "Expected" },
                            {
                                type = "progressbar",
                                value = 0.8,
                                on_created = function(e)
                                    e.style.color = { r = 0.3, g = 0.3, b = 1 }
                                end
                            },
                            { type = "label",       caption = "In Store" },
                            { type = "progressbar", value = 0.3 },
                            { type = "label",       caption = "Threshold" },
                            {
                                type = "slider",
                                minimum_value = 0,
                                maximum_value = 1,
                                value = slot.threshold,
                                value_step = 0.1,
                                style = "notched_slider",
                                on_created = function(e)
                                    e.style.horizontally_stretchable = true
                                end,
                                tags = { airport_id = airport.id, slot_index = slot_index },
                                handlers = change_slider
                            }
                        }
                    }

                }
            }
        },

    }
end

--- @param airport_id integer
--- @return GuiDef
local function Gui_airport(airport_id)
    assert(airport_id, "Airport ID is required to open the GUI")
    local airport = storage.airport[airport_id]
    local entity = airport.terminal.entity

    return {
        type = "frame",
        caption = "Airport",
        direction = "vertical",
        style = "inset_frame_container_frame",
        on_created = function(e) e.auto_center = true end,
        handlers = airport_gui,
        children = {
            {
                type = "entity-preview",
                on_created = function(e)
                    e.entity = entity
                    e.style.minimal_height = 190
                    e.style.horizontally_stretchable = true
                end
            },
            { type = "checkbox", caption = "Allow aircrafts move to other airports", state = false },
            { type = "line",     direction = "horizontal" },
            {
                type = "flow",
                direction = "vertical",
                children={
                    ui.icollect(airport.slot,function (index, value)
                        return Gui_airport_slot(airport, index)
                    end)
                }
            }
        }
    }
end



return Gui_airport