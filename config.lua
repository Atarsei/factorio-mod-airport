---@class Config
local config = {}

---@param name string
---@return string
function config.prefix(name)
    return 'Airport-' .. name
end


config.name = {
    terminal = 'terminal'
}

config.path = function (s)
    return '__airport__/'..s
end

for key, value in pairs(config.name) do
    config.name[key] = config.prefix(value)
end

return config