--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local pformat = ns.pformat
local p = O.Logger:NewLogger('ActionBarTemplateMixin')

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]

--- @alias ActionBarTemplate ActionBarTemplateMixin | _Frame
--- @class ActionBarTemplateMixin
local L = {}
ABP_ActionBarTemplateMixin = L

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionBarTemplateMixin | _Frame
local function PropsAndMethods(o)
    function o:OnLoad()
        p:log(10, 'OnLoad: %s FrameLevel: %s', self:GetName(),
                self:GetAttribute("frameLevel"))

        --- @type ActionBarFrame
        local actionbarFrame = self
        --- @type ActionBarWidget
        self.widget = CreateAndInitFromMixin(ns.O.ActionbarWidgetMixin, actionbarFrame)

        self:RegisterForDrag('LeftButton')
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
        if not self:IsVisible() then self:Show() end
    end

    -- TODO: Use frame:GetLeft(), GetRight() to get the width/height
    --       SEE: https://wowwiki-archive.fandom.com/wiki/UI_coordinates
    function o:OnDragStart(...)
        if IsAltKeyDown() then
            self:StartSizing('BOTTOMRIGHT')
            return
        end
        if not IsShiftKeyDown() then return end
        --p:log('OnDragStart[%s]: args=[%s]', self:GetName(), pformat({...}))
        self:StartMoving()
    end
    function o:OnDragStop(...)
        --p:log('OnDragStop[%s]: args=[%s]', self:GetName(), pformat({...}))
        self:StopMovingOrSizing()
    end

    -- this doesn't get called for some reason
    function o:OnEvent()
        p:log(10, 'ActionBarMixin: OnEvent...')
    end

end; PropsAndMethods(L)
