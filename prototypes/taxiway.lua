local config = require("config")
---@return data.Sprite
local function sp(name)
    return {
        filename = config.path "graphic/taxiway/" .. name .. ".png",
        size = { 64 * 3, 64 * 3 },
        scale = 1 / 2 / 3
    }
end
---@type data.PipePrototype
local taxiway = {
    type = "pipe",
    name = 'taxiway',
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    collision_box = { { -0.2, -0.2 }, { 0.2, 0.2 } },
    collision_mask = {
        layers = {}
    },
    fluid_box = {
        volume = 1,
        pipe_connections = {
            { position = { -0, 0 }, direction = defines.direction.west,  connection_category = "taxiway-pipe", },
            { position = { 0, 0 },  direction = defines.direction.east,  connection_category = "taxiway-pipe", },
            { position = { 0, -0 }, direction = defines.direction.north, connection_category = "taxiway-pipe", },
            { position = { 0, 0 },  direction = defines.direction.south, connection_category = "taxiway-pipe", },
        },
        hide_connection_info = true
    },
    horizontal_window_bounding_box = { { 0, 0 }, { 0, 0 } },
    vertical_window_bounding_box = { { 0, 0 }, { 0, 0 } },
    pictures = {
        straight_vertical_single = sp("single"),
        straight_vertical = sp("straight_v"),
        straight_vertical_window = sp("straight_v"),
        straight_horizontal = sp("straight_h"),
        straight_horizontal_window = sp("straight_h"),
        corner_up_right = sp("up_right"),
        corner_up_left = sp("up_left"),
        corner_down_right = sp("down_right"),
        corner_down_left = sp("down_left"),
        t_up = sp("t_up"),
        t_down = sp("t_down"),
        t_right = sp("t_right"),
        t_left = sp("t_left"),
        cross = sp("cross"),
        ending_up = sp("end_up"),
        ending_down = sp("end_down"),
        ending_right = sp("end_right"),
        ending_left = sp("end_left"),
    },
    minable = { mining_time = 0.2, result = "taxiway" },
    flags = { "player-creation" }
}

local taxiway3 = table.deepcopy(taxiway)
taxiway3.name = "taxiway3"
taxiway3.selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }
taxiway3.collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } }
taxiway3.fluid_box.pipe_connections[1].position = { -1, 0 }
taxiway3.fluid_box.pipe_connections[2].position = { 1, 0 }
taxiway3.fluid_box.pipe_connections[3].position = { 0, -1 }
taxiway3.fluid_box.pipe_connections[4].position = { 0, 1 }
for k, v in pairs(taxiway3.pictures) do
    v.scale = v.scale * 3
end
taxiway3.minable.result = "taxiway3"

data:extend {
    {
        type = 'item',
        name = 'taxiway',
        place_result = "taxiway",
        stack_size = 100,
        icon = config.path "graphic/taxiway/cross.png"
    },
    {
        type = 'item',
        name = 'taxiway3',
        place_result = "taxiway3",
        stack_size = 100,
        icon = config.path "graphic/taxiway/cross.png"
    },
    taxiway, taxiway3
}
