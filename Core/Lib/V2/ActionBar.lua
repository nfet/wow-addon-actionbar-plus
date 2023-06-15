--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionBar')


ABP_ActionBarMixin = {}

function ABP_ActionBarMixin:OnLoad()
    p:log(10, 'ActionBarMixin: OnLoad...')
    --- @type _Frame
    local f = self
    f:RegisterForDrag('LeftButton')
    --[[if f.SetBackdrop then
        local backdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 3, right = 3, top = 5, bottom = 3 },
        }
        f:SetBackdrop(backdrop)
        f:ApplyBackdrop()
    end]]

    if not f:IsVisible() then f:Show() end
end

-- this doesn't get called for some reason
function ABP_ActionBarMixin:OnEvent()
    p:log(10, 'ActionBarMixin: OnEvent...')
end

