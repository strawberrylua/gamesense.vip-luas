--
--
--	𝙼𝚎𝚗𝚞 𝚂𝚘𝚞𝚗𝚍 [ 𝚐𝚊𝚖𝚎𝚜𝚎𝚗𝚜𝚎.𝚟𝚒𝚙 ]
--	𝙿𝚕𝚊𝚢𝚜 𝚊 𝚜𝚘𝚞𝚗𝚍 𝚘𝚏 𝚢𝚘𝚞𝚛 𝚌𝚑𝚘𝚒𝚌𝚎 𝚠𝚑𝚎𝚗 𝚘𝚙𝚎𝚗𝚒𝚗𝚐 𝚖𝚎𝚗𝚞 𝚒𝚗-𝚐𝚊𝚖𝚎
--	
--	𝙰𝚞𝚝𝚑𝚘𝚛 | 𝚂𝚝𝚛𝚊𝚠𝚋𝚎𝚛𝚛𝚢#𝟿𝟿𝟽𝟷  | 𝚑𝚝𝚝𝚙𝚜://𝚐𝚒𝚝𝚑𝚞𝚋.𝚌𝚘𝚖/𝚜𝚝𝚛𝚊𝚠𝚋𝚎𝚛𝚛𝚢𝚕𝚞𝚊
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