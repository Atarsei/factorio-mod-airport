local math2d = require("math2d")

local utils = {}
function utils.manhattan_distance(pos1, pos2)
    return math.abs(pos1.x - pos2.x) + math.abs(pos1.y - pos2.y)
end

---@param offset Vector
---@param direction defines.direction
---@return Vector
function utils.rotate_offset_4way(offset, direction)
    offset = math2d.position.ensure_xy(offset)
    if direction == defines.direction.east then
        return { x = -offset.y, y = offset.x }
    elseif direction == defines.direction.south then
        return { x = -offset.x, y = -offset.y }
    elseif direction == defines.direction.west then
        return { x = offset.y, y = -offset.x }
    end
    return offset
end
---@param direction_by_north defines.direction
---@param direction defines.direction
---@return defines.direction
function utils.rotate_direction_4way(direction_by_north, direction)
    return (direction_by_north + direction) % 16
end
return utils