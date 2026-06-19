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
---@alias GuiDef LuaGuiElement.add_param | {children?: GuiDefUnresolvedChild[]} | {handlers?: string} | {on_created?:fun(e:LuaGuiElement)}

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
            if not (e.element and e.element.valid) then return end
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

---@param def GuiDef
---@return GuiDef
function ui.hi(def)
    return def
end

---@generic T
---@param t {integer:T}
---@param fn fun(index:integer,value:T):GuiDef?
---@return GuiDef[]
function ui.icollect(t,fn)
    local collect= {}
    for index, value in ipairs(t) do
        local result = fn(index,value)
        if result then
            table.insert(collect,result)
        end
    end
    return collect
end

ui.close_handler = ui.define_handlers("close", {
    [defines.events.on_gui_closed] = function(e)
        local player = game.players[e.player_index]
        e.element.destroy()
        player.opened = nil
    end
})
local close_button = ui.define_handlers("close_button",{
    [defines.events.on_gui_click] =function (e, tag)
        local player = game.players[e.player_index]
        e.element.parent.parent.destroy()
        player.opened = nil
    end
})
local config = require("config")
---@param title string
---@param children GuiDef[]
---@return GuiDef
function ui.window(title,children)
    return ui.hi{
        type = "frame",
        name = config.prefix "window",
        direction = "vertical",
        on_created = function (e)
            e.auto_center = true
        end,
        handlers = ui.close_handler,
        children = {
            {
                type = "flow",
                name = "titlebar",
                direction = "horizontal",
                on_created=function (e)
                    e.style.vertical_align = "center"
                    e.style.horizontal_spacing = 8
                end,
                children = {
                    {type = "label",caption = title,style = "frame_title",on_created=function (e)
                        e.ignored_by_interaction = true
                    end},
                    {type = "empty-widget",style = "draggable_space_header",
                    on_created=function (dragger)
                        dragger.style.horizontally_stretchable = true
                        dragger.style.minimal_height = 24
                        dragger.drag_target = dragger.parent.parent
                    end},
                    {
                        type = "sprite-button",
                        name = "my_gui_close_button",
                        style = "frame_action_button",
                        sprite = "utility/close",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        handlers = close_button
                    },
                }
            },
            {
                type = "frame",
                style = "inside_shallow_frame_with_padding",
                direction = "vertical",
                children = children
            }
        }
    }
end

return ui