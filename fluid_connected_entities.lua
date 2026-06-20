local Event = require("event")
local config = require("config")
local math2d = require("math2d")

Event.on_init(function()
    ---@type table<string,FluidGroups<any>?>
    storage.fce_group = {}
    for _, value in ipairs({ config.name.terminal_connection, config.name.lane_connection }) do
        storage.fce_group[value] = {
            net = {}, lookup = {}
        }
    end
end)

---@class Net
---@field arr {[integer]:FCE}
---@field len number
local Group = {}
---@generic T
---@alias FluidGroups<T> {net:table<integer,Net?>,lookup:table<integer,FCE>,data:T}

---@generic T
---@class FCE<T>
---@field entity LuaEntity
---@field fluidbox_idx number
---@field prev_group_id number?
local FCE = {}
FCE.__index = FCE
script.register_metatable("fluid_connected_entities", FCE)

---@return integer
function FCE:get_group_id()
    ---@type integer cause not flow wargon
    return self.entity.fluidbox.get_fluid_segment_id(self.fluidbox_idx)
end

---@return FluidGroups<T>
function FCE:get_fluid_groups()
    local proto = self.entity.fluidbox.get_prototype(self.fluidbox_idx)
    assert(type(proto) ~= "table", "FCE prototype define can't handle multi fluid_box merge")
    local filter = proto.filter
    assert(filter, "FCE fluidbox must have filter define")
    return storage.fce_group[filter.name]
end

---@param entity LuaEntity
---@param fluidbox_idx number
---@return FCE
function FCE.register(entity, fluidbox_idx)
    ---@type FCE
    local self = { entity = entity, fluidbox_idx = fluidbox_idx }
    setmetatable(self, FCE)
    local id = self:get_group_id()
    local groups = self:get_fluid_groups()
    Group.insert(groups, id, self.entity.unit_number, self)
    local neighbors = self.entity.fluidbox.get_connections(1)
    for _, value in ipairs(neighbors) do
        ---@type integer
        local unit_number = value.owner.unit_number
        local neighbor = groups.lookup[unit_number]
        if neighbor and neighbor.prev_group_id ~= id then
            Group.merge(groups, neighbor.prev_group_id, id)
        end
    end
    return self
end

function FCE:unregister()
    local id = self:get_group_id()
    local groups = self:get_fluid_groups()
    Group.remove(groups, id, self.entity.unit_number)
    local neighbors = self.entity.fluidbox.get_connections(1)
    if #neighbors >= 2 then
        Event.next_tick(function(e)
            Group.clean_dirty(groups, id)
        end)
    end
end

---@return number
function FCE:net_size()
    local id = self:get_group_id()
    local groups = self:get_fluid_groups()
    return Group.get(groups, id).len
end

---@param groups FluidGroups<any>
---@param id integer
---@return Net
function Group.get(groups, id)
    return groups.net[id]
end

---@param groups FluidGroups<any>
---@param id integer
function Group.clean_dirty(groups, id)
    local net = groups.net[id]
    if net then
        for unit_number, fce in pairs(net.arr) do
            if fce:get_group_id() ~= id then
                Group.remove(groups, id, unit_number)
                Group.insert(groups, fce:get_group_id(), unit_number, fce)
            end
        end
    end
end

---@param groups FluidGroups<any>
---@param id integer
---@param unit_number integer
---@param fce FCE
function Group.insert(groups, id, unit_number, fce)
    local net = groups.net[id]
    if net and unit_number then
        net.arr[unit_number] = fce
        net.len = net.len + 1
    else
        groups.net[id] = {
            arr = { [unit_number] = fce },
            len = 1,
        }
    end
    groups.lookup[unit_number] = fce
    fce.prev_group_id = id
end

---@param groups FluidGroups<any>
---@param id integer
---@param unit_number integer?
function Group.remove(groups, id, unit_number)
    local net = groups.net[id]
    if net and unit_number then
        net.arr[unit_number] = nil
        net.len = net.len - 1
        if net.len == 0 then
            groups.net[id] = nil
        end
        groups.lookup[unit_number] = nil
    end
end

---@param groups FluidGroups<any>
---@param id integer
---@return Net
function Group.merge(groups, id, target_id)
    local curr_group = groups.net[target_id]
    local prev_group = groups.net[id]
    assert(prev_group and curr_group)
    for key, _ in pairs(prev_group.arr) do
        curr_group.arr[key] = prev_group.arr[key]
        curr_group.arr[key].prev_group_id = target_id
    end
    curr_group.len = curr_group.len + prev_group.len
    groups.net[id] = nil
    return curr_group
end

Event.on_nth_tick(1, function(_)
    local color_list = { { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 1 }, { 1, 0, 0 }, { 0, 1, 0 } }
    for fluid_name, groups in pairs(storage.fce_group) do
        for net_id, net in pairs(groups.net) do
            local color = color_list[net_id % #color_list + 1]
            for unit_number, fce in pairs(net.arr) do
                local entity = fce.entity
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
end)



return FCE
