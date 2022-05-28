--[[
		                                                                       _        
		                                                                      (_)       
		  __ _   __ _  _ __ ___    ___  ___   ___  _ __   ___   ___    __   __ _  _ __  
		 / _` | / _` || '_ ` _ \  / _ \/ __| / _ \| '_ \ / __| / _ \   \ \ / /| || '_ \ 
		| (_| || (_| || | | | | ||  __/\__ \|  __/| | | |\__ \|  __/ _  \ V / | || |_) |
		 \__, | \__,_||_| |_| |_| \___||___/ \___||_| |_||___/ \___|(_)  \_/  |_|| .__/ 
		  __/ |                                                                  | |    
		 |___/                                                                   |_|    
		
		
		⋆	https://github.com/strawberrylua
		⋆	https://www.youtube.com/c/StrawberryHvH
		⋆	https://gamesense.vip/forums/profile.php?id=15

			© StrawberryHvH 2022
--]]

local vector = require "vector"

local entity = require "vip/entity"
local images = require "vip/images"

local enable = ui.new_checkbox("Visuals", "Player ESP", "LC flag")
local color = ui.new_color_picker("Visuals", "Player ESP", "LC flag", 158, 74, 0)

local style = ui.new_multiselect("Visuals", "Player ESP", "\n", "Text", "Icon")

local raw_file_content = readfile("danger.svg") or error("Could not find the file 'danger.svg' in your CS:GO directory.")
local danger_image = images.load_svg(raw_file_content) 

local ESP_TEXT = "BREAKING LC"
local esp_flag_set = false

local data = {}

local function time_to_ticks(t)
    return math.floor(0.5 + (t / globals.tickinterval()))
end

local function contains(table, val)
	for i=1,#table do
		if table[i] == val then
			return true
		end
	end
	return false
end

local function on_net_update_end (c)
    for _, player in ipairs(entity.get_players(true)) do
        local sim_time = time_to_ticks(player:get_prop("m_flSimulationTime"))
        local ent_index = player:get_entindex()

        local origin = vector(player:get_origin())

        local player_data = data[ent_index]

        if player_data == nil then
            data[ent_index] = {
                last_sim_time = sim_time,
                defensive_active_until = 0,
                origin = origin
            }
        else
            local delta = sim_time - player_data.last_sim_time
    
            if delta < 0 then
                player_data.defensive_active_until = globals.tickcount() + math.abs(delta)
            elseif delta > 0 then
                player_data.breaking_lc = (player_data.origin - origin):length2dsqr() > 4096
                player_data.origin = origin
            end
    
            player_data.last_sim_time = sim_time    
        end
    end
end

local function on_paint ()
    local tickcount = globals.tickcount()
    local draw_color = {ui.get(color)}
    local styles = ui.get(style)

    for _, player in ipairs(entity.get_players(true)) do 
        local player_data = data[player:get_entindex()]
        if player_data and (player_data.breaking_lc or tickcount <= player_data.defensive_active_until)  then
            local x1, y1, x2, y2, alpha = player:get_bounding_box()

            if alpha ~= 0 then
                local draw_x, draw_y = x1 + ((x2 - x1) / 2), y1

                if contains(styles, "Text") then
                    renderer.text(draw_x, draw_y - 20, draw_color[1], draw_color[2], draw_color[3], draw_color[4] * alpha, "dc", 0, ESP_TEXT)    
                end

                if contains(styles, "Icon") then
                    local text_width, _ = renderer.measure_text("dc", player:get_player_name())
                    local size = 16

                    danger_image:draw(draw_x + text_width / 2 + 2, draw_y - size, size, size)
                end
            end
        end
    end
end


local function reset_data ()
    data = {}
end

local function handle_esp_flag (idx) 
    if not ui.get(enable) or data[idx] == nil then return false end

    local idx_data = data[idx]

    return globals.tickcount() <= idx_data.defensive_active_until or idx_data.breaking_lc
end


ui.set_callback(enable, function(e)
    local enabled = ui.get(e)
    local callback = enabled and client.set_event_callback or client.unset_event_callback

    callback("net_update_end", on_net_update_end)
    callback("round_prestart", reset_data)

    if not esp_flag_set then
        client.register_esp_flag("LC", 158, 74, 0, handle_esp_flag)
        esp_flag_set = true
    end

    ui.set_visible(style, enabled)
end)


ui.set_callback(style, function(e)
    local styles = ui.get(e)
    local callback = #styles == 0 and client.unset_event_callback or client.set_event_callback

    callback("paint", on_paint)
end)