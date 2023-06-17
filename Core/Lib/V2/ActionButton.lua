--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionButton')

--- @type ActionBarActionEventsFrameMixin
local ActionBarActionEventsFrame = ns.O.ActionBarActionEventsFrame

--- @alias ActionButton _ActionButton | _CheckButton

--- #### See: Interface/FrameXML/ActionButtonTemplate.xml
--- @class _ActionButton : __CheckButton
local L = {
    --- @type ActionBarWidget
    widget = nil,
    eventRegistered = false,
    --- @type CooldownFrame
    cooldown = nil,
    --- @type _Texture
    NormalTexture = nil,
}
--- @type ActionButton
ABP_ActionButton = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o _ActionButton | _CheckButton
local function PropsAndMethods(o)

    --- @param event string
    function o:OnEvent(event, ...)
        local arg1, arg2 = ...
        --p:log('OnEvent[%s::%s] Received with args=[%s]',
        --        frame:GetName(), event, ns.pformat({...}))
        if event == 'PLAYER_ENTERING_WORLD' then
            return self:OnPlayerEnteringWorld(...)
        end
    end

    --- @return number
    function o:GetFrameIndex()
        --- @type ActionBarFrame
        local actionbarFrame = self:GetParent()
        return actionbarFrame.frameIndex
    end

    --- @return boolean
    function o:HasAction()
        return false
    end

    --- @return boolean
    function o:IsEventRegistered() return self.eventRegistered == true end

    --- #### SEE: Interface/FrameXML/ActionButton.lua#ActionButton_Update()
    ---@param force Boolean
    function o:Update(force)
        p:log(10, 'Update[%s] called... force=%s', self:GetName(), force or false)

        if self:HasAction() then
            if ( not self.eventRegistered ) then
                ActionBarActionEventsFrame:RegisterFrame(self)
            end
            if ( not self:GetAttribute("statehidden") ) then self:Show() end
            --ActionButton_UpdateState(self);
            --ActionButton_UpdateUsable(self);
            --ActionButton_UpdateCooldown(self);
            --ActionButton_UpdateFlash(self);
            --ActionButton_UpdateHighlightMark(self);
            --ActionButton_UpdateSpellHighlightMark(self);
        else
            if ( self.eventsRegistered ) then
                ActionBarActionEventsFrame:UnregisterFrame(self)
            end
        end

    end

    --- @param isLogin Boolean
    --- @param isReload Boolean
    function o:OnPlayerEnteringWorld(isLogin, isReload)
        p:log(10, '%s: Is-Login=%s Is-Reload=%s [OnPlayerEnteringWorld]',
                self:GetName(), isLogin, isReload)
    end
end; PropsAndMethods(L)
