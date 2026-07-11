local config = require("config")
data:extend({
    {
        type = 'fluid',
        name = config.name.runway_connection,
        icon = config.path 'graphic/icon/connection_runway.png',
        icon_size = 64,
        default_temperature = 0,
        base_color = config.color.terminal,
        flow_color = config.color.terminal
    },
    {
        type = "assembling-machine",
        name = config.name.runway,

        selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } },
        collision_box = { { -2.4, -2.4 }, { 2.4, 2.4 } },
        collision_mask = {
            layers = { transport_belt = true }
        },
        build_grid_size = 1,
        icon = config.path 'graphic/placeholder_v.png',
        tile_width = 5,
        tile_height = 5,
        energy_source = { type = "void" },
        energy_usage = "1W",
        crafting_categories = { "crafting" },
        crafting_speed = 1,
        graphics_set = {
            working_visualisations = {
                {
                    render_layer = "floor",
                    north_animation = require("graphic.runway.runway").north,
                    east_animation = require("graphic.runway.runway").east,
                    south_animation = require("graphic.runway.runway").south,
                    west_animation = require("graphic.runway.runway").west,
                    always_draw = true
                }
            }
        },
        fluid_boxes = {
            {
                volume = 1,
                production_type = "input",
                pipe_connections = {
                    { position = { 0, -2 }, direction = defines.direction.north, connection_category = "runway-pipe" },
                    { position = { 0, 2 },  direction = defines.direction.south, connection_category = "runway-pipe" },
                },
                filter = config.name.runway_connection
            },
            {
                volume = 1,
                production_type = "input",
                pipe_connections = {
                    { position = { -2, 0 }, direction = defines.direction.west, connection_category = "taxiway-pipe", flow_direction = "input" },
                    { position = { 2, 0 },  direction = defines.direction.east, connection_category = "taxiway-pipe", flow_direction = "input" },
                },
                filter = config.name.taxiway_connection
            },
        },
        integration_patch_render_layer = "floor",
        flags = { "player-creation" },
        minable = { mining_time = 0.2, result = config.name.runway },
    },
    {
        type = 'item',
        name = config.name.runway,
        icon = config.path 'graphic/placeholder_v.png',
        icon_size = 64,
        stack_size = 20,
        place_result = config.name.runway,
    },
})
