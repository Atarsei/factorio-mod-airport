local Event = require("event")
local config = require("config")
local math2d = require("math2d")
require("util")

---@class TerminalSub
---@field entity LuaEntity
---@field loader LuaEntity
---@field prev_group integer used for group seperate
local TerminalSub = {}
TerminalSub.__index = TerminalSub
script.register_metatable("TerminalSub", TerminalSub)

---@param entity LuaEntity?
---@return TerminalSub?
function TerminalSub.create(entity)
    if not (entity and entity.valid and entity.unit_number) then
        return nil
    end
    local self = setmetatable({}, TerminalSub)
    self.entity = entity
    local opposite_direction = util.oppositedirection(entity.direction)
    local opposite_vector = util.direction_vectors[opposite_direction]
    local loader = entity.surface.create_entity {
        name = config.prefix 'terminal-loader',
        position = math2d.position.add(entity.position, math2d.position.multiply_scalar(opposite_vector, 2)),
        force = entity.force,
        create_build_effect_smoke = false,
        direction = opposite_direction
    }
    if loader then
        self.loader = loader
    else
        return nil
    end
    storage.terminal_sub[entity.unit_number] = self
    self:register_on_group()
    return self
end

---@param tick MapTick
function TerminalSub:destroy(tick)
    self.loader.destroy()
    self:unregister_on_group(tick)
    storage.terminal_sub[self.entity.unit_number] = nil
    game.print(self.entity.unit_number .. " is destroyed")
end

---@param unit_number integer?
---@return TerminalSub?
function TerminalSub.get(unit_number)
    return storage.terminal_sub[unit_number]
end

---@return integer
function TerminalSub:get_group_id()
    ---@type integer not fluid wargon
    return self.entity.fluidbox.get_fluid_segment_id(1)
end

function TerminalSub:register_on_group()
    local id = self:get_group_id()
    group_insert(id, self.entity.unit_number)
    local neighbors = self.entity.fluidbox.get_connections(1)
    for _, value in ipairs(neighbors) do
        local neighbor = TerminalSub.get(value.owner.unit_number)
        if neighbor and neighbor.prev_group ~= id then
            group_merge(neighbor.prev_group, id)
        end
    end
end

function TerminalSub:unregister_on_group(tick)
    local id = self:get_group_id()
    group_remove(id, self.entity.unit_number)
    local neighbors = self.entity.fluidbox.get_connections(1)
    if #neighbors >= 2 then
        Event.next_tick(function (e)
            clean_dirty_group(id)
        end)
    end
end

---@class TerminalGroup
---@field arr {[integer]:boolean?}
---@field len number

---@param id integer
---@return TerminalGroup?
function group_get(id)
    local group = storage.terminal_group[id]
    return group
end
---@param id integer
function clean_dirty_group(id)
    local group = storage.terminal_group[id]
    if group then
        for unit_number, _ in pairs(group.arr) do
            local t = TerminalSub.get(unit_number)
            if t and t:get_group_id()~=id then
                group_remove(id,unit_number)
                group_insert(t:get_group_id(),unit_number)
            end
        end
    end
end

---@param id integer
---@param unit_number integer?
function group_insert(id, unit_number)
    local group = storage.terminal_group[id]
    if group and unit_number then
        group.arr[unit_number] = true
        group.len = group.len + 1
    else
        storage.terminal_group[id] = {
            arr = { [unit_number] = true },
            len = 1,
            dirty = 0
        }
    end
    TerminalSub.get(unit_number).prev_group = id
end

---@param id integer
---@param unit_number integer?
function group_remove(id, unit_number)
    local group = storage.terminal_group[id]
    if group and unit_number then
        group.arr[unit_number] = nil
        group.len = group.len - 1
        if group.len == 0 then
            storage.terminal_group[id] = nil
        end
    end
end

---@param id integer
---@return TerminalGroup?
function group_merge(id, target_id)
    local curr_group = storage.terminal_group[target_id]
    local prev_group =storage.terminal_group[id]
    assert(prev_group and curr_group)
    for key, _ in pairs(prev_group.arr) do
        curr_group.arr[key] = true
        TerminalSub.get(key).prev_group = target_id
    end
    curr_group.len = curr_group.len + prev_group.len
    storage.terminal_group[id] = nil
    return curr_group
end

Event.on_init(function()
    ---@type {[integer]:TerminalGroup?}
    storage.terminal_group = {}
    storage.terminal_sub = {}
end)

Event.entity(config.name.terminal_sub)
    .on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(event)
        ---@cast event EventData.on_built_entity|EventData.on_robot_built_entity
        local entity = event.entity
        TerminalSub.create(entity)
        game.print("id:" .. entity.fluidbox.get_fluid_segment_id(1))
    end)
    .on_event(
        { defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity },
        function(event)
            ---@cast event EventData.on_entity_died|EventData.on_player_mined_entity|EventData.on_robot_mined_entity
            local e = TerminalSub.get(event.entity.unit_number)
            if e then
                e:destroy(event.tick)
            end
        end)

Event.on_nth_tick(1, function(_)
    local color_list = { { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 1 }, { 1, 0, 0 }, { 0, 1, 0 } }
    for id, group in pairs(storage.terminal_group) do
        local color = color_list[id % #color_list + 1]
        for unit_number, _ in pairs(group.arr) do
            local e = TerminalSub.get(unit_number)
            assert(e)
            local pos = e.entity.position
            rendering.draw_rectangle {
                color = color,
                left_top = math2d.position.add(pos, { -2.5, -2.5 }),
                right_bottom = math2d.position.add(pos, { 2.5, 2.5 }),
                surface = e.entity.surface,
                time_to_live = 1,
                width = 10
            }
        end
    end
end)
