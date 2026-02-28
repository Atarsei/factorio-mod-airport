---@class EventManager
local event = {}
--- 存储每个事件对应的所有处理器
---@type table<LuaEventType, function[]>
local handlers = {}

---@alias event_type (LuaEventType)|((LuaEventType)[])

--- 分发事件到所有已注册的处理器
---@param event_id event_type
---@param event_data EventData
function event.dispatch(event_id, event_data)
    local registered_handlers = handlers[event_id]
    if not registered_handlers then return end

    for _, handler in ipairs(registered_handlers) do
        handler(event_data)
    end
end

---@type table<LuaEventType,EventFilter>
local global_filter = {}
---@type table<LuaEventType,true?>
local filters_disable = {}

---@param event_id event_type
---@param handler fun(event: EventData)
---@param filters? EventFilter
function event.on_event(event_id, handler, filters)
    if type(event_id) == "table" then
        for _, id in pairs(event_id) do
            event.on_event(id, handler,filters)
        end
        return
    end

    local require_update_event = false

    if not handlers[event_id] then
        handlers[event_id] = {}
        require_update_event = true
    end
    table.insert(handlers[event_id], handler)

    if not filters_disable[event_id] then
        if filters then
            local old_filters = global_filter[event_id] or {}
            for _, value in ipairs(filters) do
                table.insert(old_filters,value)
            end
            global_filter[event_id] = old_filters
        else
            filters_disable[event_id] = true
            global_filter[event_id]=nil
        end
        require_update_event = true
    end

    if require_update_event then
        script.on_event(event_id, function(event_data)
            event.dispatch(event_id, event_data)
        end,global_filter[event_id])
    end
end

--- Should only call once for each prototype name
---@param name string
function event.entity(name)
    ---@class Event.Entity
    local entity = {}
    --- event_data must have "entity" | "destination"  field
    ---@param event_id event_type
    ---@param handler fun(event: EventData)
    entity.on_event = function (event_id,handler)
        event.on_event(event_id,function (e)
            ---@cast e EventData.on_built_entity | EventData.on_pre_entity_settings_pasted
            local entity_name = (e.entity and e.entity.name) or (e.destination and e.destination.name)
            if entity_name and entity_name == name then
                handler(e)
            end
        end,{{filter="name",name=name}})
        return entity
    end
    entity.ghost = function ()
        ---@class Event.Ghost
        local ghost = {}
        --- event_data must have "ghost" field
        ---@param event_id event_type
        ---@param handler fun(event: EventData)
        ghost.on_event = function (event_id,handler)
            event.on_event(event_id,function (e)
                ---@cast e EventData.on_pre_ghost_deconstructed
                local entity_name = e.ghost and e.ghost.ghost_name
                if entity_name and entity_name == name then
                    handler(e)
                end
            end,{{filter="ghost",name = name}})
            return ghost
        end
    end
    return entity
end

return event