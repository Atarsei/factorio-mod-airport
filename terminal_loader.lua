local event = require("event")
local config = require("config")
local ui = require("ui")
local math2d = require("math2d")
local utils = require("utils")

---@class TerminalLoader
local TerminalLoader = {}

local choose_filter = ui.define_handlers("choose_filter", {
    [defines.events.on_gui_click] = function(e, tag)
        ---@cast tag {slot_index:number,unit_number:integer}
        local index = tag.slot_index
        local loader = storage.terminal_loader[tag.unit_number]
        local airport = loader.owner:get_airport()
        if airport then
            if index == 0 then
                loader.con.proxy_target_entity = nil
                goto close_ui
            end
            local slot = airport.slots[index]
            loader.con.proxy_target_entity = slot.container
            loader.con.proxy_target_inventory = defines.inventory.chest
        end
        ::close_ui::
        game.players[e.player_index].opened = nil
    end
})

event.entity(config.name.terminal_loader)
    .on_event(defines.events.on_gui_opened, function(e)
        ---@cast e EventData.on_gui_opened
        local player = game.get_player(e.player_index)
        if player then
            player.opened = nil

            local airport = TerminalLoader.get_airport(e.entity)
            if airport then
                player.opened = ui.create(player.gui.screen, ui.window("filter", { {
                    type = 'flow',
                    direction = "horizontal",
                    children = {
                        ui.icollect(airport.slots, function(index, value)
                            local slot_name = value.item
                            if slot_name then
                                return ui.hi({
                                    type = "sprite-button",
                                    sprite = "item/" .. slot_name.name,
                                    quality = slot_name.quality,
                                    tags = { unit_number = e.entity.unit_number, slot_index = index },
                                    handlers = choose_filter
                                })
                            end
                        end),
                        {
                            type = "sprite-button",
                            sprite = "utility/crafting_machine_recipe_not_unlocked",
                            tags = { unit_number = e.entity.unit_number, slot_index = 0 },
                            handlers = choose_filter
                        }
                    }
                } }))
            end
        end
    end)

event.on_init(function()
    ---@type table<integer,{owner:TerminalLoaderOwner,con:LuaEntity}>
    storage.terminal_loader = {}
end)

---@param owner TerminalLoaderOwner
---@param pos Vector
---@param direction defines.direction
---@return LuaEntity
function TerminalLoader.create(owner, pos, direction)
    pos = utils.rotate_offset_4way(pos, owner.entity.direction)
    direction = utils.rotate_direction_4way(direction, owner.entity.direction)

    local opposite_direction = util.oppositedirection(direction)
    local opposite_vector = util.direction_vectors[opposite_direction]
    local proxy_con_pos = math2d.position.add(pos, opposite_vector)

    local loader = owner.entity.surface.create_entity {
        name = config.name.terminal_loader,
        position = math2d.position.add(owner.entity.position, pos),
        force = owner.entity.force,
        create_build_effect_smoke = false,
        direction = direction
    }
    local con = owner.entity.surface.create_entity {
        name                      = config.name.terminal_proxy,
        position                  = math2d.position.add(owner.entity.position, proxy_con_pos),
        force                     = owner.entity.force,
        create_build_effect_smoke = false,
    }
    assert(loader and con)
    --- as input first
    loader.rotate()
    storage.terminal_loader[loader.unit_number] = { owner = owner, con = con }
    return loader
end

---@param entity LuaEntity
function TerminalLoader.destroy(entity)
    storage.terminal_loader[entity.unit_number].con --[[@as LuaEntity]].destroy()
    storage.terminal_loader[entity.unit_number] = nil
    entity.destroy()
end

---@param entity LuaEntity
---@return Airport?
function TerminalLoader.get_airport(entity)
    local unit_number = entity.unit_number
    assert(unit_number)
    local loader = storage.terminal_loader[unit_number]
    return loader.owner:get_airport()
end

---@class TerminalLoaderOwner
---@field entity LuaEntity
---@field loaders LuaEntity[]
---@field get_airport fun(self:TerminalLoaderOwner):Airport?

return TerminalLoader
