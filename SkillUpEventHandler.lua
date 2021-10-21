--------------------------------------------------------------------------------------
-- SkillUpEventHandler.lua 
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 March, 2021
local _, SkillUp = ...
SkillUp.SkillUpEventHandler = {}
handler = SkillUp.SkillUpEventHandler

local fileName = "SkillUpEventHandler.lua"

-- References
-- https://wowpedia.fandom.com/wiki/CHAT_MSG_LOOT
--https://wowpedia.fandom.com/wiki/CHAT_MSG_SKILL

local E = errors
local L = handler.L
local E = errors
local DEBUG = errors.DEBUG
local sprintf = _G.string.format

-- In all cases receipt of one of these signals queues the receiving thread
-- for immediate resumption (on the next tick)
local SIG_NONE          = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN        = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_WAKEUP        = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_NUMBER_OF     = timer.SIG_WAKEUP

local chatEntries = {}
local publisherThread_h = nil

local SUSPEND = false
function handler:suspend()
	SUSPEND = true
end
function handler:resume()
	SUSPEND = false
end
function handler:isSuspended()
	return SUSPEND
end

function handler:setPublisherThread( thread_h )
	local isValid = true
	local result = {SUCCESS, nil, nil}

	if thread_h == nil then 
		result = E:setResult( L["THREAD_HANDLE_NIL"], debugstack())
		return false, result
	end

	publisherThread_h = thread_h
	return isValid, result
end

	-- Remove the first table entry in the buffer table
-- Called by the publisher thread.
function handler:getChatEntry()
	if #chatEntries == 0 then return nil end

	-- removes the first element in the table.
    local entry = table.remove( chatEntries, 1)

	-- entry[1] is the boolean, isSkillUp, entry[2] is the text of the entry
	return entry[1], entry[2]
end

function handler:numChatEntries()
	-- E:dbgPrint()
	return #chatEntries
end

local function insertChatEntry( chatEntry, isSkillUp )
	local isValid = true
	local result = {SUCCESS, nil, nil}
	local entry = {isSkillUp, chatEntry}

	-- after insert, entry is the last element in the table
	table.insert( chatEntries, entry )

	-- signal the publisher thread that a chat entry string is ready for printing
	isValid, result = thread:sendSignal( publisherThread_h, SIG_WAKEUP )
	return isValid, result
end

local function OnEvent( self, event, ... )
	local arg1 = ...
	-- if handler:isSuspended() == true then return end

	if event == "CHAT_MSG_SKILL" then
		local isValid = insertChatEntry( arg1, true )
		if isValid == false then mf:postResult( result ) return end
	end
	if event == "CHAT_MSG_LOOT" then
		local isValid = insertChatEntry( arg1, false )
		if isValid == false then mf:postResult( result ) return end
	end
	-- "You harvest [Silverleaf]x3 increasing herbalism to 45"
	-- "You mine [Copper Ore]x3 increasing mining to 31"
	-- "You "
end 

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SKILL")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:SetScript( "OnEvent", OnEvent )


-------------------------------- END OF FILE -------------------------------------------
if E:isDebug() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
