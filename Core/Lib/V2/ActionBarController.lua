--[[-----------------------------------------------------------------------------
File: ActionBarControllerMixin
Notes:
  - ActionBarControllerMixin <<extends>> _Frame
  - Load this after ActionBarController
  - See: ActionBarController.xml
-------------------------------------------------------------------------------]]

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
--- @alias ActionBarController ActionBarControllerMixin | ActionBarBuilder | _Frame
--- @class ActionBarControllerMixin
local L = {}
ABP_ActionBarControllerMixin = L
ns.O.ActionBarController = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function InitActionBars()
    --- @type ActionBarController
    local c = ABP_ActionBarController
    c:Build()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- self is Blizzard Frame
--- @param o ActionBarControllerMixin | ActionBarBuilder | _Frame
local function PropsAndMethods(o)

    function o:OnLoad()
        p:log(10, 'OnLoad: %s', self:GetName())
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

end; PropsAndMethods(L)

--[[-----------------------------------------------------------------------------
Register Message
-------------------------------------------------------------------------------]]
AceEvent:RegisterMessage(GC.M.OnAddOnInitialized, function(msg)
    p:log(10, 'MSG::R: %s', msg)
    if IsEmptyTable(actionBars) then InitActionBars() end
end)
