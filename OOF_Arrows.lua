-- https://github.com/strawberrylua
-- https://www.youtube.com/strawberryhvh
local menu = {"LUA", "A"}
local enable = ui.new_checkbox(menu[1], menu[2], "Enable Out-of-FOV Arrows")
local custom_color = ui.new_color_picker(menu[1], menu[2], "Arrow color", 50, 125, 255, 125)
local offscreen = ui.new_checkbox(menu[1], menu[2], "Only when out of fov")
local overlap = ui.new_checkbox(menu[1], menu[2], "Avoid overlapping indicators")

local lp = entity.get_local_player

local function includes(table, value)
    for i=1, #table do
        if table[i] == value then
            return true, i
        end
    end
    return false, -1
end

local function set_visible(state, ...)
    local table = {...}
    for i=1, #table do
        ui.set_visible(table[i], state)
    end
end

local function handle_gui()
    set_visible(ui.get(enable), custom_color, width, offscreen, overlap)
end
local function normalize_yaw( angle )
    angle = (angle % 360 + 360) % 360
    return angle > 180 and angle - 360 or angle
end
local function CalcAngle(x, y, ex, ey)
    local delta = { x - ex, y - ey }
    local yaw = math.atan( delta[2] / delta[1] )
    yaw = normalize_yaw( yaw * 180 / math.pi )
    if delta[1] >= 0 then
        yaw = normalize_yaw( yaw + 180 )
    end
    return yaw
end
-- render
local function draw_arrow(x, y, color, distance, angle, width, thickness)
    local camera = {client.camera_angles()}
    renderer.circle_outline(x, y, color[1], color[2], color[3], color[4], distance, camera[2] - angle - 120 + (width * 100)*4, width, thickness)
    return thickness + 1 --2 == padding
end

local screen = {client.screen_size()}
local center = {screen[1]/2, screen[2]/2}

local function off_screen(origin)
    local screen_pos = {renderer.world_to_screen(origin[1], origin[2], origin[3])}
    return (screen_pos[1] == nil or screen_pos[2] == nil) or screen_pos[2] >= screen[2] or screen_pos[1] < 0 or screen_pos[1] >= screen[1] or screen_pos[2] <= 0
end

local function clamp(min, max, value)
    if min < max then
        return math.min(max, math.max(min, value))
    else
        return math.min(min, math.max(max, value))
    end
end

local all_enemies = {}

for i=1, 64 do
    table.insert(all_enemies, i)
end


local function paint()
    handle_gui()
    -- Dead or alive??
    if lp() == nil and entity.is_alive(lp()) == false then
        return
    end
    if ui.get(enable) == false then
        return
    end

    local lp_origin = {entity.get_origin(lp())}

    local dormant_color = {50, 50, 50, clamp(125, 255, 125 + math.abs(math.sin(globals.realtime() * 2) * 125))}
    local color = {ui.get(custom_color)}

    local offset = 150
    -- Hardcodeeeeee.
    for i=1, #all_enemies do
        local ememy_origin = {entity.get_origin(all_enemies[i])}
        if ememy_origin[1] ~= nil and entity.is_alive(all_enemies[i]) and entity.is_enemy(all_enemies[i])  then
            local yaw = CalcAngle(lp_origin[1], lp_origin[2], ememy_origin[1], ememy_origin[2])
            
            local should_draw = true

            if ui.get(offscreen) then
                if off_screen(ememy_origin) == false then
                    should_draw = false
                end
            end

            if should_draw then
                --Enemy is dormant // draw different color
                if entity.is_dormant(all_enemies[i]) then
                    player_color = dormant_color
                end

                local thick = draw_arrow(center[1], center[2], color, offset, yaw, 0.05, 10)

                if ui.get(overlap) then
                    offset = offset + thick
                end
            end
        end
    end
end

client.set_event_callback("paint_ui", paint)
