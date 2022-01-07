--	.88b  d88.  .d8b.  d888888b d8888b. d888888b db	db 
--	88'YbdP`88 d8' `8b `~~88~~' 88  `8D   `88'   `8b  d8' 
--	88  88  88 88ooo88	88	88oobY'	88	 `8bd8'  
--	88  88  88 88~~~88	88	88`8b	  88	 .dPYb.  
--	88  88  88 88   88	88	88 `88.   .88.   .8P  Y8. 
--	YP  YP  YP YP   YP	YP	88   YD Y888888P YP	YP 
--
--
--
-- Matrix Adaptive Weapons by Strawberry for https://gamesense.vip/
-- https://github.com/strawberrylua
-- https://www.youtube.com/strawberryhvh

local function depends()
	local csgo_weapons = require("vip/csgo_weapons")
end
if pcall(depends) == false then
	return error("[Matrix] Lua requires vip/csgo_weapons")
end

local csgo_weapons = require("vip/csgo_weapons")

local menu = {
	target_selection = ui.reference("RAGE", "Aimbot", "Target selection"),
	target_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox"),
	multi_point = {ui.reference("RAGE", "Aimbot", "Multi-point")},
	multi_pointscale = ui.reference("RAGE", "Aimbot", "Multi-point scale"),
	prefer_safe_points = ui.reference("RAGE", "Aimbot", "Prefer safe point"),
	force_safe_point = ui.reference("RAGE", "Aimbot", "Force safe point"),
	avoidunsafe = ui.reference("RAGE", "Aimbot", "Avoid unsafe hitboxes"),
	automatic_fire = ui.reference("RAGE", "Aimbot", "Automatic fire"),
	automatic_penetration = ui.reference("RAGE", "Aimbot", "Automatic penetration"),
	slient_aim = ui.reference("RAGE", "Aimbot", "Silent aim"),
	minimum_hit_chance = ui.reference("RAGE", "Aimbot", "Minimum hit chance"),
	minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),
	automatic_scope = ui.reference("RAGE", "Aimbot", "Automatic scope"),
	reduce_aim_step = ui.reference("RAGE", "Aimbot", "Reduce aim step"),
	max_fov = ui.reference("RAGE", "Aimbot", "Maximum FOV"),
	log_misses_due_to_spread = ui.reference("RAGE", "Aimbot", "Log misses due to spread"),
	remove_recoil = ui.reference("RAGE", "Other", "Remove recoil"),
	delay_shot = ui.reference("RAGE", "Other", "Delay shot"),
	quick_stop = {ui.reference("RAGE", "Other", "Quick stop")},
	quick_stop_options = ui.reference("RAGE", "Other", "Quick stop options"),
	quick_peek_assist = {ui.reference("RAGE", "Other", "Quick peek assist")},
	quick_peek_assist_color = ui.reference("RAGE", "Other", "Quick peek assist mode"),
	resolver = ui.reference("RAGE", "Other", "Anti-aim correction"),
	resolver_override = ui.reference("RAGE", "Other", "Anti-aim correction override"),
	prefer_body_aim = ui.reference("RAGE", "Other", "Prefer body aim"),
	prefer_body_aim_options = ui.reference("RAGE", "Other", "Prefer body aim disablers"),
	force_body_aim = ui.reference("RAGE", "Other", "Force body aim"),
	force_body_aim_on_peek = ui.reference("RAGE", "Other", "Force body aim on peek"),
	double_tap = {ui.reference("RAGE", "Other", "Double tap")},
	double_tap_mode = ui.reference("RAGE", "Other", "Double tap mode"),
	double_tap_hit_chance = ui.reference("RAGE", "Other", "Double tap hit chance"),
	double_tap_fake_lag_limit = ui.reference("RAGE", "Other", "Double tap fake lag limit"),
	double_tap_quick_stop = ui.reference("RAGE", "Other", "Double tap quick stop"),
	accuracy_boost = ui.reference("RAGE", "Other", "Accuracy boost"),
	duck_peek_assist = ui.reference("RAGE", "Other", "Duck peek assist"),
	on_shot_antiaim = {ui.reference("AA", "Other", "On shot anti-aim")},
	low_fps_mitigations = ui.reference("RAGE", "Aimbot", "Low FPS mitigations")
}	   

local screen = {client.screen_size()}
local center = {screen[1]/2, screen[2]/2} 

--ye
local lp = entity.get_local_player
local weapon_names = {}
local config = {}
local label = {}

local current_config = "Global"
local last_weapon = current_config
local time_of_last_change = 0

--Weapon things
local weapon_groups = {}

local add_weapon = function(namename, ...)
	table.insert(weapon_groups, {
		name = namename,
		weapons = {...}
	})
end

add_weapon("Global", nil)
add_weapon("Auto", 38, 11)
add_weapon("AWP", 9)
add_weapon("Scout", 40)
add_weapon("Revolver", 64)
add_weapon("Deagle", 1)
add_weapon("Pistol", 4, 63, 36, 3, 2, 30, 61, 32)
add_weapon("SMG", 17, 34, 33, 24, 26, 19)
add_weapon("Rifle & Heavy", 13, 10, 7, 16, 60, 39, 8, 14, 28)
add_weapon("Taser", 31)

--Get names
for i=1, #weapon_groups do
	table.insert(weapon_names, weapon_groups[i].name)
end

--UI
local master = ui.new_checkbox("RAGE", "Other", "Matrix adaptive weapon")
local active_config = ui.new_combobox("RAGE", "Other", "Manage configs", weapon_names)

--Config stuff
for i=1, #weapon_groups do
	local weapon_group = weapon_groups[i]
	local name = weapon_group.name

	config[i] = {
		name = name,
		enable = ui.new_checkbox("RAGE", "Other", "Enable: " .. name, false),
		target_selection = ui.new_combobox("RAGE", "Aimbot", "Target selection \n" .. name, {"Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance"}),
		target_hitbox = ui.new_multiselect("RAGE", "Aimbot", "Target hitbox \n" .. name, {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}),
		multi_point_hitbox = ui.new_multiselect("RAGE", "Aimbot", "Multi-point hitbox \n" .. name, {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}),
		multi_point_scale = ui.new_slider("RAGE", "Aimbot", "Multi-point scale \n" .. name, 24, 100, 70),
		prefer_safe_point = ui.new_checkbox("RAGE", "Aimbot", "Prefer safe point \n" .. name),
		avoidunsafe = ui.new_multiselect("RAGE", "Aimbot", "Avoid unsafe hitboxes \n" .. name, {"Head", "Chest", "Stomach", "Arms", "Legs"}),
		hit_chance = ui.new_slider("RAGE", "Aimbot", "Minimum hit chance \n" .. name, 0, 100, 50, true, "%"),
		damage = ui.new_slider("RAGE", "Aimbot", "Minimum damage \n" .. name, 0, 126, 25, true),
		accuracy_boost = ui.new_combobox("RAGE", "Other", "Accuracy boost \n" .. name, {"Off", "Low", "Medium", "High", "Maximum"}),
		delay_shot = ui.new_checkbox("RAGE", "Other", "Delay shot \n" .. name),
		quick_stop = ui.new_checkbox("RAGE", "Other", "Quick stop \n" .. name),
		quick_stop_options = ui.new_multiselect("RAGE", "Other", "Quick stop options \n" .. name, {"Early", "Slow motion", "Duck", "Fake duck", "Move between shots", "Ignore molotov"}),
		prefer_body_aim = ui.new_checkbox("RAGE", "Other", "Prefer body aim \n" .. name),
		prefer_body_aim_options = ui.new_multiselect("RAGE", "Other", "Prefer body aim options\n" .. name, {"Low inaccuracy", "Target shot fired", "Target resolved", "Safe point headshot", "Low damage"}),
		force_body_aim_on_peek = ui.new_checkbox("RAGE", "Other", "Force body aim on peek \n" .. name),
		double_tap = ui.new_checkbox("RAGE", "Other", "Double tap \n" .. name),
		double_tap_hit_chance = ui.new_slider("RAGE", "Aimbot", "double tap hit chance \n" .. name, 0, 100, 50, true, "%"),
		double_tap_quick_stop = ui.new_multiselect("RAGE", "Aimbot", "double tap quick stop \n" .. name, {"Slow motion", "Duck", "Move between shots"}),
		extra = ui.new_multiselect("RAGE", "Aimbot", "Extra options: " .. name, {"Noscope minimum hit chance", "Override minimum damage", "Override hitboxes", "Force body aim on lethal", "Force safepoint on lethal"}),
		noscope_hit_chance = ui.new_slider("RAGE", "Aimbot", "Noscope hit chance: " .. name, 0, 100, 40, true, "%"),
		override_damage = ui.new_slider("RAGE", "Aimbot", "Override minimum damage: " .. name, 0, 126, 40, true, ""),
		override_key = ui.new_hotkey("RAGE", "Aimbot", "Override key: " .. name, true),
		override_hitboxes = ui.new_multiselect("RAGE", "Aimbot", "Override hitboxes: " .. name, {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}),  
		override_hitboxes_key = ui.new_hotkey("RAGE", "Aimbot", "Override hitboxes key: " .. name, true),
		
		--ns
		last_noscope_state = false,
		ns_restored = true,

		--Md
		last_md_hotkey_state = false,
		md_restored = true,

		--hb
		last_hb_hotkey_state = false,
		hb_restored = true
	}
end

for i=1, #config do
	local weapon_group = weapon_groups[i]
	local name = weapon_group.name
	label[i] = {
		acitve_fig = ui.new_label("RAGE", "Other", "Current config: " .. name),
	}
end

local distance2d = function(point, point2)
	local delta = {point[1] - point2[1], point[2] - point2[2]}
	return math.sqrt((delta[1] * delta[1]) + (delta[2] * delta[2]))
end

local includes = function(table, key)
	for i=1, #table do
		if table[i] == key then
			return true, i
		end
	end
	return false, nil
end

local set_vis = function(state, ...)
	local table = {...}
	for i=1, #table do
		ui.set_visible(table[i], state)
	end
end

local is_noscoping = function(config)
	if lp() ~= nil and entity.is_alive(lp()) then
		if config == "Auto" or config == "Scout" or config == "AWP" then
			local scoped = entity.get_prop(lp(), "m_bIsScoped")
			return scoped == 0
		end
	end
	return false
end

--Pasted from smol (idc to make my own LOL) 
--Damn this code is smelly
local is_lethal = function(player)
	if lp() == nil or not entity.is_alive(lp()) then 
		return false
	end

	local local_origin = {entity.get_origin(lp())}
	local enemy_origin = {entity.get_origin(player)}
	local distance = distance2d(local_origin, enemy_origin)

	local enemy_health = entity.get_prop(player, "m_iHealth")

	local weapon_ent = entity.get_player_weapon(lp())
	if weapon_ent == nil then 
		return false
	end
	
	local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
	if weapon_idx == nil then 
		return false
	end
	
	local weapon = csgo_weapons[weapon_idx]
	if weapon == nil then 
		return false
	end

	local dmg_after_range = (weapon.damage * math.pow(weapon.range_modifier, (distance * 0.002))) * 1.25
	local armor = entity.get_prop(player,"m_ArmorValue")
	local newdmg = dmg_after_range * (weapon.armor_ratio * 0.5)
	if dmg_after_range - (dmg_after_range * (weapon.armor_ratio * 0.5)) * 0.5 > armor then
		newdmg = dmg_after_range - (armor / 0.5)
	end
	return newdmg >= enemy_health
end

local paint_ui = function()
	local master_g = ui.get(master)
	local active_config_g = ui.get(active_config)

	set_vis(master_g, active_config)

	if master_g then
		local weapon = entity.get_player_weapon(lp())
		if weapon ~= nil then
			local item_def_index = entity.get_prop(weapon, "m_iItemDefinitionIndex")
			if item_def_index then
				for i=1, #weapon_groups do
					local weapon_group = weapon_groups[i]
					local contains, i2 = includes(weapon_group.weapons, item_def_index)
					if contains and ui.get(config[i].enable) then
						current_config = weapon_group.name
						break
					else
						current_config = "Global"
					end
				end
			end
		else
			current_config = active_config_g
		end
	end

	if last_weapon ~= current_config then
		time_of_last_change = globals.tickcount()
		ui.set(active_config, current_config)
		last_weapon = current_config
	end 

	local active_indicators = {}

	local enemies = entity.get_players(true)

	for i=1, #config do
		local fig = config[i]

		set_vis(master_g and fig.name == active_config_g, fig.enable)
		set_vis(master_g and fig.name == current_config, fig.extra, label[i].acitve_fig)

		local extra_g = ui.get(fig.extra)
		set_vis(master_g and fig.name == current_config and includes(extra_g, "Noscope minimum hit chance"), fig.noscope_hit_chance)
		set_vis(master_g and fig.name == current_config and includes(extra_g, "Override minimum damage"), fig.override_damage, fig.override_key)
		set_vis(master_g and fig.name == current_config and includes(extra_g, "Override hitboxes"), fig.override_hitboxes, fig.override_hitboxes_key)

		set_vis(false, 
			fig.target_selection,
			fig.target_hitbox,
			fig.target_selection,
			fig.multi_point_hitbox,
			fig.multi_point_scale,
			fig.prefer_safe_point,
			fig.hit_chance,
			fig.damage,
			fig.accuracy_boost,
			fig.avoidunsafe,
			fig.delay_shot,
			fig.quick_stop,
			fig.quick_stop_options,
			fig.force_body_aim_on_peek,
			fig.double_tap,
			fig.double_tap_hit_chance,
			fig.double_tap_quick_stop,
			fig.prefer_body_aim,
			fig.prefer_body_aim_options
		)

		if master_g then
			-- hide
			if fig.name == "Global" then
				ui.set(fig.enable, true)
				ui.set_visible(fig.enable, false)
			end

			-- figs
			if fig.name == current_config then
				if #ui.get(fig.target_hitbox) == 0 then
					ui.set(fig.target_hitbox, {"Head"})
				end

				if #ui.get(fig.override_hitboxes) == 0 then
					ui.set(fig.override_hitboxes, {"Head"})
				end

				local ns_ovr = includes(extra_g, "Noscope minimum hit chance") and is_noscoping(fig.name)
				local md_ovr = includes(extra_g, "Override minimum damage") and ui.get(fig.override_key)
				local hb_ovr = includes(extra_g, "Override hitboxes") and ui.get(fig.override_hitboxes_key)

				if fig.last_noscope_state ~= ns_ovr then
					if ns_ovr == false then
						ui.set(menu.minimum_hit_chance, ui.get(fig.hit_chance))
						fig.ns_restored = true
					end
					fig.last_noscope_state = ns_ovr
				end
				if fig.last_md_hotkey_state ~= md_ovr then
					if md_ovr == false then
						ui.set(menu.minimum_damage, ui.get(fig.damage))
						fig.md_restored = true
					end
					fig.last_md_hotkey_state = md_ovr
				end
				if fig.last_hb_hotkey_state ~= hb_ovr then
					if hb_ovr == false then
						ui.set(menu.target_hitbox, ui.get(fig.target_hitbox))
						fig.hb_restored = true
					end
					fig.last_hb_hotkey_state = hb_ovr
				end

				-- render
				if time_of_last_change == globals.tickcount() then
					ui.set(menu.target_selection, ui.get(fig.target_selection))
					ui.set(menu.target_hitbox, ui.get(fig.target_hitbox))
					ui.set(menu.multi_point[1], ui.get(fig.multi_point_hitbox))
					ui.set(menu.multi_pointscale, ui.get(fig.multi_point_scale))
					ui.set(menu.prefer_safe_points, ui.get(fig.prefer_safe_point))
					ui.set(menu.minimum_hit_chance, ui.get(fig.hit_chance))
					ui.set(menu.minimum_damage, ui.get(fig.damage))
					ui.set(menu.accuracy_boost, ui.get(fig.accuracy_boost))
					ui.set(menu.delay_shot, ui.get(fig.delay_shot))
					ui.set(menu.avoidunsafe, ui.get(fig.avoidunsafe))
					ui.set(menu.quick_stop[1], ui.get(fig.quick_stop))
					ui.set(menu.quick_stop_options, ui.get(fig.quick_stop_options))
					ui.set(menu.prefer_body_aim, ui.get(fig.prefer_body_aim))
					ui.set(menu.prefer_body_aim_options, ui.get(fig.prefer_body_aim_options))
					ui.set(menu.force_body_aim_on_peek, ui.get(fig.force_body_aim_on_peek))
					ui.set(menu.double_tap[1], ui.get(fig.double_tap))
					ui.set(menu.double_tap_hit_chance, ui.get(fig.double_tap_hit_chance))
					ui.set(menu.double_tap_quick_stop, ui.get(fig.double_tap_quick_stop))
				else -- No? aight then save
					ui.set(fig.target_selection, ui.get(menu.target_selection))
					if hb_ovr then
						ui.set(menu.target_hitbox, ui.get(fig.override_hitboxes))
						fig.hb_restored = false
					elseif fig.hb_restored then
						ui.set(fig.target_hitbox, ui.get(menu.target_hitbox))
					end
					ui.set(fig.multi_point_hitbox, ui.get(menu.multi_point[1]))
					ui.set(fig.multi_point_scale, ui.get(menu.multi_pointscale))
					ui.set(fig.prefer_safe_point, ui.get(menu.prefer_safe_points))
					if ns_ovr then
						ui.set(menu.minimum_hit_chance, ui.get(fig.noscope_hit_chance))
						fig.ns_restored = false
					elseif fig.ns_restored then
						ui.set(fig.hit_chance, ui.get(menu.minimum_hit_chance))
					end
					if md_ovr then
						ui.set(menu.minimum_damage, ui.get(fig.override_damage))
						config[i].md_restored = false
					elseif config[i].md_restored then
						ui.set(fig.damage, ui.get(menu.minimum_damage))
					end

					if md_ovr then
						table.insert(active_indicators, "Min damage: " .. ui.get(fig.override_damage))
					end

					if ns_ovr then
						table.insert(active_indicators, "Noscope hitchance")
					end

					if hb_ovr then
						table.insert(active_indicators, "Hitbox override")
					end
					ui.set(fig.avoidunsafe, ui.get(menu.avoidunsafe))
					ui.set(fig.accuracy_boost, ui.get(menu.accuracy_boost))
					ui.set(fig.delay_shot, ui.get(menu.delay_shot))
					ui.set(fig.quick_stop, ui.get(menu.quick_stop[1]))
					ui.set(fig.quick_stop_options, ui.get(menu.quick_stop_options))
					ui.set(fig.prefer_body_aim, ui.get(menu.prefer_body_aim))
					ui.set(fig.prefer_body_aim_options, ui.get(menu.prefer_body_aim_options))
					ui.set(fig.force_body_aim_on_peek, ui.get(menu.force_body_aim_on_peek))
					ui.set(fig.double_tap, ui.get(menu.double_tap[1]))
					ui.set(fig.double_tap_hit_chance, ui.get(menu.double_tap_hit_chance))
					ui.set(fig.double_tap_quick_stop, ui.get(menu.double_tap_quick_stop))
				end

				client.update_player_list()

				for i=1, #enemies do 
					local enemy = enemies[i]
					local lethal = is_lethal(enemy)
					plist.set(enemy, "Override prefer body aim", (lethal and includes(extra_g, "Force body aim on lethal")) and "Force" or "-" )
					plist.set(enemy, "Override safe point", (lethal and includes(extra_g, "Force safepoint on lethal")) and "On" or "-" )
				end
			end
		end

		local offset = 50

		for i=1, #active_indicators do
			renderer.text(center[1], center[2] + offset, 220, 220, 220, 175, "", 0, active_indicators[i])
			offset = offset + 14
		end 
	end 
end

client.set_event_callback("paint_ui", paint_ui)