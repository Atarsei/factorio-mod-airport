local config = require("config")
function placeholder(tilesize)
    local v= {
        filename = config.path "graphic/placeholder_v.png",
        size = { 64, 64 },
        scale = tilesize/2
    }
    local h= {
        filename = config.path "graphic/placeholder_h.png",
        size = { 64, 64 },
        scale = tilesize/2
    }
    return {
        north = v,
        east = h,
        south = v,
        west = h
    }
end

function sprite()
    
end