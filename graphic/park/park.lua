local config = require("config")
return {
    north = {
        filename = config.path "graphic/park/parking_n.png",
        size = { 64 * 5, 64 * 5 },
        scale = 1 / 2
    },
    east = {
        filename = config.path "graphic/park/parking_e.png",
        size = { 64 * 5, 64 * 5 },
        scale = 1 / 2
    },
    south = {
        filename = config.path "graphic/park/parking_s.png",
        size = { 64 * 5, 64 * 5 },
        scale = 1 / 2
    },
    west = {
        filename = config.path "graphic/park/parking_w.png",
        size = { 64 * 5, 64 * 5 },
        scale = 1 / 2
    }
}
