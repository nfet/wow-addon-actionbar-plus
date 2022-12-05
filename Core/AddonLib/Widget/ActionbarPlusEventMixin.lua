--This mixin handles events for the addon
--
--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame, FrameUtil = CreateFrame, FrameUtil
local RegisterFrameForEvents, RegisterFrameForUnitEvents = FrameUtil.RegisterFrameForEvents, FrameUtil.RegisterFrameForUnitEvents

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local ns = ABP_Namespace(...)
local O, Core, LibStub = ns:LibPack()
local BaseAPI, API, GC = O.BaseAPI, O.API, O.GlobalConstants
local E, UnitId = GC.E, GC.UnitId
local B = O.BaseAPI
local AceEvent = O.AceLibFactory:A().AceEvent
local CURSOR_ITEM_TYPE = 1

--[[-----------------------------------------------------------------------------
Interface
-------------------------------------------------------------------------------]]
---@class EventFrameInterface : _Frame
local EventsFrameInterface = {
    ---@type EventFrameWidgetInterface
    widget = {}
}

---@class EventFrameWidgetInterface
local EventFrameWidgetInterface = {
    ---@type EventFrameInterface
    frame = {},
    ---@type ActionbarPlus
    addon = {},
    ---@type ButtonFactory
    buttonFactory = {},
    ---@type WidgetMixin
    widgetMixin = {},
}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@class ActionbarPlusEventMixin
local L = LibStub:NewLibrary(Core.M.ActionbarPlusEventMixin)
---@return LoggerTemplate
local p = L:GetLogger()

AceEvent:RegisterMessage(E.AddonMessage_OnAfterInitialize, function(evt, ...)
    ---@type ActionbarPlus
    local addon = ...
    p:log(30, 'RegisterMessage: %s called...', evt)
    addon.addonEvents:RegisterEvents()
end)

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
---@param f EventFrameInterface
---@param event string
local function OnPlayerCombatEvent(f, event, ...)
    -- p:log(40, 'Event[%s] received...', event)
    if E.PLAYER_REGEN_ENABLED == event then
        f.widget.buttonFactory:Fire(E.OnPlayerLeaveCombat)
    end

    f.widget.buttonFactory:Fire(E.OnUpdateItemStates)
    -- This second fire is for fail-safety
    C_Timer.After(2, function() f.widget.buttonFactory:Fire(E.OnUpdateItemStates) end)
end

---@param f EventFrameInterface
---@param event string
local function OnUpdateBindings(f, event, ...)
    if E.UPDATE_BINDINGS ~= event then return end
    local addon = f.widget.addon
    addon.barBindings = f.widget.widgetMixin:GetBarBindingsMap()
    if addon.barBindings then f.widget.buttonFactory:UpdateKeybindText() end
end

---@param f EventFrameInterface
---@param event string
local function OnPetBattleEvent(f, event, ...)
    if E.PET_BATTLE_OPENING_START == event then
        f.widget.buttonFactory:Fire(E.OnActionbarHideGroup)
        return
    end
    f.widget.buttonFactory:Fire(E.OnActionbarShowGroup)
end

---@param f EventFrameInterface
---@param event string
local function OnVehicleEvent(f, event, ...)
    local unitTarget = ...
    if UnitId.player ~= unitTarget then return end
    if E.UNIT_ENTERED_VEHICLE == event then
        f.widget.buttonFactory:Fire(E.OnActionbarHideGroup)
        return
    end
    f.widget.buttonFactory:Fire(E.OnActionbarShowGroup)
end

---@param f EventFrameInterface
---@param event string
local function OnActionbarGrid(f, event, ...)
    if E.ACTIONBAR_SHOWGRID == event then
        f.widget.buttonFactory:Fire(E.OnActionbarShowGrid)
        return
    end
    f.widget.buttonFactory:Fire(E.OnActionbarHideGrid)
end

--- See Also: [https://wowpedia.fandom.com/wiki/CURSOR_CHANGED](https://wowpedia.fandom.com/wiki/CURSOR_CHANGED)
---@param f EventFrameInterface
---@param event string
local function OnCursorChangeInBags(f, event, ...)
    local isDefault, newCursorType, oldCursorType, oldCursorVirtualID = ...
    --p:log(40, 'OnCursorChangeInBags: isDefault: %s new=%s old=%s', isDefault, newCursorType, oldCursorType)
    if true == isDefault and oldCursorType == CURSOR_ITEM_TYPE then
        f.widget.buttonFactory:Fire(E.OnActionbarHideGrid)
        ABP.ActionbarEmptyGridShowing = false
        return
    end
    if newCursorType ~= CURSOR_ITEM_TYPE then return end
    f.widget.buttonFactory:Fire(E.OnActionbarShowGrid)
    ABP.ActionbarEmptyGridShowing = true
end

--- Non-Instant Start-Cast Handler
--- @param f EventFrameInterface
local function OnSpellCastStart(f, ...)
    --todo next: include item spells (i.e., quest items)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    --p:log(50, 'OnSpellCastStart: %s', spellCastEvent)
    local w = f.widget
    ---@param fw FrameWidget
    w.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param btnWidget ButtonUIWidget
        fw:ApplyForEachSpellOrMacroButtons(spellCastEvent.spellID,
                function(btnWidget) btnWidget:SetHighlightInUse() end)
    end)
end

--- Non-Instant Stop-Cast Handler
--- @param f EventFrameInterface
local function OnSpellCastStop(f, ...)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    p:log(50, 'OnSpellCastStop: %s', spellCastEvent)
    local w = f.widget
    ---@param fw FrameWidget
    w.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param btn ButtonUIWidget
        fw:ApplyForEachSpellOrMacroButtons(spellCastEvent.spellID,
                function(btn) btn:ResetHighlight() end)
    end)
end

--- Non-Instant Stop-Cast Handler
--- @param f EventFrameInterface
local function OnSpellCastFailed(f, ...)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    --p:log(50, 'OnSpellCastFailed: %s', spellCastEvent)
    local w = f.widget
    ---@param fw FrameWidget
    w.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param btn ButtonUIWidget
        fw:ApplyForEachSpellOrMacroButtons(spellCastEvent.spellID,
                function(btn) btn:SetButtonStateNormal() end)
    end)
end

--- This handles 3-state spells like mage blizzard, hunter flares,
--- or basic campfire in retail
---@param f EventFrameInterface
local function OnSpellCastSent(f, ...)
    local spellCastSentEvent = B:ParseSpellCastSentEventArgs(...)
    if not spellCastSentEvent or spellCastSentEvent.unit ~= UnitId.player then return end
    local w = f.widget
    ---@param fw FrameWidget
    w.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param btn ButtonUIWidget
        fw:ApplyForEachSpellOrMacroButtons(spellCastSentEvent.spellID,
                function(btn) btn:SetButtonStateNormal() end)
    end)
end

---@param f EventFrameInterface
---@param event string
local function OnActionbarEvents(f, event, ...)
    --p:log('e[%s]: %s', event, {...})
    if E.UNIT_SPELLCAST_START == event then
        OnSpellCastStart(f, ...)
    elseif E.UNIT_SPELLCAST_STOP == event then
        OnSpellCastStop(f, ...)
    elseif E.UNIT_SPELLCAST_SENT == event then
        OnSpellCastSent(f, ...)
    --elseif E.UNIT_SPELLCAST_SUCCEEDED == event then
          -- instant cast spells
    --    OnSpellCastSucceeded(f, ...)
    elseif E.UNIT_SPELLCAST_FAILED_QUIET == event then
        OnSpellCastFailed(f, ...)
    end
end

---@param eventWidget EventFrameWidgetInterface
local function OnStealth(eventWidget)
    ---@param fw FrameWidget
    eventWidget.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param bw ButtonUIWidget
        fw:ApplyForEachButtonCondition(
                function(bw) return bw:GetButtonData():IsStealthSpell() end,
                function(bw)
                    local spellInfo = bw:GetButtonData():GetSpellInfo()
                    local icon = API:GetSpellIcon(spellInfo)
                    bw:SetIcon(icon)
                end)
    end)
end

---@param eventWidget EventFrameWidgetInterface
local function OnShapeShift(eventWidget)
    ---@param fw FrameWidget
    eventWidget.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param bw ButtonUIWidget
        fw:ApplyForEachButtonCondition(
                function(bw) return bw:GetButtonData():IsShapeshiftSpell() end,
                function(bw)
                    local spellInfo = bw:GetButtonData():GetSpellInfo()
                    local icon = API:GetSpellIcon(spellInfo)
                    bw:SetIcon(icon)
                end)
    end)
end

---@param eventWidget EventFrameWidgetInterface
local function OnStealthIconUpdate(eventWidget)
    ---@param fw FrameWidget
    eventWidget.buttonFactory:ApplyForEachVisibleFrames(function(fw)
        ---@param bw ButtonUIWidget
        fw:ApplyForEachButtonCondition(
                function(bw) return bw:GetButtonData():IsStealthSpell() end,
                function(bw)
                    local spellInfo = bw:GetButtonData():GetSpellInfo()
                    local icon = API:GetSpellIcon(spellInfo)
                    bw:SetIcon(icon)
                end)
    end)
end

--- Sequence is UPDATE_SHAPESHIFT_FORM, UPDATE_STEALTH, UPDATE_SHAPESHIFT_FORM; for this reason
---@param f EventFrameInterface
---@param event string
local function OnShapeshiftOrStealthEvent(f, event, ...)
    local eventWidget = f.widget
    if E.UPDATE_STEALTH == event then
        OnStealth(eventWidget)
    elseif E.UPDATE_SHAPESHIFT_FORM == event then
        OnShapeShift(eventWidget)
    end
end

---@param f EventFrameInterface
---@param event string
local function OnPlayerEnteringWorld(f, event, ...)
    OnStealthIconUpdate(f.widget)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param addon ActionbarPlus
function L:Init(addon)
    self.addon = addon
    self.buttonFactory = O.ButtonFactory
    self.widgetMixin = O.WidgetMixin
end

---@return EventFrameInterface
function L:CreateEventFrame()
    local f = CreateFrame("Frame", nil, self.addon.frame)
    f.widget = self:CreateWidget(f)
    return f
end

---@param eventFrame _Frame
---@return EventFrameWidgetInterface
function L:CreateWidget(eventFrame)
    local widget = {
        frame = eventFrame,
        addon = self.addon,
        buttonFactory = self.buttonFactory,
        widgetMixin = self.widgetMixin
    }
    return widget
end

function L:RegisterActionbarsEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnActionbarEvents)
    RegisterFrameForUnitEvents(f, {
        E.UNIT_SPELLCAST_START,
        E.UNIT_SPELLCAST_STOP,
        E.UNIT_SPELLCAST_SENT,
        E.UNIT_SPELLCAST_FAILED_QUIET,
        --E.UNIT_SPELLCAST_SUCCEEDED,
        --E.UNIT_SPELLCAST_FAILED,
    })
end

function L:RegisterShapeshiftOrStealthEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnShapeshiftOrStealthEvent)
    RegisterFrameForEvents(f, { E.UPDATE_STEALTH, E.UPDATE_SHAPESHIFT_FORM })
end

function L:RegisterKeybindingsEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnUpdateBindings)
    RegisterFrameForEvents(f, { E.UPDATE_BINDINGS })
end

function L:RegisterVehicleFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnVehicleEvent)
    RegisterFrameForUnitEvents(f, { E.UNIT_ENTERED_VEHICLE, E.UNIT_EXITED_VEHICLE }, GC.UnitId.player)
end

function L:RegisterActionbarGridEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnActionbarGrid)
    RegisterFrameForEvents(f, { E.ACTIONBAR_SHOWGRID, E.ACTIONBAR_HIDEGRID })
end

function L:RegisterCursorChangesInBagEvents()
    if BaseAPI:IsClassicEra() then return end
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnCursorChangeInBags)
    RegisterFrameForEvents(f, { E.CURSOR_CHANGED })
end

function L:RegisterPetBattleFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPetBattleEvent)
    RegisterFrameForEvents(f, { E.PET_BATTLE_OPENING_START, E.PET_BATTLE_CLOSE })
end

--- Use PLAYER_REGIN[ENABLED|DISABLED] is more reliable than using
--- PLAYER_[ENTER|LEAVE]_COMBAT event
function L:RegisterCombatFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPlayerCombatEvent)
    RegisterFrameForEvents(f, { E.PLAYER_REGEN_ENABLED, E.PLAYER_REGEN_DISABLED })
end
function L:RegisterPlayerEnteringWorld()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPlayerEnteringWorld)
    RegisterFrameForEvents(f, { E.PLAYER_ENTERING_WORLD })
end

function L:RegisterEvents()
    p:log(30, 'RegisterEvents called..')
    self:RegisterActionbarsEventFrame()
    self:RegisterKeybindingsEventFrame()
    self:RegisterActionbarGridEventFrame()
    self:RegisterCursorChangesInBagEvents()
    self:RegisterShapeshiftOrStealthEventFrame()
    self:RegisterCombatFrame()
    self:RegisterPlayerEnteringWorld()
    if B:SupportsPetBattles() then self:RegisterPetBattleFrame() end
    --TODO: Need to investigate Wintergrasp (hides/shows intermittently)
    if B:SupportsVehicles() then self:RegisterVehicleFrame() end
end