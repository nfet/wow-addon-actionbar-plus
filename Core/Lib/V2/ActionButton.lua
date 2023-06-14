--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionButton')

--- @type ActionBarActionEventsFrameMixin
local ActionBarActionEventsFrame = ns.O.ActionBarActionEventsFrame

--- @class ActionButton
local L = {}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
---@param btn _CheckButton
local function HasAction(btn)
    --- todo: button is not empty
    return true
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param event string
---@param btn _CheckButton
function L:OnEvent(btn, event, ...)
    local arg1, arg2 = ...
    --p:log('OnEvent[%s::%s] Received with args=[%s]',
    --        frame:GetName(), event, ns.pformat({...}))
    if event == 'PLAYER_ENTERING_WORLD' then
        return self:OnPlayerEnteringWorld(...)
    end
end

--- #### SEE: Interface/FrameXML/ActionButton.lua#ActionButton_Update()
---@param btn _CheckButton
---@param force Boolean
function L:Update(btn, force)
    p:log(10, 'Update[%s] called... force=%s', btn:GetName(), force or false)

    if HasAction(btn) then
        if ( not btn.eventRegistered ) then
            ActionBarActionEventsFrame:RegisterFrame(btn)
            btn.eventRegistered = true
        end
        if ( not btn:GetAttribute("statehidden") ) then btn:Show() end
        --ActionButton_UpdateState(self);
        --ActionButton_UpdateUsable(self);
        --ActionButton_UpdateCooldown(self);
        --ActionButton_UpdateFlash(self);
        --ActionButton_UpdateHighlightMark(self);
        --ActionButton_UpdateSpellHighlightMark(self);
    else
        if ( self.eventsRegistered ) then
            ActionBarActionEventsFrame:UnregisterFrame(btn)
            btn.eventsRegistered = nil;
        end
    end

end

---@param isLogin Boolean
---@param isReload Boolean
function L:OnPlayerEnteringWorld(isLogin, isReload)
    p:log(10, 'Is-Login=%s Is-Reload=%s [ActionBarButtonEventsFrameMixin::OnPlayerEnteringWorld]', isLogin, isReload)
    local frames = ABP_ActionBarButtonEventsFrameMixin.frames
    --p:log(0, 'Number of btns: %s', #frames)

    --- @type _CheckButton
    local b = frames[1]
    b:SetAttribute('type', 'spell')
    local spell, _, icon = GetSpellInfo('Arcane Intellect')
    p:log(10, 'spell: %s icon: %s', spell, tostring(icon))
    b:SetAttribute('spell', spell)
    b:SetNormalTexture(icon)
    b:SetPushedTexture(icon)
    b:GetNormalTexture():SetAllPoints(b)
    b:GetPushedTexture():SetAllPoints(b)

    --b:GetNormalTexture():SetDesaturated(true)
    --b:SetHighlightTexture(icon)
end


--[[-----------------------------------------------------------------------------
Global
-------------------------------------------------------------------------------]]
ABP_ActionButton = L
