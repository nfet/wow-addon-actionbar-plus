--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tinsert, tsort = table.insert, table.sort
local sformat = string.format

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local pformat = ns.pformat
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local Table, AceEvent = O.Table, O.AceLibrary.AceEvent
local IsEmptyTable = Table.IsEmpty

local p = O.Logger:NewLogger('ActionBarController')
--- @type table<number, string> array of frame names
local actionBars = {}

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @class ActionBarControllerMixin
local L = {}
ABP_ActionBarControllerMixin = L
ns.O.ActionBarController = L

--- @alias ActionBarController ActionBarControllerMixin | _Frame

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function profile() return O.Profile end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionBarControllerMixin
local function PropsAndMethods(o)

    --- @return ActionBarController
    function o:f() return self end

    function o:OnLoad()
        p:log(0, 'OnLoad...')

        --ManyBars
        self:RegisterEvent("PLAYER_ENTERING_WORLD");
        --self:RegisterEvent("ACTIONBAR_PAGE_CHANGED");

        -- This is used for shapeshifts/stances
        -- self:RegisterEvent("UPDATE_BONUS_ACTIONBAR");

        --MainBar Only

        --Alternate Only
        --if ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
        --    self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR");
        --    self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR");
        --end

        --Shapeshift/Stance Only
        --self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
        --self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
        --self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE");

        -- Possess Bar
        --self:RegisterEvent("UPDATE_POSSESS_BAR");

        -- MultiBarBottomLeft
        -- self:RegisterEvent("ACTIONBAR_SHOW_BOTTOMLEFT");
    end

    --- #### SEE: Interface/FrameXML/ActionBarController.lua#ActionBarController_UpdateAll()
    --- @param event string
    function o:OnEvent(event, ...)
        local arg1, arg2 = ...;
        p:log(10, 'OnEvent[%s]: args=[%s]', event, ns.pformat({...}))
        if ( event == "PLAYER_ENTERING_WORLD" ) then
            self:OnPlayerEnteringWord()
        end
    end

    function o:OnPlayerEnteringWord()
        --self:UpdateAll()
    end

    --- #### SEE: Interface/FrameXML/ActionButton.lua#ActionButton_UpdateAction()
    ---@param force Boolean
    function o:UpdateAll(force)
        -- If we have a skinned vehicle bar or skinned override bar, display the OverrideActionBar
        local frames = ABP_ActionBarButtonEventsFrameMixin.frames
        if not frames then return end
        for k, frame in pairs(frames) do
            ABP_ActionButton:Update(frame, force)
        end
    end

    function o:Init()
        local frameNames = L:CreateActionbarFrames()
        for i, fn in ipairs(frameNames) do
            local f = self:CreateActionbarGroup(i, fn)
            --f:ShowGroupIfEnabled()
        end
    end

    function o:CreateActionbarFrames()
        local frameNames = {}
        --local frameCount = profile():GetActionbarFrameCount()
        local frameCount = 1
        for i=1, frameCount do
            --- @type _Frame
            local f = self:CreateFrame(i)
            f:ClearAllPoints()
            f:SetPoint('CENTER', nil, 'CENTER', 350, 250)
            f:Show()
            tinsert(actionBars, f:GetName())
            --local actionbarFrame = self:CreateFrame(i)
            --tinsert(frameNames, actionbarFrame:GetName())
        end
        tsort(actionBars)

        return actionBars
    end

    ---@param frameIndex number
    ---@param frameName string
    function o:CreateActionbarGroup(frameIndex, frameName)
        local barConfig = profile():GetBar(frameIndex)
        --local widget = barConfig.widget

        local rowSize = barConfig.widget.rowSize
        local colSize = barConfig.widget.colSize

        local f = _G[frameName]
        f.index = frameIndex
        self:CreateButtons(f, rowSize, colSize)
        --f:SetInitialState()
        return f
    end

    ---@param fw _Frame
    function o:CreateButtons(fw, rowSize, colSize)
        --fw:ClearButtons()
        local index = 0
        for row=1, rowSize do
            for col=1, colSize do
                index = index + 1
                --- @type _CheckButton
                local btnUI = fw['Button' .. index]
                if not btnUI then
                    btnUI = self:CreateSingleButton(fw, row, col, index)
                    p:log(10, 'Creating button[%s]: %s size: %s', index, btnUI:GetName(),
                            pformat({ btnUI:GetSize() }))
                end
                tinsert(fw:GetChildren(), btnUI)
                --fw:AddButtonFrame(btnUI)
            end
        end
        --self:HideUnusedButtons(fw)
        self:LayoutButtonGrid(fw)
    end

    --- @param frameWidget _Frame
    --- @param row number
    --- @param col number
    --- @param btnIndex number The button index number
    --- @return ButtonUIWidget
    function o:CreateSingleButton(frameWidget, row, col, btnIndex)
        local template = 'ABP_ActionBar1ButtonTemplate'
        local btnIndexName = sformat('Button%s', btnIndex)
        --local btnName = frameWidget:GetName() .. btnIndexName
        local btnName = sformat('$parent%s', btnIndexName)
        --- @type _CheckButton
        local btnWidget = CreateFrame('CheckButton', btnName, frameWidget, template)
        if btnWidget.SetParentKey then
            btnWidget:SetParentKey(btnIndexName)
        end

        --btnWidget:SetPoint('LEFT', sformat('$parentButton%s', btnIndex - 1),
        --'RIGHT', 6, 0)
        --[[btnWidget:SetButtonAttributes()
        btnWidget:SetCallback("OnMacroChanged", OnMacroChanged)
        btnWidget:UpdateStateDelayed(0.05)]]
        return btnWidget
    end

    --- @param frameIndex number
    --- @return _Frame
    function o:CreateFrame(frameIndex)
        local frameName = GC:GetFrameName(frameIndex)
        --- @type _Frame
        local f = CreateFrame('Frame', frameName, nil, 'ABP_ActionBar')
        p:log(10, '  • Created Frame[%s]: %s %s', frameIndex, frameName, f:GetName())

        return f
    end

    --- @param f _Frame
    function o:LayoutButtonGrid(f)
        local horizontalButtonPadding = 8
        local verticalButtonPadding = 8

        local barConfig = profile():GetBar(f.index)
        --local buttonSize = barConfig.widget.buttonSize
        local buttonSize = 36
        local paddingX = horizontalButtonPadding
        local paddingY = verticalButtonPadding
        local horizontalSpacing = buttonSize
        local verticalSpacing = buttonSize
        local stride = barConfig.widget.colSize
        -- TopLeftToBottomRight
        -- TopLeftToBottomRightVertical
        local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.TopLeftToBottomRight,
                stride, paddingX, paddingY, horizontalSpacing, verticalSpacing);
        --- Offset from the anchor point
        --- @param row number
        --- @param col number
        function layout:GetCustomOffset(row, col) return 0, 0 end

        --- @type _AnchorMixin
        local anchor = CreateAnchor("TOPLEFT", f:GetName(), "TOPLEFT", 0, -2);
        local buttons = self:GetButtons(f)
        AnchorUtil.GridLayout(buttons, anchor, layout);

        --- @type _Texture
        local bg = f.Background
        local colSize = barConfig.widget.colSize
        local framePadding = 10
        local width = buttonSize * colSize + (horizontalButtonPadding * (colSize - 1)) + (framePadding*2)
        bg:SetSize(width, 100)

    end

    --- @param f _Frame
    function o:GetButtons(f)
        local buttons = {}
        local children = f:GetChildren()
        p:log(10, 'children: %s', #children)
        for i, child in ipairs(children) do
            p:log(10, 'child: %s', child:GetName())
            if child:GetObjectType() == 'CheckButton' then
                tinsert(buttons, child)
            end
        end
        return buttons
    end
end

PropsAndMethods(L)

AceEvent:RegisterMessage(GC.M.OnAddOnInitialized, function(msg)
    p:log(10, 'MSG::R: %s', msg)
    if IsEmptyTable(actionBars) then
        L:Init()
        return
    end
end)
