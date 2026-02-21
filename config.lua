local config = {}
---comment
---@param name string
---@return string
function config.prefix(name)
    return 'Airport-' .. name
end
return config