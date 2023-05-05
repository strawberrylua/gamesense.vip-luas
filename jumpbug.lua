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
		⋆	https://gamesense.vip/forums/viewtopic.php?pid=7869
			© StrawberryHvH 2023
		
--]]
local vector, trace_hull, get_local_player, get_prop, tickinterval, band, floor, ui_get, ui_set, ui_reference, ui_newhotkey totime, vector2d = require("vector"), require("gamesense/trace").hull, entity.get_local_player, entity.get_prop, globals.tickinterval, bit.band, math.floor, ui.get(), ui.set(), ui.reference(), ui.new_hotkey(), totime, vector(1, 1, 0)


local bhop = ui_reference("MISC", "Movement", "Bunny hop")
local jumpbug_hotkey = ui_new_hotkey("MISC", "Movement", "Jumpbug")

local jumping_last = false
local jumpbugging = false
local was_on_ground = false

-- for our fall speed calculation
local sv_gravity = cvar.sv_gravity

-- a list of flags i'm using
-- you can find a full list of flags at https://gitlab.com/KittenPopo/csgo-2018-source/-/blob/main/public/const.h#L116
local FL = {
	ONGROUND = bit.lshift(1, 0)
}

-- returns two bools
-- is player currently on ground, will they be on ground within `t` ticks
local function ground_check(cmd, t)
	local local_player = get_local_player()

	-- if you don't know how this works, "m_fFlags" is a netprop which returns a bitflag
	-- google those terms.
	local flags = get_prop(local_player, "m_fFlags")
	local is_on_ground = band(flags, FL.ONGROUND) ~= 0

	-- if we're already on the ground, then we wouldn't be off the ground next tick unless we are jumping this tick
	if is_on_ground then
		return is_on_ground, cmd.in_jump == 1
	end

	-- get player position............ we can't do anything without this.
	local origin = vector(get_prop(local_player, "m_vecOrigin"))
	
	-- get player velocity so we can predict where we will be in a bit of time
	local velocity = vector(get_prop(local_player, "m_vecVelocity"))
	
	-- z axis unnecessary as we are not measuring anything above the players origin which is located at the bottom of the hitbox hence the * vector(1, 1, 0)
	-- (z is height)
	-- mins and maxs refer to our player hitbox "size"
	-- i could just inline +16 and -16 vectors but i believe it makes more sense to use the netprops instead
	local mins = vector(get_prop(local_player, "m_vecMins")) * vector2d
	local maxs = vector(get_prop(local_player, "m_vecMaxs")) * vector2d
	local predicted_pos = origin

	local sv_gravity = sv_gravity:get_float()
	
	-- basically applies our velocity and gravity
	local t = totime(t)
	local predicted_pos = origin + velocity * t
	predicted_pos.z = predicted_pos.z - 0.5 * sv_gravity * t ^ 2
	
	-- this mask is dogshit, and it prevents bench to bricks from being consistent
	-- why? i don't know. you'd think something called FLOORTRACE would mask anything you can stand on
	-- mask = "MASK_FLOORTRACE"
	
	-- this ray extrapolates on every axis
	local floor_collision = trace_hull(origin, predicted_pos, mins, maxs, { skip = local_player }).fraction
	-- this ray extrapolates on only the z axis
	local floor_collision_two = trace_hull(origin, vector(origin.x, origin.y, predicted_pos.z), mins, maxs, { skip = local_player }).fraction
	
	-- this ray extrapolates ignoring the z axis
	local wall_collision = trace_hull(origin, vector(predicted_pos.x, predicted_pos.y, origin.z), mins, maxs, { skip = local_player }).fraction

	-- these numbers (floor_collision and wall_collision) aren't 100% accurate so i needed to floor them, i think to the 0.001th unit is much more than enough
	-- basically check if our first floor check hit
		-- if so, compare the wall collision check to our floor check, and if they aren't the same, we'll be on the floor
		-- (prevents jumpbug from triggering when hitting a wall)
	-- otherwise check if our second floor check hit

	-- the first floor check supports uneven ground better when you're moving at a large velocity
	-- the second one is just to make sure we also check directly beneath the player in case we are hitting a wall

	return is_on_ground, floor_collision ~= 1 and (floor(floor_collision * 1000) ~= floor(wall_collision * 1000)) or floor_collision ~= 1 and floor_collision_two ~= 1
end


client.set_event_callback("setup_command", function(cmd)
	-- will be on ground in 2 ticks
	local is_on_ground, will_be_on_ground = ground_check(cmd, 2)

	-- currently in the air,
	-- predicted to be on the ground within the next 2 ticks,
	-- and we aren't already jumpbugging
	if is_on_ground == false and will_be_on_ground == true and jumpbugging == false then
		if ui_get(jumpbug_hotkey) then
			-- crouch this tick
			cmd.in_duck = 1

			-- don't crouch until we jump, and jump next tick
			jumpbugging = true
		end
	elseif jumpbugging then
		-- gamesense bhop always misses when we correctly "landbug"
		-- disable it and jump forcefully, then clear our jumpbug status
		ui_set(bhop, false)
		cmd.in_jump = 1
		jumpbugging = false
	else
		-- not jumpbugging, not going to jumpbug, so enable gs bhop
		ui_set(bhop, true)
	end

	
	-- sometimes our jumpbug jump doesn't land properly and our bhop re-enables while we have a jump input going out,
	-- this leaves us stuck on the ground because gamesense keeps attempting to jump, but if we have jump down two ticks in a row then we can't jump
	if was_on_ground and is_on_ground and cmd.in_jump == 1 and jumping_last == 1 then
		cmd.in_jump = 0
	end

	-- old vars to correct bhop not bhopping (read above)
	jumping_last = cmd.in_jump
	was_on_ground = is_on_ground
end)