--[[

    Minesweeper by engineer @ gamesensepub
    Minor fixes for gamesensevip compatibility  

]]

--=================================--
--            CONSTANTS            --
--=================================--
local gs_justify_left = "A"

local screen_width, screen_height = client.screen_size()
local mid_x, mid_y = screen_width / 2, screen_height / 2

--================================--
--              MENU              --
--================================--
-- No changes /Strawberry
local menu = {
    enabled      = ui.new_checkbox("LUA", gs_justify_left, "Minesweeper"),
    difficulty   = ui.new_combobox("LUA", gs_justify_left, "Difficulty", "Easy", "Medium", "Hard", "Custom"),
    rows         = ui.new_slider("LUA", gs_justify_left, "Rows", 1, 100, 16),
    columns      = ui.new_slider("LUA", gs_justify_left, "Columns", 1, 100, 30),
    mines        = ui.new_slider("LUA", gs_justify_left, "Mines", 1, 1000, 99),
    edit         = {
        enabled = ui.new_checkbox("LUA", gs_justify_left, "Settings"),
        reveal       = ui.new_hotkey("LUA", gs_justify_left, "Reveal tile", false, 0x01),
        flag         = ui.new_hotkey("LUA", gs_justify_left, "Flag tile", false, 0x02),
        tile_w  = ui.new_slider("LUA", gs_justify_left, "Tile width", 5, 100, 24, true, "px"),
        x       = ui.new_slider("LUA", gs_justify_left, "X", 0, screen_width, 300, true, "px"),
        y       = ui.new_slider("LUA", gs_justify_left, "Y", 0, screen_height, 200, true, "px")
    },
    reset
}

ui.set(menu.enabled, true)
ui.set(menu.difficulty, "Medium")

local function handle_menu()
    -- Main menu
    local enabled = ui.get(menu.enabled)
    ui.set_visible(menu.difficulty, enabled)
    ui.set_visible(menu.edit.enabled, enabled)

    if menu.reset ~= nil then
        ui.set_visible(menu.reset, enabled)
    end

    -- Difficulty
    local is_custom = ui.get(menu.difficulty) == "Custom"
    ui.set_visible(menu.rows, is_custom and enabled)
    ui.set_visible(menu.columns, is_custom and enabled)
    ui.set_visible(menu.mines, is_custom and enabled)

    -- Settings
    local is_edit_enabled = ui.get(menu.edit.enabled)
    ui.set_visible(menu.edit.reveal, is_edit_enabled and enabled)
    ui.set_visible(menu.edit.flag, is_edit_enabled and enabled)
    ui.set_visible(menu.edit.tile_w, is_edit_enabled and enabled)
    ui.set_visible(menu.edit.x, is_edit_enabled and enabled)
    ui.set_visible(menu.edit.y, is_edit_enabled and enabled)

end

ui.set_callback(menu.enabled, handle_menu)
ui.set_callback(menu.edit.enabled, handle_menu)
handle_menu()

--================================--
--          MINESWEEPER           --
--================================--
-- Generate map
local map = {}
local rows, columns, mines, flags, correct_flags, map_revealed, init_time, cur_time, difficulty
local reveals = 0
local game_state = 0  -- -1 lost, 0 in progress, 1 won

local map_x  = ui.get(menu.edit.x)
local map_y  = ui.get(menu.edit.y)
local tile_w = ui.get(menu.edit.tile_w)

local function generate_map()
    handle_menu() --  bro..... i putting this shits here because I cant doing ui.set_callback(menu.difficulty, handle_menu) and ui.set_callback(menu.difficulty, generate_map). IMPOSSIBLE!!!! / engineer@gs.pub
    
    -- Reset stats
    reveals = 0
    game_state = 0

    -- Generate tiles
    difficulty = ui.get(menu.difficulty)
    if difficulty == "Easy" then
        rows = 7
        columns = 10
        mines = 10
    elseif difficulty == "Medium" then
        rows = 12
        columns = 22
        mines = 40
    elseif difficulty == "Hard" then
        rows = 16
        columns = 30
        mines = 100
    else
        rows    = ui.get(menu.rows)
        columns = ui.get(menu.columns)
        mines   = ui.get(menu.mines)
    end

    for row = 1, rows do
        map[row] = {}
        for col = 1, columns do
            map[row][col] = {
                is_mine  = false,
                selected = false,
                revealed = false,
                flagged  = false,
                num      = nil
            }
        end
    end

    -- Insert mines
    local planted_mines = 0

    if mines > rows * columns then
        mines = rows * columns - 1
    end

    while planted_mines < mines do
        local row = client.random_int(1, rows)
        local col = client.random_int(1, columns)

        if not map[row][col].is_mine then
            map[row][col].is_mine = true
            planted_mines = planted_mines + 1
        end
    end

    -- Get the # of mines around each non-mine tile
    for row = 1, rows do
        for col = 1, columns do
            if not map[row][col].is_mine then
                map[row][col].num = 0
                for i = -1, 1 do
                    for j = -1, 1 do
                        if {i, j} ~= {0, 0} and row + i > 0 and row + i <= rows and col + j > 0 and col + j <= columns then
                            if map[row + i][col + j].is_mine then
                                map[row][col].num = map[row][col].num + 1
                            end
                        end
                    end
                end
            end
        end
    end

    -- Get initial time
    init_time = client.unix_time()
    cur_time  = client.unix_time()
end

generate_map()
ui.set_callback(menu.difficulty, generate_map)

-- Get selected tile
local selected_row, selected_col

local function get_selected_tile()
    local mx, my = ui.mouse_position()
    selected_col = math.floor((mx - map_x) / (tile_w + 1))
    selected_row = math.floor((my - map_y) / (tile_w + 1))

    for row = 1, rows do
        for col = 1, columns do
            map[row][col].selected = false
        end
    end

    if selected_row >= 1 and selected_row <= rows and selected_col >= 1 and selected_col <= columns then
        map[selected_row][selected_col].selected = true
        return map[selected_row][selected_col], selected_row, selected_col
    end
end

local function reveal_ms_tile(selected_row, selected_col)
    selected_tile = map[selected_row][selected_col]

    if not selected_tile.flagged then
        selected_tile.revealed = true

        local nearby_flagged = 0
        for i = -1, 1 do
            for j = -1, 1 do
                if {i, j} ~= {0, 0} and map[selected_row + i] ~= nil then
                    if map[selected_row + i][selected_col + j] ~= nil then
                        if map[selected_row + i][selected_col + j].flagged then
                            nearby_flagged = nearby_flagged + 1
                        end
                    end
                end
            end
        end

        if selected_tile.num == 0 or selected_tile.num == nearby_flagged then
            for i = -1, 1 do
                for j = -1, 1 do
                    if {i, j} ~= {0, 0} and map[selected_row + i] ~= nil then
                        if map[selected_row + i][selected_col + j] ~= nil and not map[selected_row + i][selected_col + j].flagged then
                            map[selected_row + i][selected_col + j].revealed = true
                        end
                    end
                end
            end
        end
    end
end

menu.reset = ui.new_button("LUA", gs_justify_left, "Reset", generate_map)

-- Main minesweeper function
local flag_key_state = ui.get(menu.edit.flag)
local old_flag_key_state = flag_key_state
local flag_state

local function minesweeper()
    if ui.get(menu.enabled) and ui.is_menu_open() then
        map_x  = ui.get(menu.edit.x)
        map_y  = ui.get(menu.edit.y)
        tile_w = ui.get(menu.edit.tile_w)

        -- User interactions
        local selected_tile, selected_row, selected_col = get_selected_tile()
        if selected_tile ~= nil and game_state == 0 then
            -- Reveal tile
            if ui.get(menu.edit.reveal) then
                reveal_ms_tile(selected_row, selected_col)

                for row = 1, rows do
                    for col = 1, columns do
                        if map[row][col].revealed and map[row][col].num == 0 then
                            reveal_ms_tile(row, col)
                        end
                    end
                end
            end

            -- Flag tile
            flag_key_state = ui.get(menu.edit.flag)

            if flag_key_state ~= old_flag_key_state then
                flag_state = not selected_tile.flagged
                old_flag_key_state = flag_key_state
            end
            
            if ui.get(menu.edit.flag) and not selected_tile.revealed and flags < mines then
                selected_tile.flagged = flag_state
            end

            -- Ensure first reveal isn't a mine
            if reveals == 0 then
                for row = 1, rows do
                    for col = 1, columns do
                        if map[row][col].revealed then
                            reveals = reveals + 1
                        end
                    end
                end
            end

            if reveals == 1 and selected_tile.num ~= 0 then
                generate_map()
            end
        end
        
        -- Win/lose conditions
        flags = 0
        correct_flags = 0
        map_revealed = true
        for row = 1, rows do
            for col = 1, columns do
                if map[row][col].flagged then
                    flags = flags + 1
                    if map[row][col].is_mine then
                        correct_flags = correct_flags + 1
                    end
                end

                if map[row][col].revealed and map[row][col].is_mine then
                    for i = 1, rows do
                        for j = 1, columns do
                            map[i][j].revealed = true
                        end
                    end
                    game_state = -1
                end

                if not map[row][col].revealed and not map[row][col].is_mine then
                    map_revealed = false
                end
            end
        end

        if map_revealed and correct_flags == mines then
            game_state = 1
        end

        --[[
        renderer.text(100, 100, 255, 255, 255, 255, nil, 0, "REVEALED: " .. tostring(map_revealed))
        renderer.text(100, 120, 255, 255, 255, 255, nil, 0, "FLAGS : " .. flags)
        renderer.text(100, 140, 255, 255, 255, 255, nil, 0, "CORRECT FLAGS: " .. correct_flags)
        renderer.text(100, 160, 255, 255, 255, 255, nil, 0, "STATE: " .. game_state)
        ]]

        -- Render background
        renderer.rectangle(map_x, map_y + 1, (columns + 2) * (tile_w + 1), (rows + 2) * (tile_w + 1), 0, 0, 0, 125)

        -- Render tiles
        for row = 1, rows do
            for col = 1, columns do
                local x = col * (tile_w + 1)
                local y = row * (tile_w + 1)
                local r, g, b, a = 255, 255, 255, 255
                local text = ""
                local flag = "bc"

                if map[row][col].revealed then
                    a = 175
                    if map[row][col].num ~= 0 then
                        if map[row][col].is_mine then
                            text = "BOOM!"
                            flag = "-c"
                            r, g, b = 255, 0, 0
                        else
                            text = map[row][col].num
                        end
                    end
                end

                if map[row][col].selected then
                    a = 100
                end

                if map[row][col].flagged then
                    r, g, b, a = 255, 255, 0, 150
                end

                renderer.rectangle(x + map_x, y + map_y, tile_w, tile_w, r, g, b, a)
                renderer.text(x + map_x + tile_w / 2 - 1, y + map_y + tile_w / 2 + 1, 0, 0, 0, 150, flag, 0, text)
                renderer.text(x + map_x + tile_w / 2 - 2, y + map_y + tile_w / 2, 255, 255, 255, 255, flag, 0, text)
                
            end
        end

        -- Header
        renderer.text(map_x + ((columns) * (tile_w + 1)) / 2 + tile_w + 1, map_y + tile_w / 2, 255, 255, 255, 255, "bc", (columns - 1) * (tile_w + 1), "Minesweeper by engineer")

        -- Amount of flags left
        renderer.text(map_x + tile_w, map_y + tile_w / 2 - 5, 255, 255, 255, 255, "b", 0, mines - flags)
        
        -- Timer
        if game_state == 0 and reveals ~= 0 then
            cur_time = client.unix_time()
        end
        -- [gamesense.vip] 5/21/2022 Strawberry: removed unnecessary self assigment

        local timer = cur_time - init_time
        local extrazero

        if timer % 60 < 10 then
            extrazero = "0"
        else
            extrazero = ""
        end
        
        local formatted_timer = string.format(
            "%i:%s%i", 
            math.floor(timer / 60),
            extrazero,
            timer % 60
        )

        renderer.text(map_x + (tile_w + 1) * (columns + 1), map_y + tile_w / 2 - 5, 255, 255, 255, 255, "br", 0, formatted_timer)

        -- Win/lose text
        local game_text, game_r, game_g, game_b
        if game_state == -1 then
            game_text = "You've lost!"
            game_r, game_g, game_b = 255, 0, 0
        elseif game_state == 1 then
            game_text = string.format("You've beaten %s difficulty in %s! (%ix%i, %i mines)", string.lower(difficulty), formatted_timer, columns, rows, mines)
            game_r, game_g, game_b = 0, 255, 0
        else
            game_text = ""
            game_r, game_g, game_b = 255, 255, 255
        end
        renderer.text(map_x + ((columns) * (tile_w + 1)) / 2 + tile_w + 1, map_y + (rows + 1.5) * (tile_w + 1), game_r, game_g, game_b, 255, "bc", 0, game_text)
    end
end

client.set_event_callback("paint_ui", minesweeper)