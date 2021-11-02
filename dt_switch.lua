-- gamesense.vip | DT switch by Strawberry#9971
-- https://github.com/strawberrylua
-- https://www.youtube.com/channel/UC571plH1xJzVRPNjqdw5eKQ
local eventcb, ui_set, ui_ref = client.set_event_callback, ui.set, ui.reference
local dtmode = ui_ref("RAGE", "Other", "Double tap mode")
eventcb("setup_command", function (cmd)
    ui_set(dtmode, cmd.forwardmove == 0 and cmd.sidemove == 0 and "Defensive" or "Offensive")
end)
local double_tap, double_tap_key = ui.reference("RAGE", "Other", "Double tap")
local double_tap_mode = ui.reference("RAGE", "Other", "Double tap mode")
local double_tap_fake_lag_limit = ui.reference("RAGE", "Other", "Double tap fake lag limit")
local fake_lag = ui.reference("AA", "Fake lag", "Limit")
local sv_maxusrcmdprocessticks = ui.reference("MISC", "Settings", "sv_maxusrcmdprocessticks")
local increase_speed = ui.new_checkbox("RAGE", "Other", "Increase double tap speed")
local increase_speed_mode = ui.new_combobox("RAGE", "Other", "Increase double tap speed mode", {"Safe (Slower)", "Unsafe (Faster)"})

ui.set_visible(sv_maxusrcmdprocessticks, true)

local function do_shit()
	ui.set(fake_lag, math.min(14, ui.get(fake_lag)))

	if ui.get(increase_speed) then
		ui.set(double_tap, true)
		ui.set(double_tap_fake_lag_limit, 1)
		ui.set(double_tap_mode, "Offensive")
		
		if ui.get(increase_speed_mode) == "Unsafe (Faster)" then
			ui.set(sv_maxusrcmdprocessticks, 18)
			cvar.cl_clock_correction:set_int(0)
			return
		end
	end
	
	ui.set(sv_maxusrcmdprocessticks, 16)
	cvar.cl_clock_correction:set_int(1)
end

ui.set_callback(increase_speed, do_shit)
ui.set_callback(increase_speed_mode, do_shit)
ui.set_callback(fake_lag, do_shit)

client.set_event_callback("shutdown", function()
	ui.set(increase_speed, false)
	do_shit()
end)