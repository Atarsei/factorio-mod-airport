---@alias GuiEvents 
---|defines.events.on_gui_checked_state_changed
---|defines.events.on_gui_click
---|defines.events.on_gui_closed
---|defines.events.on_gui_confirmed
---|defines.events.on_gui_elem_changed
---|defines.events.on_gui_hover
---|defines.events.on_gui_leave	
---|defines.events.on_gui_location_changed	
---|defines.events.on_gui_opened	
---|defines.events.on_gui_selected_tab_changed	
---|defines.events.on_gui_selection_state_changed	
---|defines.events.on_gui_switch_state_changed	
---|defines.events.on_gui_text_changed	
---|defines.events.on_gui_value_changed

---@alias GuiEventData
---|EventData.on_gui_checked_state_changed
---|EventData.on_gui_click
---|EventData.on_gui_closed
---|EventData.on_gui_confirmed
---|EventData.on_gui_elem_changed
---|EventData.on_gui_hover
---|EventData.on_gui_leave	
---|EventData.on_gui_location_changed	
---|EventData.on_gui_opened	
---|EventData.on_gui_selected_tab_changed	
---|EventData.on_gui_selection_state_changed	
---|EventData.on_gui_switch_state_changed	
---|EventData.on_gui_text_changed	
---|EventData.on_gui_value_changed

---@alias GuiDefHandlers 
---|{[defines.events.on_gui_checked_state_changed]: fun(event:EventData.on_gui_checked_state_changed)}
---|{[defines.events.on_gui_click]: fun(event:EventData.on_gui_click)}
---|{[defines.events.on_gui_closed]: fun(event:EventData.on_gui_closed)}
---|{[defines.events.on_gui_confirmed]: fun(event:EventData.on_gui_confirmed)}
---|{[defines.events.on_gui_elem_changed]: fun(event:EventData.on_gui_elem_changed)}
---|{[defines.events.on_gui_hover]: fun(event:EventData.on_gui_hover)}
---|{[defines.events.on_gui_leave]: fun(event:EventData.on_gui_leave)}
---|{[defines.events.on_gui_location_changed]: fun(event:EventData.on_gui_location_changed)}
---|{[defines.events.on_gui_opened]: fun(event:EventData.on_gui_opened)}
---|{[defines.events.on_gui_selected_tab_changed]: fun(event:EventData.on_gui_selected_tab_changed)}
---|{[defines.events.on_gui_selection_state_changed]: fun(event:EventData.on_gui_selection_state_changed)}
---|{[defines.events.on_gui_switch_state_changed]: fun(event:EventData.on_gui_switch_state_changed)}
---|{[defines.events.on_gui_text_changed]: fun(event:EventData.on_gui_text_changed)}
---|{[defines.events.on_gui_value_changed]: fun(event:EventData.on_gui_value_changed)}

---@alias GuiDef LuaGuiElement.add_param | {children: GuiDef[]} | {handlers: string} | {style:LuaStyle}

local event = require("event")
local util = require("util")
local ui = {}

---@param symbol string
---@param handlers GuiDefHandlers
---@return string
function ui.define_handlers(symbol,handlers)
    for event_id, handler in pairs(handlers) do
        event.on_event(event_id, function (e)
            ---@cast e GuiEventData
            local tags = e.element.tags
            if tags and tags.symbol == symbol then
                handler(e)
            end
        end)
    end
    return symbol
end


---@param def GuiDef
---@param parent LuaGuiElement
---@return LuaGuiElement
function ui.create(def, parent)
    local element = parent.add(def)

    if def.handlers then
        local tags = element.tags
        element.tags = util.merge({tags,{symbol=def.handlers}})
    end

    local style = def.style
    if style then
        if type(style)=="table"then
            for key, value in pairs(style) do
                element.style[key] = value
            end
        end
    end

    if def.children then
        for _, child_def in ipairs(def.children) do
            ui.create_element(child_def, element)
        end
    end

    return element
end

return ui