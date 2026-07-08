local config = require("config")
local x = {
    filename = config.path "graphic/terminal/sub.png",
    size = {  64*5 ,64*5},
    scale = 1/2
}
return {
    north = x,
    east = x,
    south = x,
    west = x
}