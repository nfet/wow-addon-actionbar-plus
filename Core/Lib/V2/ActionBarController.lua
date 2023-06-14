--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionBarController')

ABP_ActionBarControllerMixin = {}

function ABP_ActionBarControllerMixin:OnLoad()
    p:log(10, 'OnLoad')

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
function ABP_ActionBarControllerMixin:OnEvent(event, ...)
    local arg1, arg2 = ...;
    p:log(10, 'OnEvent[%s]: args=[%s]', event, ns.pformat({...}))
    if ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UpdateAll()
    end
end

--- #### SEE: Interface/FrameXML/ActionButton.lua#ActionButton_UpdateAction()
---@param force Boolean
function ABP_ActionBarControllerMixin:UpdateAll(force)
    -- If we have a skinned vehicle bar or skinned override bar, display the OverrideActionBar
    local frames = ABP_ActionBarButtonEventsFrameMixin.frames
    if not frames then return end
    for k, frame in pairs(frames) do
        ABP_ActionButton:Update(frame, force)
    end
end
