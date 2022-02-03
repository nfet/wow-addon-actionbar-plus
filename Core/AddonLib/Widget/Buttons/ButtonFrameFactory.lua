--
-- ButtonFrameFactory
--
-- ## External -------------------------------------------------
local _G = _G
local type, ipairs, tinsert = type, ipairs, table.insert
-- ## Local ----------------------------------------------------
local LibStub, M, Assert, P, LSM = ABP_WidgetConstants:LibPack()

---@class ButtonFrameFactory
local _L = LibStub:NewLibrary(M.ButtonFrameFactory)

-- ## Functions ------------------------------------------------

---@param widget FrameWidget
local function WidgetMethods(widget)
    local AssertThatMethodArgIsNotNil = Assert.AssertThatMethodArgIsNotNil

    widget.rendered = false
    widget.buttons = {}
    local frame = widget.frame

    function widget:GetName()
        return widget.frame:GetName()
    end

    function widget:GetFrameIndex()
        return self.frameIndex
    end

    function widget:Toggle()
        if self:IsShown() then self:Hide(); return end
        self:Show()
    end

    function widget:SetFrameState(frameIndex, isEnabled)
        AssertThatMethodArgIsNotNil(frameIndex, 'frameIndex', 'SetFrameState(frameIndex)')
        P:SetBarEnabledState(frameIndex, isEnabled)
        if isEnabled then
            if self.ShowGroup then self:ShowGroup() end
            return
        end
        if self.HideGroup then self:HideGroup() end
    end

    -- Synchronize UI and Profile data
    function widget:IsShownInConfig(frameIndex)
        AssertThatMethodArgIsNotNil(frameIndex, 'frameIndex', 'IsShownInConfig(frameIndex)')
        local actualFrameIsShown = frame:IsShown()
        P:SetBarEnabledState(frameIndex, actualFrameIsShown)
        return P:IsBarEnabled(frameIndex)
    end

    function widget:ToggleGroup()
        if #self.buttons > 0 then
            local firstBtn = _G[self.buttons[1]]
            if firstBtn:IsShown() then self:HideGroup()
            else self:ShowButtons() end
        end
    end

    function widget:HideGroup()
        frame:Hide()
        self:HideButtons()
    end

    function widget:ShowGroup()
        frame:Show()
        self:ShowButtons()
    end

    function widget:ShowButtons()
        for _, btnName in ipairs(self.buttons) do
            _G[btnName]:Show()
        end
    end

    function widget:HideButtons()
        for _, btnName in ipairs(self.buttons) do
            _G[btnName]:Hide()
        end
    end

    function widget:AddButton(buttonName)
        if type(buttonName) ~= 'string' then return end
        tinsert(self.buttons, buttonName)
    end

    function widget:GetButtonCount() return #self.buttons end

    function widget:GetButtons()
        return self.buttons
    end

    function widget:IsRendered()
        return self.rendered
    end

    function widget:IsNotRendered()
        return not self:IsRendered()
    end

    function widget:MarkRendered()
        self.rendered = true
    end

end

--local function getProfileUtil()
--    if not P then P = WidgetLibFactory:GetProfile() end
--    return P
--end

function _L:GetFrameByIndex(frameIndex)
    local frameName = P:GetFrameNameByIndex(frameIndex)
    return _G[frameName]
end

function _L:IsFrameShownByIndex(frameIndex)
    return self:GetFrameByIndex(frameIndex):IsShown()
end

function _L:CreateFrame(frameIndex)
    local FrameBackdrop = {
        ---@see LibSharedMedia
        bgFile = LSM:Fetch(LSM.MediaType.BACKGROUND, "Blizzard Marble"),
        --bgFile = LSM:Fetch(LSM.MediaType.BACKGROUND, "Blizzard Parchment"),
        --bgFile = LSM:Fetch(LSM.MediaType.BACKGROUND, "Solid"),
        --edgeFile = LSM:Fetch(LSM.MediaType.BORDER, "Blizzard Chat Bubble"),
        --edgeFile = LSM:Fetch(LSM.MediaType.BORDER, "Blizzard Dialog"),
        tile = false, tileSize = 26, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    }
    local FrameHandleBackdrop = {
        ---@see LibSharedMedia
        bgFile = LSM:Fetch(LSM.MediaType.BACKGROUND, "Solid"),
        tile = false, tileSize = 26, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    }

    ---@class Frame
    local f = self:GetFrameByIndex(frameIndex)

    local fh = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
    --fh:SetToplevel(true)

    ---@class FrameWidget
    local widget = {
        frameIndex = frameIndex,
        buttonSize = 35,
        frameHandleHeight = 3,
        dragHandleHeight = 0,
        padding = 2,
        frameStrata = 'LOW',
        frame = f,
        frameHandle = fh
    }
    widget.frame = f
    f.widget, fh.widget = widget, widget

    local config = P:GetActionBarSizeDetailsByIndex(frameIndex)

    --local halfPadding = widget.padding/2
    local widthAdj = widget.padding
    local heightAdj = widget.padding + widget.dragHandleHeight
    local frameWidth = (config.colSize * widget.buttonSize) + widthAdj
    f:SetWidth(frameWidth)
    f:SetHeight((config.rowSize * widget.buttonSize) + heightAdj)
    f:SetFrameStrata(widget.frameStrata)
    f:SetBackdrop(FrameBackdrop)
    f:SetBackdropColor(0, 0, 0, 1)

    fh:SetBackdrop(FrameHandleBackdrop)
    --fh:SetBackdropColor(0.92, 0.96, 0.26, 0.2)
    -- yellow
    --fh:SetBackdropColor(0.92, 0.96, 0.26, 0.5)
    -- orange
    fh:SetBackdropColor(235/255, 152/255, 45/255, 0.5)
    fh:SetWidth(frameWidth)
    fh:EnableMouse(true)
    fh:SetMovable(true)
    fh:SetResizable(true)
    fh:SetHeight(widget.frameHandleHeight)
    fh:SetFrameStrata(widget.frameStrata)
    fh:SetPoint("BOTTOM", f, "TOP", 0, 1)
    fh:SetScript("OnLoad", function() self:RegisterForDrag("LeftButton"); end)
    fh:SetScript("OnMouseDown", function() print('mouse down'); f:StartMoving(); end)
    fh:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); end)
    fh:SetScript("OnDragStart", function() f:StartMoving();  end)
    fh:SetScript("OnDragStop", function() f:StopMovingOrSizing(); end)
    fh:Show()

    WidgetMethods(widget)

    return widget
end

_L.mt.__call = _L.CreateFrame

