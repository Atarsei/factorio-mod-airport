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

---@alias GuiDefHandlers table<GuiEvents,fun(event: GuiEventData)?>
---@alias GuiDef LuaGuiElement.add_param | {children: GuiDef[]} | {handlers: GuiDefHandlers}|{style:LuaStyle}

local event = require("event")
local ui = {}

---@type table<string,GuiDef>
local ui_defs = {}
---@type table<string,true?>
local name_unique_checker = {}

---@param def GuiDef
local function register_handlers(def)
    if def.handlers then
        local name = def.name
        if not name then
            error("UI definition must have a name to register handlers.")
        end
        if name_unique_checker[name] then
            error("UI element name: '" .. name .. "' already has handlers registered.")
        else
            name_unique_checker[name] = true
        end
        for event_id, handler in pairs(def.handlers) do
            event.on_event(event_id, function (e)
                ---@cast e GuiEventData
                -- 安全检查：某些 GUI 事件可能没有 element 或 element 已失效
                if e.element and e.element.valid and e.element.name == name then
                    handler(e)
                end
            end)
        end
        def.handlers = nil
    end

    if def.children then
        for _, child_def in ipairs(def.children) do
            register_handlers(child_def)
        end
    end
end

---@param name string
---@param def GuiDef
function ui.define(name, def)
    if ui_defs[name] then
        error("UI definition '" .. name .. "' already exists.")
    end
    def.name = name
    ui_defs[name] = def
    register_handlers(def)
end



---@param def GuiDef
---@param parent LuaGuiElement
---@return LuaGuiElement
local function create_element(def, parent)
    local element = parent.add(def)

    -- 递归创建子元素
    if def.children then
        for _, child_def in ipairs(def.children) do
            create_element(child_def, element)
        end
    end

    return element
end

---@param name string
---@param parent LuaGuiElement
---@return LuaGuiElement
function ui.create(name, parent)
    local def = ui_defs[name]
    if not def then
        error("UI definition '" .. name .. "' not found.")
    end
    return create_element(def, parent)
end

return ui