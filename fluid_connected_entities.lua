local Event = require("event")
local config = require("config")
local math2d = require("math2d")

-- ============================================================================
-- 1. 基类：连通性网络管理器 (BaseManager)
-- 职责：只处理纯粹的图连通性、合并、分裂和缓存，不包含任何业务数据
-- ============================================================================

---@class Net
---@field arr {[integer]:FCE}
---@field len number

---@class BaseManager
---@field net table<integer, Net>
---@field lookup table<integer, FCE>
local BaseManager = {}
BaseManager.__index = BaseManager
script.register_metatable("fce_base_manager", BaseManager)

function BaseManager.new()
    local self = setmetatable({}, BaseManager)
    self.net = {}
    self.lookup = {}
    return self
end

---@param fce FCE
function BaseManager:insert(fce)
    local id = fce:get_group_id()
    ---@type integer
    local unit_number = fce.entity.unit_number
    local net = self.net[id]
    if net and unit_number then
        net.arr[unit_number] = fce
        net.len = net.len + 1
    else
        self.net[id] = {
            arr = { [unit_number] = fce },
            len = 1,
        }
    end
    self.lookup[unit_number] = fce
    fce.prev_group_id = id
end

---@param prev_id integer
---@param fce FCE
function BaseManager:remove(prev_id,fce)
    local net = self.net[prev_id]
    ---@type integer
    local unit_number = fce.entity.unit_number
    if net and unit_number then
        net.arr[unit_number] = nil
        net.len = net.len - 1
        if net.len == 0 then
            self.net[prev_id] = nil
        end
        self.lookup[unit_number] = nil
    end
end

---@param prev_id integer
---@param target_id integer
---@return Net
function BaseManager:merge(prev_id, target_id)
    local curr_group = self.net[target_id]
    local prev_group = self.net[prev_id]
    assert(prev_group and curr_group, "Merge failed: network ID not found.")

    for key, fce in pairs(prev_group.arr) do
        curr_group.arr[key] = fce
        fce.prev_group_id = target_id
    end
    curr_group.len = curr_group.len + prev_group.len
    self.net[prev_id] = nil
    return curr_group
end

---@param id integer
function BaseManager:clean_dirty(id)
    local net = self.net[id]
    if net then
        for unit_number, fce in pairs(net.arr) do
            if fce:get_group_id() ~= id then
                self:remove(id,fce)
                self:insert(fce)
            end
        end
    end
end

-- ============================================================================
-- 2. 子类：业务网络管理器 (BusinessManager)
-- 职责：继承 BaseManager，在图发生变化时，顺带处理专属的业务数据
-- ============================================================================

---@class TerminalManager : BaseManager
---@field tower table<integer,LuaEntity?>
local TerminalManager = {}
setmetatable(TerminalManager, { __index = BaseManager })
TerminalManager.__index = TerminalManager
script.register_metatable("fce_terminal_manager", TerminalManager)

---@return TerminalManager
function TerminalManager.new()
    ---@class TerminalManager
    local self = BaseManager.new() -- 初始化父类数据
    setmetatable(self, TerminalManager) -- 挂载子类元表
    self.tower = {} -- 子类专属的业务附加数据表
    return self
end

function TerminalManager:merge(prev_id, target_id)
    local merged_net = BaseManager.merge(self, prev_id, target_id)
    if self.tower[prev_id] then
        self.tower[target_id] = self.tower[prev_id]
        self.tower[prev_id] = nil
    end
    return merged_net
end

function TerminalManager:insert(fce)
    BaseManager.insert(self,fce)
    local id = fce:get_group_id()
    local prototype = fce.entity.prototype.name
    if prototype == config.name.terminal_tower and self.tower[id]==nil then
        self.tower[id] = fce.entity
    end
end

function TerminalManager:remove(prev_id,fce)
    BaseManager.remove(self,prev_id,fce)
    local prototype = fce.entity.prototype.name
    if prototype == config.name.terminal_tower and self.tower[prev_id] == fce.entity then
        self.tower[prev_id] = nil
    end
end


-- ============================================================================
-- 3. 全局生命周期与存储路由
-- ============================================================================

Event.on_init(function()
    ---@type table<string, BaseManager>
    storage.managers = {}
    -- 根据不同的流体 Filter，分配不同的管理器！
    -- 如果是普通管道流体，用基类；如果是特殊流体，用子类
    storage.managers[config.name.park_connection] = BaseManager.new()
    storage.managers[config.name.terminal_connection] = TerminalManager.new()
end)

-- ============================================================================
-- 4. 底层节点 (FCE)
-- 职责：作为一个极其纯粹的游离节点对象，提供对实体和管理器的快速访问
-- ============================================================================

---@class FCE
---@field entity LuaEntity
---@field fluidbox_idx number
---@field prev_group_id number?
local FCE = {}
FCE.__index = FCE
script.register_metatable("fluid_connected_entities", FCE)

---@return integer
function FCE:get_group_id()
    ---@type integer cause not flow wargon
    return self.entity.get_fluid_segment_id(self.fluidbox_idx)
end

--- 根据当前实体的 filter，自动找到归属的管理器实例
---@return BaseManager | TerminalManager
function FCE:get_manager()
    local proto = self.entity.get_fluid_box_prototype(self.fluidbox_idx)
    assert(proto and type(proto) ~= "table", "FCE prototype define can't handle multi fluid_box merge")
    local filter = proto.filter
    assert(filter, "FCE fluidbox must have filter define")

    local manager = storage.managers[filter.name]
    assert(manager, "No manager initialized for filter: " .. filter.name)
    return manager
end

---@param entity LuaEntity
---@param fluidbox_idx number
---@return FCE
function FCE.register(entity, fluidbox_idx)
    ---@type FCE
    local self = { entity = entity, fluidbox_idx = fluidbox_idx }
    setmetatable(self, FCE)

    local id = self:get_group_id()
    local manager = self:get_manager()
    manager:insert(self)

    local neighbors = self.entity.get_fluid_box_neighbours(self.fluidbox_idx)
    assert(neighbors)
    for _, value in ipairs(neighbors) do
        ---@type integer
        local unit_number = value.entity.unit_number
        local neighbor = manager.lookup[unit_number]

        if neighbor and neighbor.prev_group_id ~= id then
            manager:merge(neighbor.prev_group_id, id)
        end
    end
    return self
end

function FCE:unregister()
    local id = self:get_group_id()
    local manager = self:get_manager()
    manager:remove(id,self)
    local neighbors = self.entity.get_fluid_box_neighbours(self.fluidbox_idx)
    if #neighbors >= 2 then
        Event.next_tick(function(_)
            manager:clean_dirty(id)
        end)
    end
end

---@return number
function FCE:net_size()
    local id = self:get_group_id()
    local manager = self:get_manager()
    local net = manager.net[id]
    return net and net.len or 0
end

-- ============================================================================
-- 5. Debug 渲染循环 (已增加防御性校验)
-- ============================================================================

Event.on_nth_tick(1, function(_)
    local color_list = { { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 1 }, { 1, 0, 0 }, { 0, 1, 0 } }
    for fluid_name, manager in pairs(storage.managers) do
        for net_id, net in pairs(manager.net) do
            local color = color_list[net_id % #color_list + 1]
            for unit_number, fce in pairs(net.arr) do
                local entity = fce.entity
                if entity and entity.valid then
                    local pos = entity.position
                    local borderbox = entity.prototype.selection_box
                    rendering.draw_rectangle {
                        color = color,
                        left_top = math2d.position.add(pos, borderbox.left_top),
                        right_bottom = math2d.position.add(pos, borderbox.right_bottom),
                        surface = entity.surface,
                        time_to_live = 1,
                        width = 2,
                        only_in_alt_mode = true,
                    }
                end
            end
        end
    end
end)

return FCE