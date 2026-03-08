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
---|{[defines.events.on_gui_checked_state_changed]: fun(e:EventData.on_gui_checked_state_changed,tag:Tags)}
---|{[defines.events.on_gui_click]: fun(e:EventData.on_gui_click,tag:Tags)}
---|{[defines.events.on_gui_closed]: fun(e:EventData.on_gui_closed,tag:Tags)}
---|{[defines.events.on_gui_confirmed]: fun(e:EventData.on_gui_confirmed,tag:Tags)}
---|{[defines.events.on_gui_elem_changed]: fun(e:EventData.on_gui_elem_changed,tag:Tags)}
---|{[defines.events.on_gui_hover]: fun(e:EventData.on_gui_hover,tag:Tags)}
---|{[defines.events.on_gui_leave]: fun(e:EventData.on_gui_leave,tag:Tags)}
---|{[defines.events.on_gui_location_changed]: fun(e:EventData.on_gui_location_changed,tag:Tags)}
---|{[defines.events.on_gui_opened]: fun(e:EventData.on_gui_opened,tag:Tags)}
---|{[defines.events.on_gui_selected_tab_changed]: fun(e:EventData.on_gui_selected_tab_changed,tag:Tags)}
---|{[defines.events.on_gui_selection_state_changed]: fun(e:EventData.on_gui_selection_state_changed,tag:Tags)}
---|{[defines.events.on_gui_switch_state_changed]: fun(e:EventData.on_gui_switch_state_changed,tag:Tags)}
---|{[defines.events.on_gui_text_changed]: fun(e:EventData.on_gui_text_changed,tag:Tags)}
---|{[defines.events.on_gui_value_changed]: fun(e:EventData.on_gui_value_changed,tag:Tags)}

---@alias GuiDefChild GuiDef|GuiDef[]
---@alias GuiDefChildFn fun(children?:GuiDefUnresolvedChild[]):GuiDefUnresolvedChild
---@alias GuiDefUnresolvedChild GuiDefChild
---@alias GuiDef LuaGuiElement.add_param | {children?: GuiDefUnresolvedChild[]} | {handlers?: string} | {on_created?:fun(LuaGuiElement)}

local event = require("event")
local util = require("util")
---@class UI
local ui = {}

---@type table<string,true?>
local symbol_existed = {}
---@param symbol string
---@param handlers GuiDefHandlers
---@return string
function ui.define_handlers(symbol,handlers)
    assert(not symbol_existed[symbol],"handlers symbol: '"..symbol.."'have already existed")
    symbol_existed[symbol] = true
    for event_id, handler in pairs(handlers) do
        event.on_event(event_id, function (e)
            ---@cast e GuiEventData
            if not e.element then return end
            local tags = e.element.tags
            if tags and tags.symbol == symbol then
                handler(e,tags)
            end
        end)
    end
    return symbol
end

---@param namespace string
function ui.batch_handlers(namespace)
    ---@class UI.BatchHandlers
    local batch ={}
    ---@param symbol string
    ---@param handlers GuiDefHandlers
    ---@return string
    batch.define = function (symbol,handlers)
        return ui.define_handlers(namespace..'-'..symbol,handlers)
    end
    return batch
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