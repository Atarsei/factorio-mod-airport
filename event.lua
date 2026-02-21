---@meta
---@diagnostic disable: lowercase-global

---@class EventManager
local event = {}

--- 存储每个事件对应的所有处理器
---@type table<defines.events|string|integer, function[]>
local handlers = {}

--- 存储每个事件当前生效的所有过滤器
---@type table<defines.events|string|integer, EventFilter[]>
local global_filters = {}

--- 合并两个过滤器数组
---@param old_filters? EventFilter[]
---@param new_filters? EventFilter[]
---@return EventFilter[]|nil
local function merge_filters(old_filters, new_filters)
    if not new_filters then return old_filters end
    if not old_filters then return new_filters end

    local merged = {}
    -- 复制旧过滤器
    for _, f in ipairs(old_filters) do table.insert(merged, f) end
    -- 追击新过滤器
    for _, f in ipairs(new_filters) do table.insert(merged, f) end
    
    return merged
end

--- 注册一个事件处理器，支持过滤器合并
---@alias event_type (LuaEventType)|((LuaEventType)[])
---@param event_id event_type
---@param handler fun(event: EventData)
---@param filters? EventFilter[]
function event.on_event(event_id, handler, filters)
    -- 处理数组形式的事件 ID (递归调用)
    if type(event_id) == "table" then
        for _, id in pairs(event_id) do
            event.on_event(id, handler, filters)
        end
        return
    end

    -- 1. 初始化处理器容器
    if not handlers[event_id] then
        handlers[event_id] = {}
    end
    table.insert(handlers[event_id], handler)

    -- 2. 合并过滤器逻辑
    local current_filters = global_filters[event_id]
    local next_filters = merge_filters(current_filters, filters)
    global_filters[event_id] = next_filters

    -- 3. 重新向引擎注册（覆盖之前的注册，应用合并后的过滤器）
    script.on_event(event_id, function(event_data)
        event.dispatch(event_id, event_data)
    end, next_filters)
end

--- 分发事件到所有已注册的处理器
---@param event_id event_type
---@param event_data EventData
function event.dispatch(event_id, event_data)
    local registered_handlers = handlers[event_id]
    if not registered_handlers then return end

    for _, handler in ipairs(registered_handlers) do
        local success, err = pcall(handler, event_data)
        if not success then
            -- 使用 Factorio 内置日志记录错误，防止静默失败
            log("Error in event handler for " .. tostring(event_id) .. ":\n" .. tostring(err))
        end
    end
end

return event