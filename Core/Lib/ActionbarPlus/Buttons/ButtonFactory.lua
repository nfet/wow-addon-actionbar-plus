local _G = _G
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert
local unpack, pack, fmod = table.unpackIt, table.pack, math.fmod
local AssertThatMethodArgIsNotNil = Assert.AssertThatMethodArgIsNotNil
local CreateFrame, UIParent, SECURE_ACTION_BUTTON_TEMPLATE = CreateFrame, UIParent, SECURE_ACTION_BUTTON_TEMPLATE
local GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show = GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show
local TOPLEFT, ANCHOR_TOPLEFT, CONFIRM_RELOAD_UI = TOPLEFT, ANCHOR_TOPLEFT, CONFIRM_RELOAD_UI
local PU = ProfileUtil

local F = LibFactory:NewAceLib('ButtonFactory')
if not F then return end

local P, SM = LibFactory:GetButtonFactoryLibs()
local noIconTexture = SM:Fetch(SM.MediaType.BACKGROUND, "Blizzard Dialog Background")
local buttonSize = 40
local frameStrata = 'LOW'


---- ## Start Here ----

-- TODO: Load frame by index (from config toggle)
local frameDetails = {
    [1] = { rowSize = 2, colSize = 6 },
    [2] = { rowSize = 6, colSize = 2 },
    [3] = { rowSize = 3, colSize = 5 },
    [4] = { rowSize = 2, colSize = 6 },
    [5] = { rowSize = 2, colSize = 6 },
    [6] = { rowSize = 2, colSize = 6 },
    [7] = { rowSize = 2, colSize = 6 },
    [8] = { rowSize = 3, colSize = 6 },
}

-- Initialized on Logger#OnAddonLoaded()
F.addon = nil
F.profile = nil

local function isFirstButtonInRow(colSize, i) return fmod(i - 1, colSize) == 0 end

local function ShowConfigTooltip(frame)
    GameTooltip:SetOwner(frame, ANCHOR_TOPLEFT)
    GameTooltip:AddLine('Right-click to open config UI for Actionbar ' .. frame:GetFrameIndex(), 1, 1, 1)
    GameTooltip:Show()
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function OnShowConfigTooltip(frame)
    C_Timer.After(1, function() ShowConfigTooltip(frame) end)
    C_Timer.After(3, function() GameTooltip:Hide() end)
end

local function OnMouseDownFrame(_, mouseButton)
    --F:log(1, 'Mouse Button Clicked: %s', mouseButton or '')
    GameTooltip:Hide()
    if IsShiftKeyDown() and strlower(mouseButton) == 'leftbutton' then
        ReloadUI()
    elseif strlower(mouseButton) == 'rightbutton' then
        F.addon:OpenConfig()
    elseif strlower(mouseButton) == 'button5' then
        StaticPopup_Show(CONFIRM_RELOAD_UI)
    end
end

function F:OnAfterInitialize()
    local frames = PU:GetAllFrameNames()
    --error(format('frames: %s', table.toString(frames)))
    for i,f in ipairs(frames) do
        local frameEnabled = P:IsBarIndexEnabled(i)
        local f = self:CreateActionbarGroup(i)
        if frameEnabled then
            f:ShowGroup()
        else
            f:HideGroup()
        end
    end
end

function F:CreateActionbarGroup(frameIndex)
    -- TODO: config should be in profiles
    local config = frameDetails[frameIndex]
    local f = FrameFactory:CreateFrame(frameIndex)
    f:SetWidth(config.colSize * buttonSize)
    f:SetScale(1.0)
    f:SetFrameStrata(frameStrata)
    self:CreateButtons(f, config.rowSize, config.colSize)
    f:MarkRendered()
    self:AttachFrameEvents(f)
    return f
end

function F:CreateButtons(dragFrame, rowSize, colSize)
    local index = 0
    for row=1, rowSize do
        for col=1, colSize do
            index = index + 1
            local btnUI = self:CreateSingleButton(dragFrame, row, col, index)
            btnUI:SetScript("OnReceiveDrag", function(_btnUI) self.OnReceiveDrag(self, _btnUI) end)
            dragFrame:AddButton(btnUI:GetName())
        end
    end
end

-- See: https://wowpedia.fandom.com/wiki/API_GetCursorInfo
--      This one is incorrect:  https://wowwiki-archive.fandom.com/wiki/API_GetCursorInfo
-- spell: spellId=info1 bookType=info2 ?=info3
-- item: itemId = info1, itemName/Link = info2
-- macro: macro-index=info1
function F:OnReceiveDrag(btnUI)
    AssertThatMethodArgIsNotNil(btnUI, 'btnUI', 'OnReceiveDrag(btnUI)')
    local actionType, info1, info2, info3 = GetCursorInfo()
    ClearCursor()
    if ABP_LOG_LEVEL > 10 then
        self:logp('Drag Received', { actionType=actionType, info1=tostring(info1), info2=tostring(info2), info3=tostring(info3) })
    end

    local H = ReceiveDragEventHandler
    if not H:CanHandle(actionType) then return end
    local cursorInfo = { type = actionType, bookIndex = info1, bookType = info2, id = info3 }
    H:Handle(btnUI, actionType, cursorInfo)

    --if 'spell' == actionType then
    --    local spellInfo = { type = actionType, name='TODO', bookIndex = info1, bookType = info2, id = info3 }
    --    self:logp('Spell Info', spellInfo)
    --elseif 'item' == actionType then
    --    local itemInfo = { type = actionType, id=info1, name='TODO', link=info2 }
    --   self:logp('Item Info', itemInfo)
    --end

end

function F:CreateSingleButton(dragFrame, rowNum, colNum, index)
    local frameName = dragFrame:GetName()
    local btnName = format('%sButton%s', frameName, tostring(index))
    --self:printf('frame name: %s button: %s index: %s', frameName, btnName, index)
    local btnUI = CreateFrame("Button", btnName, UIParent, SECURE_ACTION_BUTTON_TEMPLATE)
    btnUI:SetFrameStrata(frameStrata)

    local padding = 2
    btnUI:SetSize(buttonSize - padding, buttonSize - padding)
    local topLeftAdjustX = buttonSize + padding - 1
    local topLeftAdjustY = buttonSize - 10
    local adjX = (colNum * buttonSize) + padding - topLeftAdjustX
    local adjY =  (rowNum * buttonSize) + padding - topLeftAdjustY
    btnUI:SetPoint(TOPLEFT, dragFrame, TOPLEFT, adjX, -adjY)
    btnUI:SetNormalTexture(noIconTexture)
    return btnUI
end

function F:AttachFrameEvents(frame)
    frame:SetScript("OnMouseDown", OnMouseDownFrame)
    frame:SetScript("OnEnter", OnShowConfigTooltip)
end