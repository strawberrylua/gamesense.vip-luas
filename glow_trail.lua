--[[
									       
									       
                                                                      _        
                                                                     (_)       
   __ _   __ _  _ __ ___    ___  ___   ___  _ __   ___   ___  __   __ _  _ __  
  / _` | / _` || '_ ` _ \  / _ \/ __| / _ \| '_ \ / __| / _ \ \ \ / /| || '_ \ 
 | (_| || (_| || | | | | ||  __/\__ \|  __/| | | |\__ \|  __/ _\ V / | || |_) |
  \__, | \__,_||_| |_| |_| \___||___/ \___||_| |_||___/ \___|(_)\_/  |_|| .__/ 
   __/ |                                                                | |    
  |___/                                                                 |_|    
									       
									       
									       
	https://github.com/strawberrylua/gamesense.vip-luas			
	https://www.youtube.com/@StrawberryHvH					
	https://discord.gamesense.vip/						
										
--]]
local ffi = require "ffi"
local vector = require "vector"
local masterSwitch, m_vecPrevPoint = ui.new_checkbox("VISUALS", "Effects", "Enable glow trail"), nil

local menu = {
    rainbow = ui.new_checkbox("VISUALS", "Effects", "RGB glow trail"),
    color = ui.new_color_picker("VISUALS", "Effects", "Enable glow trail", 255, 9, 11, 255)
}

local sigGlowObjectManager = client.find_signature("client.dll", "\xA1\xCC\xCC\xCC\xCC\xA8\x01\x75\x4B") or error("client.dll!::GlowObjectManager couldn't be found. Signature is outdated.")
local sigAddGloxBox = client.find_signature("client.dll", "\x55\x8B\xEC\x53\x56\x8D") or error("client.dll!::AddGlowBox couldn't be found. Signature is outdated.")
local n_glowObjectManager = ffi.cast("void*(__cdecl*)()", sigGlowObjectManager)
local n_addGlowBox = ffi.cast("int(__thiscall*)(void*, Vector, Vector, Vector, Vector, unsigned char[4], float)", sigAddGloxBox) -- @ void* GlowObjectManager, Vector BoxPosition, Vector Direction, Vector Mins, Vector Maxs, unsigned char[4] Colour, float Duration

local init = function(CTX)
    local localPlayer = entity.get_local_player()
    if not localPlayer or not entity.is_alive(localPlayer) then return end
    
    local color = ffi.cast("unsigned char**", ffi.new("unsigned char[4]", ui.get(menu.color)))[0]

    if ui.get(menu.rainbow) then
        local rt = globals.realtime() * 0.2 * 3
        local val = rt % 3
        local r, g, b = math.abs(math.sin(val + 4))*255, math.abs(math.sin(val + 2))*255, math.abs(math.sin(val))*255
        color = ffi.cast("unsigned char**", ffi.new("unsigned char[4]", { r, g, b, 255}))[0]
    end

    local m_vecPoint = vector(entity.get_origin(localPlayer))
    local m_flThickness = 0.25

    if not m_vecPrevPoint then m_vecPrevPoint = m_vecPoint end

    local m_vecTemporaryOrientation = (m_vecPrevPoint - m_vecPoint)
    local m_angTrajectoryAngles = vector(m_vecTemporaryOrientation:angles())

    local m_vecMin = vector(0, -m_flThickness, -m_flThickness)
    local m_vecMax = vector(m_vecTemporaryOrientation:length(), m_flThickness, m_flThickness)

    local velocity = vector(entity.get_prop(localPlayer, "m_vecVelocity"))

    if velocity:length2d() > 2 then
        n_addGlowBox(n_glowObjectManager(), m_vecPoint, m_angTrajectoryAngles, m_vecMin, m_vecMax, color, 1)
    end

    m_vecPrevPoint  = m_vecPoint
end

local ui_callback = function(self)
    local enabled = ui.get(self)
    local updatecallback = enabled and client.set_event_callback or client.unset_event_callback

    updatecallback("setup_command", init)
end

ui.set_callback(masterSwitch, ui_callback)
ui_callback(masterSwitch)