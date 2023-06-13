--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

ABP_ActionBarButtonCodeMixin = {}

function ABP_ActionBarButtonCodeMixin:OnLoad()
    print('ActionBarButtonCodeMixin::OnLoad XX')

end

function ABP_ActionBarButtonCodeMixin:OnClick()
    local childFrames = {self:GetParent():GetChildren()}
    print('ActionBarButtonCodeMixin::OnClick called:', self:GetName(), 'frames:', ns.pformat(#childFrames))
    --ActionButton_ShowOverlayGlow(self)
    self:SetChecked(false)
end

function ABP_ActionBarButtonCodeMixin:OnEvent()
    print('ActionBarButtonCodeMixin::OnEvent:', self:GetName())
end


ABP_ActionBarButtonEventsFrameMixin = {}
function ABP_ActionBarButtonEventsFrameMixin:OnLoad()
    print('ActionBarButtonEventsFrameMixin: OnLoad..')
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("ACTIONBAR_SHOWGRID");
    self:RegisterEvent("ACTIONBAR_HIDEGRID");
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    self:RegisterEvent("UPDATE_BINDINGS");
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    self:RegisterEvent("PET_BAR_UPDATE");
    self:RegisterEvent("UNIT_FLAGS");
    self:RegisterEvent("UNIT_AURA");
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
end
function ABP_ActionBarButtonEventsFrameMixin:OnEvent()
    --print('ABP_ActionBarButtonEventsFrameMixin: OnEvent...')
end
