--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local p = ns.O.Logger:NewLogger('ActionBarActionEventsFrameMixin')

--- @alias ActionBarActionEventsFrameMixin _ActionBarActionEventsFrameMixin|_Frame
--- @class _ActionBarActionEventsFrameMixin : _Frame_
local L = {}
--- @type table<number, _CheckButton>
L.frames = {}

--- @type ActionBarActionEventsFrameMixin
ABP_ActionBarActionEventsFrameMixin = L
ns.O.ActionBarActionEventsFrame = L

function L:OnLoad()
    p:log(10, 'OnLoad...')

    --self:RegisterEvent("ACTIONBAR_UPDATE_STATE");			not updating state from lua anymore, see SetActionUIButton
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
    --self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");		not updating cooldown from lua anymore, see SetActionUIButton
    self:RegisterEvent("SPELL_UPDATE_CHARGES");
    self:RegisterEvent("UPDATE_INVENTORY_ALERTS");
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("TRADE_SKILL_SHOW");
    self:RegisterEvent("TRADE_SKILL_CLOSE");
    self:RegisterEvent("PLAYER_ENTER_COMBAT");
    self:RegisterEvent("PLAYER_LEAVE_COMBAT");
    self:RegisterEvent("START_AUTOREPEAT_SPELL");
    self:RegisterEvent("STOP_AUTOREPEAT_SPELL");
    self:RegisterEvent("UNIT_INVENTORY_CHANGED");
    self:RegisterEvent("LEARNED_SPELL_IN_TAB");
    --self:RegisterEvent("PET_STABLE_UPDATE");
    --self:RegisterEvent("PET_STABLE_SHOW");
    --self:RegisterEvent("LOSS_OF_CONTROL_ADDED");
    --self:RegisterEvent("LOSS_OF_CONTROL_UPDATE");
    self:RegisterEvent("SPELL_UPDATE_ICON");
end

--- #### SEE: Interface/FrameXML/ActionButton.lua#ActionBarActionEventsFrame_OnEvent()
--- Pass event down to the buttons
--- @param event string
function L:OnEvent(event, ...)
    p:log(0, 'OnEvent(%s): args=%s', event, ns.pformat({...}))

    for k, frame in pairs(self.frames) do
        ABP_ActionButton:OnEvent(frame, event, ...);
    end
end

---@param frame _CheckButton
function L:RegisterFrame(frame)
    p:log(10, 'Frame Registered: %s', frame:GetName())
    self.frames[frame] = frame
end

---@param frame _CheckButton
function L:UnregisterFrame(frame) self.frames[frame] = nil end
