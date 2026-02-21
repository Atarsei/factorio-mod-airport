local airports = {}
local Airport = {}



function Airport.new(unit_number)
    local airport = {
        unit_number = unit_number,
        io = {},
    }
    airports[unit_number] = airport
    return airport
end

local demonds = {}
local supplys = {}



