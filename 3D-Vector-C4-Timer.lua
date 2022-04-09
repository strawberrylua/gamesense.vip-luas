--
--
--	𝟹𝙳 𝙲𝟺 𝚃𝚒𝚖𝚎𝚛 ― 𝚐𝚊𝚖𝚎𝚜𝚎𝚗𝚜𝚎.𝚟𝚒𝚙
--	𝘈 𝘭𝘶𝘢 𝘴𝘤𝘳𝘪𝘱𝘵 𝘪𝘯𝘥𝘪𝘤𝘢𝘵𝘪𝘯𝘨 𝘊4 𝘵𝘪𝘮𝘦 𝘶𝘯𝘵𝘪𝘭 𝘦𝘹𝘦𝘤𝘶𝘵𝘪𝘰𝘯 𝘥𝘳𝘢𝘸𝘯 3-𝘥𝘪𝘳𝘦𝘤𝘵𝘪𝘰𝘯𝘢𝘭 𝘶𝘴𝘪𝘯𝘨 𝘷𝘦𝘤𝘵𝘰𝘳𝘴
--	
--	𝙰𝚞𝚝𝚑𝚘𝚛 | 𝚂𝚝𝚛𝚊𝚠𝚋𝚎𝚛𝚛𝚢#𝟿𝟿𝟽𝟷  | 𝚑𝚝𝚝𝚙𝚜://𝚐𝚒𝚝𝚑𝚞𝚋.𝚌𝚘𝚖/𝚜𝚝𝚛𝚊𝚠𝚋𝚎𝚛𝚛𝚢𝚕𝚞𝚊
--	https://gamesense.vip/forums/profile.php?id=15
--	https://www.youtube.com/c/StrawberryHvH
--
--

local vector = require 'vector'

local clamp = function(x, min, max)
    return math.min(math.max(x, min), max)
end

local round = function(x, place)
    local m = 10 ^ (place or 0)
    return math.floor(x * m + 0.5) / m
end

local tab, container = 'LUA', 'A'
local interface = {
    enabled = ui.new_checkbox(tab, container, '3D C4 timer'),
    color = ui.new_color_picker(tab, container, 'C4 timer color', 210, 207, 205, 255),
    height = ui.new_slider(tab, container, 'Y offset', 0, 80, 40, true, 'px'),
    render = ui.new_slider(tab, container, 'Distance', 0, 1000, 800, true, 'u'),
    alpha = ui.new_checkbox(tab, container, 'Distance (Alpha)'),
}

local on_paint = function()
    local local_player = entity.get_local_player()
    local is_alive = entity.is_alive(local_player)

    if not local_player or not is_alive then
        return
    end

    local color = {ui.get(interface.color)}
    local height = ui.get(interface.height)
    local render = ui.get(interface.render)
    local alpha = ui.get(interface.alpha)

    local local_origin = vector(entity.get_prop(local_player, 'm_vecOrigin'))

    local c4_enumerate_plant = entity.get_all('CPlantedC4')
    for index, bomb in ipairs(c4_enumerate_plant) do
        if not bomb then
            goto skip
        end

        -- Resolve the origin
        local c4 = vector(entity.get_prop(bomb, 'm_vecOrigin'))
        
        -- Time?
        local c4_time = entity.get_prop(bomb, 'm_flC4Blow')
        
        -- Time left :slight_smile:
        local c4_time_left = c4_time - globals.curtime()
        
        -- Defused??
        local c4_defused = entity.get_prop(bomb, 'm_bBombDefused') == 1

        if c4_time_left < 0 or c4_defused then
            goto skip
        end

        -- distance
        local c4_dist = local_origin:dist(c4)

        -- render
        local x, y = renderer.world_to_screen(c4.x, c4.y, c4.z + height)

        -- hardcode22
        if x and y then
            local r, g, b, a = color[1], color[2], color[3], alpha and  clamp(255 - (c4_dist / render) * 255, 0, 255) or color[4]
            if c4_dist <= render then
                renderer.circle_outline(x, y - 5, 30, 30, 30, a, 20, 0, 100, 6)
                renderer.circle_outline(x, y - 5, r, g, b, a, 20 - 1, 0, c4_time_left / 40, 7 -3)
                renderer.text(x, y - 5, 255, 255, 255, a, 'c', 0, round(c4_time_left, 1))
            end
        end

        ::skip::
    end
end

local handle_callback = function(self)
    local handle = ui.get(self) and client.set_event_callback or client.unset_event_callback
    handle('paint', on_paint)
end

ui.set_callback(interface.enabled, handle_callback)
handle_callback(interface.enabled)
