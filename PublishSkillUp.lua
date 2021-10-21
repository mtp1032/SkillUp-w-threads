--------------------------------------------------------------------------------------
-- PublishSkillUp.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2020
local _, SkillUp = ...
SkillUp.PublishSkillUp = {}
pub = SkillUp.PublishSkillUp

local fileName = "PublishSkillUp.lua"

local E = errors
local L = SkillUp.L
local E = errors
local sprintf = _G.string.format
local DEBUG = E:isDebug()

local SIG_NONE          = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN        = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_WAKEUP        = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_NUMBER_OF     = timer.SIG_WAKEUP

local framePool = {}

local function createNewFrame()
  local f = CreateFrame( "Frame" )
  f.Text1 = f:CreateFontString("TrashHand")
  -- f.Text1:SetFont( "Interface\\Addons\\SkillUp\\Fonts\\ActionMan.ttf", 18 )
  f.Text1:SetFont( "Interface\\Addons\\SkillUp\\Fonts\\Bazooka.ttf", 18 )
  -- f.Text1:SetFont( "Interface\\Addons\\SkillUp\\Fonts\\SFWonderComic.ttf", 18 )


  f.Text1:SetWidth( 600 )
  f.Text1:SetJustifyH("LEFT")
  f.Text1:SetJustifyV("TOP")
  f.Text1:SetTextColor( 1.0, 1.0, 0.0 )
  f.Text1:SetText("")

  f.Text1:SetJustifyH("LEFT")
  f.Text1:SetJustifyV("TOP")
  f.Done = false
  f.TotalTicks = 0
  f.UpdateTicks = 2 -- Move the frame once every 2 ticks
  f.UpdateTickCount = f.UpdateTicks
  return f
end
local function initFramePool()
  local f = createNewFrame()
  table.insert( framePool, f )
end
local function releaseFrame( f )
  f.Text1:SetText("")
  table.insert( framePool, f )
end
local function acquireFrame()
  local f = table.remove( framePool )
  if f == nil then 
      f = createNewFrame() 
    end
    return f
end
initFramePool()

local Y_START_POS = -100
-- local X_START_POS = 300
local X_START_POS = 150

local function writeFloatingText( isSkillUp, logEntry )

  local clockInterval = mgmt:getClockInterval()
  local ScrollMax = (UIParent:GetHeight() * UIParent:GetEffectiveScale())/2 -- max scroll height

  local f = acquireFrame()

  f.Text1:SetText( logEntry )

    local yDelta = 2.0 -- move this much each update
    local xDelta = 0.0
    local yPos = Y_START_POS
    local xPos = X_START_POS

    if isSkillUp == false then
      yPos = Y_START_POS + 18
      xPos = X_START_POS
      xDelta = 0.0
    end

    f:ClearAllPoints()
    f.Text1:SetPoint("TOP", UIParent, xPos, yPos )
    f.Done = false

    f.TotalTicks = 0
    f.UpdateTicks = 4 -- Move the frame once every 4 ticks
    f.UpdateTickCount = f.UpdateTicks
    f:Show()
    f:SetScript("OnUpdate", 
  
          function(self, elapsed)
              self.UpdateTickCount = self.UpdateTickCount - 1
              if self.UpdateTickCount > 0 then
                return
              end

              self.UpdateTickCount = self.UpdateTicks
              self.TotalTicks = self.TotalTicks + 1
              
              if self.TotalTicks == 40 then f:SetAlpha( 0.8 ) end
              if self.TotalTicks == 50 then f:SetAlpha( 0.6 ) end
              if self.TotalTicks == 60 then f:SetAlpha( 0.4 ) end
              if self.TotalTicks == 70 then f:SetAlpha( 0.2 ) end
              if self.TotalTicks == 90 then f:SetAlpha( 0.1 ) end
              if self.TotalTicks >= 100 then 
                f:Hide()
                f.Done = true
              else
                yPos = yPos + yDelta
                xPos = xPos + xDelta
                f:ClearAllPoints()
                f.Text1:SetPoint("TOP", UIParent, xPos, yPos ) -- reposition the text to its new location
              end

            end)
            if f.Done == true then
              releaseFrame(f)
            end
end

-- This is the skillup thread's action routine
function pub:publishSkillUp()
  local signal = SIG_NONE
  while signal ~= SIG_RETURN do
    thread:yield()
    signal = thread:getSignal()
    if signal == SIG_WAKEUP then
      while handler:numChatEntries() > 0 do
        local isSkillUp, logEntry = handler:getChatEntry()
        writeFloatingText( isSkillUp, logEntry )
        E:dbgPrint( tostring( isSkillUp) .. ": " .. logEntry )
      end
    end
  end
  mf:postMsg( sprintf("publisherThread_h terminated.\n"))
end
if E:isDebug() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
