local ORE_SWAP = '[color=128,206,240][Ore Swap][/color]'
local FRAME_NAME = 'ore_swap_gui_frame'

script.on_init(function()
    storage.selected_target = storage.selected_target or {}
end)

script.on_configuration_changed(function()
    storage.selected_target = storage.selected_target or {}
end)

-- Create or destroy the GUI panel
local function open_swap_gui(player)
    local screen = player.gui.screen
    if screen[FRAME_NAME] then
        return
    end

    local frame = screen.add {
        type = 'frame',
        name = FRAME_NAME,
        direction = 'vertical',
        caption = 'Ore Swap config',
    }
    -- Position near the top-left or center so it doesn't block the cursor while dragging
    frame.location = { x = 20, y = 80 }

    local flow = frame
        .add { type = 'frame', style = 'inside_shallow_frame_with_padding' }
        .add { type = 'flow', direction = 'horizontal' }
    flow.style.vertical_align = 'center'
    flow.add { type = 'label', caption = 'New resource: ' }

    local current_target = storage.selected_target[player.index]

    local elem_button = flow.add {
        type = 'choose-elem-button',
        name = 'ore_swap_elem_button',
        style = 'slot_button_in_shallow_frame',
        elem_type = 'entity',
        elem_filters = { { filter = 'type', type = 'resource' } },
    }

    if current_target and prototypes.entity[current_target] then
        elem_button.elem_value = current_target
    end
end

local function close_swap_gui(player)
    local frame = player.gui.screen[FRAME_NAME]
    if frame then
        frame.destroy()
    end
end

-- Automatically open the window when holding Ore Swap, and close it when put away
script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.players[event.player_index]
    local stack = player.cursor_stack

    if stack and stack.valid_for_read and stack.name == 'ore-swap' then
        open_swap_gui(player)
    else
        close_swap_gui(player)
    end
end)

-- Handle choose-elem-button change
script.on_event(defines.events.on_gui_elem_changed, function(event)
    if event.element and event.element.name == 'ore_swap_elem_button' then
        local player = game.players[event.player_index]
        local chosen_name = event.element.elem_value

        if chosen_name then
            storage.selected_target[player.index] = chosen_name
            local proto = prototypes.entity[chosen_name]
            player.print({ '', ORE_SWAP, ' target set to: ', proto.localised_name })
        else
            storage.selected_target[player.index] = nil
            player.print({ '', ORE_SWAP, ' target cleared.' })
        end
    end
end)

-- Perform the ore swap using the chosen target
script.on_event(defines.events.on_player_selected_area, function(event)
    local player = game.players[event.player_index]
    local item = event.item
    local entities = event.entities

    if item == 'ore-swap' then
        local target_ore = storage.selected_target[player.index]

        if not target_ore then
            player.print({ '', ORE_SWAP, ' [color=red]Please select a target ore first in the Ore Swap window![/color]' })
            return
        end

        for _, entity in ipairs(entities) do
            if entity.valid and entity.type == 'resource' then
                if entity.name ~= target_ore then
                    local amount = entity.amount
                    local position = entity.position
                    local surface = player.surface

                    entity.destroy()
                    surface.create_entity {
                        name = target_ore,
                        position = position,
                        amount = amount,
                    }
                end
            end
        end
    end
end)

script.on_event(defines.events.on_player_dropped_item, function(event)
    if event.entity ~= nil and event.entity.stack ~= nil then
        if event.entity.stack.name == 'ore-swap' then
            event.entity.stack.clear()
            close_swap_gui(game.players[event.player_index])
        end
    end
end)
