require("placeholder")
local config = require("config")
data:extend({
    {
        type = 'simple-entity-with-owner',
        name = config.prefix 'block5',
        selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
        collision_box = {{-2.4, -2.4}, {2.4, 2.4}},
        build_grid_size =  1,
        icon = config.path 'graphic/placeholder_v.png',
        tile_width = 5,
        tile_height = 5,
        picture = placeholder(5)
    },
    {
        type = 'item',
        name = config.prefix'block5-item',
        icon = config.path 'graphic/placeholder_v.png',
        icon_size = 64,
        stack_size = 20,
        place_result = config.prefix 'block5'
    },
    {
        type = 'constant-combinator' ,
        name = config.name.terminal,
        selection_box = {{-7.5, -2.5}, {7.5, 2.5}},
        collision_box = {{-7.4, -2.4}, {7.4, 2.4}},
        build_grid_size =  1,
        icon = config.path 'graphic/placeholder_v.png',
        tile_width = 15,
        tile_height = 5,
        sprites = require('graphic.terminal.index'),
        activity_led_light_offsets = data.raw['constant-combinator']['constant-combinator'].activity_led_light_offsets,
        circuit_wire_connection_points = data.raw['constant-combinator']['constant-combinator'].circuit_wire_connection_points,
        render_layer = "floor",
        flags = {"player-creation"},
        minable = {mining_time = 0.2, result = config.prefix 'terminal-item'}
    },
    {
        type = 'item',
        name = config.name.terminal..'-item',
        icon = config.path 'graphic/terminal/terminal_h.png',
        icon_size = 64,
        stack_size = 20,
        place_result = config.prefix 'terminal'
    },
    {
        type = 'loader-1x1',
        name = config.name.terminal..'-loader',
        icon = config.path 'graphic/placeholder_v.png',
        icon_size = 64,
        picture = placeholder(1),
        speed = 15/480,
        filter_count = 1,
        collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_mask = {
            layers={transport_belt=true}
        },
        belt_animation_set = data.raw['loader']['loader'].belt_animation_set,
        animation_speed_coefficient = data.raw['loader']['loader'].animation_speed_coefficient,
        allow_container_interaction = true,
        container_distance = 1,
        selection_priority = 51
    },
    {
        type = 'container',
        name = config.name.terminal..'-container',
        icon = config.path 'graphic/placeholder_v.png',
        icon_size = 64,
        picture = {
            filename = config.path 'graphic/placeholder_v.png',
            size = { 64, 64 },
            scale = 1/2
        },
        inventory_size = 10,
        collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_mask = {
            layers={}
        },
        flags = {"player-creation"},
        selection_priority = 51
    }
})