local config = require("config")
local v = {
    filename = config.path "graphic/terminal/tower_v.png",
    size = {  64*5 ,64*15},
    scale = 1/2
}
local h = {
    filename = config.path "graphic/terminal/tower_h.png",
    size = { 64*15, 64*5 },
    scale = 1/2
}
return {
    north = h,
    east = v,
    south = h,
    west = v
}