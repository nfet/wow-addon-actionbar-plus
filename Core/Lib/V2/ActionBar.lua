--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionBar')


ABP_ActionBarMixin = {}

function ABP_ActionBarMixin:OnLoad()
    p:log(10, 'ActionBarMixin: OnLoad...')
    --- @type _Frame
    local f = self

    if not f:IsVisible() then f:Show() end
end

-- this doesn't get called for some reason
function ABP_ActionBarMixin:OnEvent()
    p:log(10, 'ActionBarMixin: OnEvent...')
end

--[[-----------------------------------------------------------------------------
ABP_ActionBarButtonCodeMixin
-------------------------------------------------------------------------------]]

--- @class ActionBarButtonCodeMixin : _CheckButton
ABP_ActionBarButtonCodeMixin = {}

function ABP_ActionBarButtonCodeMixin:OnLoad()
    p:log(10, 'ActionBarButtonCodeMixin::OnLoad...')

    ABP_ActionBarButtonEventsFrameMixin:RegisterFrame(self)

    -- cvar ActionButtonUseKeyDown set to 1
    self:RegisterForDrag("LeftButton", "RightButton");
    self:RegisterForClicks("AnyDown");
end

---@param button ButtonName
---@param down ButtonDown
function ABP_ActionBarButtonCodeMixin:PreClick(button, down)
    p:log(10, 'PreClick')
    self:UpdateState(button, down)
end


---@param button ButtonName
---@param down ButtonDown
function ABP_ActionBarButtonCodeMixin:PostClick(button, down)
    p:log(10, 'PostClick')
    self:UpdateState(button, down)
end

---@param button ButtonName
---@param down ButtonDown
function ABP_ActionBarButtonCodeMixin:UpdateState(button, down)
    C_Timer.After(0.1, function()
        self:SetChecked(false)
    end)
end

-- This doesn't get called
function ABP_ActionBarButtonCodeMixin:OnEvent(event)
    p:log('ActionBarButtonCodeMixin::OnEvent: %s', self:GetName())
end
