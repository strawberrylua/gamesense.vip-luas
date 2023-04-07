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
		⋆	https://gamesense.vip/forums/viewtopic.php?pid=7714
			© StrawberryHvH 2023
		
--]]
local steamworks = require "vip/steamworks"
local http = require "vip/http"
local ffi = require "ffi"
local ISteamMatchmaking = steamworks.ISteamMatchmaking
local GetClipboardTextCount = vtable_bind('vgui2.dll', 'VGUI_System010', 7, 'int(__thiscall*)(void*)')
local GetClipboardText = vtable_bind('vgui2.dll', 'VGUI_System010', 11, 'void(__thiscall*)(void*, int, const char*, int)')

local js = panorama['open']()
local myPersonaAPI = js['MyPersonaAPI']
local partyListAPI = js['PartyListAPI']
local lobbyAPI = js['LobbyAPI']
local friendListAPI = js['FriendsListAPI']

local a = {}

local P = panorama['loadstring']([[
    let _ActionInviteFriend = FriendsListAPI.ActionInviteFriend;
    let Invites = [];
    
    FriendsListAPI.ActionInviteFriend = (xuid)=>{
        if ( !LobbyAPI.CreateSession() ) {
            LobbyAPI.CreateSession();
            PartyListAPI.SessionCommand('MakeOnline', '');
        }
        Invites.push(xuid);
    };

    return {
        get: ()=>{
            let inviteCache = Invites;
            Invites = [];
            return inviteCache;
        },
        old: (xuid)=>{
            _ActionInviteFriend(xuid);
        },
        shutdown: ()=>{
            FriendsListAPI.ActionInviteFriend = _ActionInviteFriend;
        }
    }
]])()

-- #region UI Code

local isSpamEnabled = false
local isPrime = true
local isSpamCheckBoxActive = ui.new_checkbox('Lua', 'B', 'Enable Invite Spam')
local silentInvites = ui.new_checkbox('Lua', 'B', 'Silent Invites')
local spamDelay = ui.new_slider('Lua', 'B', 'Spam Delay', 1, 1000, 25, true, '', 1)
local idBox = ui.new_listbox('Lua', 'B', 'Steam IDs', a)
local removeButton = ui.new_button('Lua', 'B', 'Remove ID', function()
    if ui.get(idBox) >= 0 then
        local id = ui.get(idBox) + 1
        table.remove(a, id)
        ui.update(idBox, a)
    end
end)

-- #endregion

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

local function not_prime()
    isSpamEnabled = false
    for i = #a, 1, -1 do
        table.remove(a, i)
    end
    ui.update(idBox, a)
    error("Your account is not prime eligible!")
    return
end

local function GetClipboardData()
    local len = GetClipboardTextCount()
    if len > 0 then
        local buf = ffi.new('char[?]', len)
        local nText = len * ffi.sizeof('char[?]', len)

        GetClipboardText(0, buf, nText)

        local data = ffi.string(buf, len - 1)
        return data
    else
        return nil
    end
end

local function invitePlayer(xuid)
    local lobby = ISteamMatchmaking.GetLobbyID()
    if lobbyAPI.IsSessionActive() then
		if lobby ~= nil and xuid ~= nil then
			ISteamMatchmaking.InviteUserToLobby(lobby, xuid)
            if (not ui.get(silentInvites)) then
                partyListAPI.SessionCommand('Game::ChatInviteMessage',
                    string.format('run all xuid %s %s %s', myPersonaAPI.GetXuid(), 'friend', xuid))
            end
		end
    else
        if not isPrime then not_prime() return end
        lobbyAPI.CreateSession()
        partyListAPI.SessionCommand('MakeOnline', '')
        client.delay_call(0.1, invitePlayer, xuid)
    end
end

local function addUser(id)
    if id ~= nil then
        if not contains(a, id) and not lobbyAPI.IsPartyMember(id) then
            a[table.getn(a) + 1] = id
            client.log('Added ' .. id .. ' to spam!')
            ui.update(idBox, a)
        end
    end
end

local PasteButton = ui.new_button('Lua', 'B', 'Paste from clipboard', function()
    if not isPrime then not_prime() return end
    local ClipboardData = GetClipboardData()
    local id = ClipboardData
    if id ~= nil and #id == 17 then
        addUser(id)
    else
        local extension, min, max
        if string.match(string.lower(id), '.com/id/') then
            min, max = string.find(id, '.com/id/', 1, true)
            extension = string.gsub(string.sub(id, max + 1, #id), '%/', '')
        elseif string.match(string.lower(id), 'profiles/') then
            min, max = string.find(id, 'profiles/', 1, true)
            extension = string.gsub(string.sub(id, max + 1, #id), '%/', '')
        end
        if not extension then extension = id end
        http.get('https://steamidfinder.com/lookup/' .. extension, function(success, response)
            if not success or response.status ~= 200 then
                client.log('Invalid ID!')
                return
            end
            min, max = string.find(response.body, '<th scope="row">steamID64 (Dec):</th>', 1, true)
            id = string.sub(response.body, max + 32, max + 48)
            addUser(id)
        end)
    end
end)

local clearButton = ui.new_button('Lua', 'B', 'Clear invite queue', function()
    for i = #a, 1, -1 do
        table.remove(a, i)
    end
    ui.update(idBox, a)
    client.log('Cleared spam!')
end)

local startButton = ui.new_button('Lua', 'B', 'Start Spam invite', function()
    if not isPrime then not_prime() return end
    if not isSpamEnabled then
        client.log('Started spam!')
        isSpamEnabled = true
    end
end)

local abortButton = ui.new_button('Lua', 'B', 'Stop Spam invite', function()
    if isSpamEnabled then
        client.log('Stopped spam!')
        isSpamEnabled = false
    end
end)

client.set_event_callback('paint_ui', function()
    if lobbyAPI.GetHostSteamID() ~= "0" then
        if lobbyAPI.BIsHost() and not friendListAPI.GetFriendPrimeEligible(lobbyAPI.GetHostSteamID()) then
            isPrime = false
        end
    end
    if not ui.get(isSpamCheckBoxActive) then
        isSpamEnabled = false
    end
    ui.set_visible(silentInvites, ui.get(isSpamCheckBoxActive))
    ui.set_visible(spamDelay, ui.get(isSpamCheckBoxActive))
    ui.set_visible(idBox, ui.get(isSpamCheckBoxActive))
    ui.set_visible(PasteButton, ui.get(isSpamCheckBoxActive))
    ui.set_visible(clearButton, ui.get(isSpamCheckBoxActive) and ui.get(idBox) ~= nil)
    ui.set_visible(startButton, ui.get(isSpamCheckBoxActive) and ui.get(idBox) ~= nil and not isSpamEnabled)
    ui.set_visible(abortButton, ui.get(isSpamCheckBoxActive) and isSpamEnabled)
    ui.set_visible(removeButton, ui.get(isSpamCheckBoxActive) and ui.get(idBox) ~= nil)
    local Invites = P.get()
    for i = 0, Invites.length - 1 do
        if not isSpamEnabled then
            invitePlayer(Invites[i])
        end
        if not contains(a, Invites[i]) and not lobbyAPI.IsPartyMember(Invites[i]) then
            client.log('Added ' .. Invites[i] .. ' to spam!')
            a[table.getn(a) + 1] = Invites[i]
            ui.update(idBox, a)
        end
    end
end)

local function upd()
    for i = 1, table.getn(a) do
        local pl = a[i]
        if lobbyAPI.IsPartyMember(pl) then
            table.remove(a, i)
            ui.update(idBox, a)
        end
        if isSpamEnabled then
            invitePlayer(pl)
        end
    end
    if isPrime then
        client.delay_call(ui.get(spamDelay) / 100, upd)
    end
end

upd()

client.set_event_callback('shutdown', function()
    P.shutdown()
end)
