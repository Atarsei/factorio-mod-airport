local config = require("config")
local v = {
    filename = config.path "graphic/terminal/terminal_v.png",
    size = {  64 ,192},
    scale = 5/2
}
local h = {
    filename = config.path "graphic/terminal/terminal_h.png",
    size = { 192, 64 },
    scale = 5/2
}
return {
    north = h,
    east = v,
    south = h,
    west = v
}