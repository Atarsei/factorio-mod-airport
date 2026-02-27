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

---@alias GuiDefChild GuiDef|GuiDef[]
---@alias GuiDefChildFn fun(children?:GuiDefUnresolvedChild[]):GuiDefUnresolvedChild
---@alias GuiDefUnresolvedChild GuiDefChild
---@alias GuiDef LuaGuiElement.add_param | {children?: GuiDefUnresolvedChild[]} | {handlers?: string} | {on_created?:fun(LuaGuiElement)}

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
            if not e.element then return end
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
function ui.create( parent,def)
    local handlers = def.handlers
    local on_created = def.on_created
    local children = def.children
    def.handlers = nil
    def.on_created = nil
    def.children = nil

    local element = parent.add(def)

    if handlers then
        local tags = element.tags
        --tags.symbol=handlers
        element.tags = util.merge({tags,{symbol=handlers}})
    end

    if on_created then
        if type(on_created)=="function"then
            on_created(element)
        end
    end

    if children then
        for _, child in ipairs(children) do
            if child.type then
                ui.create(element,child)
            else
                for _, value in ipairs(child) do
                    ui.create( element,value)
                end
            end
        end
    end
 
    return element
end


---@param def GuiDef
---@return fun(children?:GuiDef[]):GuiDef
function ui.h(def)
    return function (children)
        def.children = children
        return def.children
    end
end

---@generic T
---@generic R
---@param t {integer:T}
---@param fn fun(index:integer,value:T):R
---@return R
function ui.icollect(t,fn)
    local collect= {}
    for index, value in ipairs(t) do
        table.insert(collect,fn(index,value))
    end
    return collect
end

return ui