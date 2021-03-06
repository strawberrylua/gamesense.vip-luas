--
--
--	πΌπππ πππππ [ πππππππππ.πππ ]
--	πΏπππ’π π πππππ ππ π’πππ ππππππ π πππ πππππππ ππππ ππ-ππππ
--	
--	π°πππππ | πππππ πππππ’#πΏπΏπ½π·  | πππππ://ππππππ.πππ/πππππ πππππ’πππ
--	https://gamesense.vip/forums/profile.php?id=15
--	https://www.youtube.com/c/StrawberryHvH
--
--
local executed = false
local tab, container = 'CONFIG', 'Lua'

-- UI stuff
local ui_enabled = ui.new_checkbox(tab, container, 'Sound on menu open')
local ui_label = ui.new_label(tab, container, 'File name')
local ui_file = ui.new_textbox(tab, container, 'File name text box')

-- Main loop
local on_paint_ui = function()
	local enabled = ui.get(ui_enabled)

	if not enabled then return end
	
	local is_menu_open = ui.is_menu_open()
	local file = ui.get(ui_file)

	if is_menu_open then
		if not executed then
			client.exec(string.format('playvol %s 1', file))
			executed = true
		end
	else
		executed = false
	end
end

-- CB
client.set_event_callback('paint_ui', on_paint_ui)