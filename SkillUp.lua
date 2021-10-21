--------------------------------------------------------------------------------------
-- SkillUp.lua 
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 March, 2021

-- https://wowpedia.fandom.com/wiki/CHAT_MSG_COMBAT_XP_GAIN
-- https://wowpedia.fandom.com/wiki/API_GetCursorInfo
-- https://wowpedia.fandom.com/wiki/API_SetPortraitTexture
-- Example from Buttons.lua in Visual Threat Addon
-- function btn:updateButton( entry, button )
--     local unitId  = entry[ENTRY_UNIT_ID]
--     local name    = entry[ENTRY_UNIT_NAME]
--     local threat  = entry[ENTRY_THREAT_VALUE_RATIO]*100

--     SetPortraitTexture( button.Portrait, unitId )
--     button.Name:SetText( name )
--     local str = sprintf( "%d%%", threat )
--     button.Threat:SetText( str )
-- end



local _, SkillUp = ...
local fileName = "SkillUp.lua"

local E = errors
local L = SkillUp.L
local DEBUG = errors.DEBUG

local sprintf = _G.string.format

local SUCCESS   = errors.STATUS_SUCCESS
local FAILURE   = errors.STATUS_FAILURE
-----------------------------------------------------------------------------------------------------------
--                      The infoTable
-----------------------------------------------------------------------------------------------------------

--                      Indices into the infoTable table
local INTERFACE_VERSION = 1	-- string
local BUILD_NUMBER 		= 2		-- string
local BUILD_DATE 		= 3		-- string
local TOC_VERSION		= 4		-- number
local ADDON_C_NAME 		= 5		-- string

 -- Access WoWThreads signal interface
local SIG_NONE          = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN        = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_WAKEUP        = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_NUMBER_OF      = timer.SIG_WAKEUP

local publisherThread_h   = nil
local main_h = nil
local talonActive = false

local function main()
    -- local str = sprintf("[INFO] Control Thread created: thread id %d.\n", thread:getId( publisherThread_h))
	-- DEFAULT_CHAT_FRAME:AddMessage( str,1.0, 1.0, 0.0 )

    local result = {SUCCESS, nil, nil }
    local isValid = true

    ------------------------------------------------------------/reload
    -----
    -- Create the publisher thread, publisherThread_h
    -----------------------------------------------------------------
    local yieldInterval = mgmt:getClockInterval() * 12
    publisherThread_h, result = thread:create( yieldInterval, 
                                                function()
                                                pub:publishSkillUp()
                                                end)
    if publisherThread_h == nil then mf:postResult( result ) return end
    isValid, result = handler:setPublisherThread( publisherThread_h )
    if not isValid then mf:postResult( result ) return end  

    local str = sprintf("[INFO] Publisher Thread created: thread id %d.\n", thread:getId( publisherThread_h))
	DEFAULT_CHAT_FRAME:AddMessage( str, 1.0, 1.0, 0.0 )

    -- Wait for termination signal (SIG_RETURN)
    local signal = SIG_NONE
    while signal ~= SIG_RETURN do
        -- E:dbgPrint()
        thread:yield()
        signal, isValid, result = thread:getSignal()
        if not isValid then mf:postResult( result ) return end
    end
end

----------------------------------------------------------
-- Create the main thread. The publisher thread is created
-- inside the main thread's action routine.
----------------------------------------------------------
local yieldInterval = 2.0
main_h, result = thread:create( yieldInterval, main )
if main_h == nil then mf:postResult( result ) return end

SLASH_SKILLUP_COMMANDS1 = "/skillup"
SLASH_SKILLUP_COMMANDS2 = "/skill"

SlashCmdList["SKILLUP_COMMANDS"] = function( msg )
    local result = {SUCCESS, nil, nil }
    local errStr  = nil

    if msg == nil then
        -- errStr = sprintf("[UNKNOWN, NIL, OR INVALID SLASH COMMAND OPTION]\n\n")
		-- UIErrorsFrame:AddMessage( errStr, 1.0, 1.0, 0.0, 1, 20 )

        return
    end
    local msg = strupper( msg )

    if msg == "SUSPEND" then
        handler:suspend()


    elseif msg == "RESUME" then
            handler:resume()
    else
		local errStr = sprintf(L["UNKNOWN_OR_INVALID_SLASH_COMMAND_OPTION"])
		UIErrorsFrame:AddMessage( errStr, 1.0, 1.0, 0.0, 1, 20 )
    end
end

if E:isDebug() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end