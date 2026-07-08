---@class Config
local config = {}

---@param name string
---@return string
function config.prefix(name)
    return 'Airport-' .. name
end
---@param name string
---@return string
function config.item(name)
    return name .. '-item'
end

config.name = {
    terminal = 'terminal', -- rename tower later
    terminal_tower = 'terminal-tower',
    terminal_container = "terminal-container",
    terminal_proxy = 'terminal-proxy',
    terminal_loader = "terminal-loader",
    terminal_sub = "terminal-sub",
    park = "park",
    terminal_connection = "terminal-connection",
    park_connection = "park-connection",
    taxiway_connection = "taxiway-connection"
}

config.color = {
    terminal = { r = 1, g = 1, b = 1 }
}

config.path = function (s)
    return '__airport__/'..s
end

for key, value in pairs(config.name) do
    config.name[key] = config.prefix(value)
end

---@param x number
---@return number
function config.airport_level(x)
    return math.floor(1.4*math.log(x+1,math.exp(1)))+3
end
return config