local config = require("config")
local h = {
    filename = config.path "graphic/runway/runway_h.png",
    size = {  64*5 ,64*5},
    scale = 1/2
}
local v = {
    filename = config.path "graphic/runway/runway_v.png",
    size = {  64*5 ,64*5},
    scale = 1/2
}
return {
    north = v,
    east = h,
    south = v,
    west = h
}