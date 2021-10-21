--------------------------------------------------------------------------------------
-- Startup.lua 
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 March, 2021
local _, SkillUp = ...
SkillUp.Startup = {}
main = SkillUp.Startup

local fileName = "Startup.lua"

local E = errors
local L = SkillUp.L

local DEBUG = errors.DEBUG
local sprintf = _G.string.format

local SUCCESS   = errors.STATUS_SUCCESS
local FAILURE   = errors.STATUS_FAILURE

local function OnEvent( self, event, ... )
    local addonName = ...
    if event == "ADDON_LOADED" and addonName == "SkillUp" then
        timer:initDispatcher()
        DEFAULT_CHAT_FRAME:AddMessage( L["ADDON_LOADED_MESSAGE"], 1.0, 1.0, 0.0 )
    end

    return
end   

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript( "OnEvent", OnEvent )
    
if E:isDebug() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end