local config = require("config")
data:extend({
    {
        type = 'item',
        name = config.item(config.name.terminal_sub),
        icon = config.path 'graphic/placeholder_v.png',
        icon_size = 64,
        stack_size = 20,
        place_result = config.name.terminal_sub,
    },
    {
        type = 'fluid',
        name = config.name.terminal_connection,
        icon = config.path 'graphic/icon/connection_terminal.png',
        icon_size = 64,
        default_temperature = 0,
        base_color = config.color.terminal,
        flow_color = config.color.terminal
    },
    {
        type = 'fluid',
        name = config.name.lane_connection,
        icon = config.path 'graphic/icon/connection_lane.png',
        icon_size = 64,
        default_temperature = 0,
        base_color = config.color.terminal,
        flow_color = config.color.terminal
    },
    {
        type = "assembling-machine",
        name = config.name.terminal_sub,

        selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
        collision_box = { { -2.4, -2.4 }, { 2.4, 2.4 } },
        build_grid_size = 1,
        icon = config.path 'graphic/placeholder_v.png',
        tile_width = 5,
        tile_height = 5,
        energy_source = { type = "void" },
        energy_usage = "1W",
        crafting_categories = {"basic-crafting"},
        crafting_speed = 1,
        graphics_set = {
            animation = placeholder(5),
            animation_render_layer = "above-tiles"
        },
        fluid_boxes = {
            {
                volume = 1,
                production_type = "input",
                pipe_connections = {
                    { position = { -2, -1 }, direction = defines.direction.west,  connection_category = "terminal-pipe", },
                    { position = { -2, 2 },  direction = defines.direction.west,  connection_category = "terminal-pipe", },

                    { position = { 2, -1 },  direction = defines.direction.east,  connection_category = "terminal-pipe", },
                    { position = { 2, 2 },   direction = defines.direction.east,  connection_category = "terminal-pipe", },

                    { position = { -1, -2 }, direction = defines.direction.north, connection_category = "terminal-pipe", },
                    { position = { 1, -2 },  direction = defines.direction.north, connection_category = "terminal-pipe", },

                    { position = { 2, 2 },   direction = defines.direction.south, connection_category = "terminal-pipe", },
                    { position = { -2, 2 },  direction = defines.direction.south, connection_category = "terminal-pipe", },
                },
                pipe_covers = data.raw['pipe']['pipe'].fluid_box.pipe_covers,
                filter = config.name.terminal_connection
            },
            {
                volume =1,
                production_type = "output",
                pipe_connections = {
                    { position = { -2, 0 },  direction = defines.direction.west,  connection_category = "lane-pipe", },
                    { position = { 2, 0 },   direction = defines.direction.east,  connection_category = "lane-pipe", },
                    { position = { 0, -2 }, direction = defines.direction.north, connection_category = "lane-pipe", },
                }
            }
        },
        render_layer = "floor",
        flags = { "player-creation" },
        minable = { mining_time = 0.2, result = config.item(config.name.terminal_sub) },
    }
})
