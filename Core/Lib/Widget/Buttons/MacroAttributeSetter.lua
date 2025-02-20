--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GameTooltip, GetMacroSpell, GetMacroItem = GameTooltip, GetMacroSpell, GetMacroItem

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local sformat = string.format

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local AceEvent = O.AceLibrary.AceEvent

local String, WAttr = O.String, GC.WidgetAttributes
local MACRO_WITHOUT_SPELL_FORMAT = '%s |cfd5a5a5a(Macro)|r'
local MACRO_WITH_SPELL_FORMAT = '|cfd03c2fc::|r |cfd03c2fc%s|r |cfd5a5a5a(Macro)|r'

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@class MacroAttributeSetter : BaseAttributeSetter
local S = LibStub:NewLibrary(M.MacroAttributeSetter); if not S then return end; AceEvent:Embed(S)
---@type BaseAttributeSetter
local BaseAttributeSetter = LibStub(M.BaseAttributeSetter)
local p = S:GetLogger()

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

---@param btnUI ButtonUI
function S:SetAttributes(btnUI)
    local w = btnUI.widget
    w:ResetWidgetAttributes(btnUI)
    local macroInfo = w:GetMacroData()
    if w:IsInvalidMacro(macroInfo) then return end

    local icon = GC.Textures.TEXTURE_EMPTY
    if macroInfo.icon then icon = macroInfo.icon end

    btnUI:SetAttribute(WAttr.TYPE, WAttr.MACRO)
    btnUI:SetAttribute(WAttr.MACRO, macroInfo.index or macroInfo.macroIndex)
    w:SetIcon(icon)

    if w:IsM6Macro(macroInfo.name) then
        self:SendMessage(GC.M.MacroAttributeSetter_OnSetIcon, ns.name, function() return w, macroInfo.name end)
    end

    C_Timer.NewTicker(0.01, function() w:UpdateMacroState() end, 2)
    self:OnAfterSetAttributes(btnUI)
end

---@param btnUI ButtonUI
function S:ShowTooltip(btnUI)
    local w = btnUI.widget

    if not w:ConfigContainsValidActionType() then return end

    local macroInfo = w:GetMacroData()
    if w:IsInvalidMacro(macroInfo) then return end

    if w:IsM6Macro(macroInfo.name) then
        self:SendMessage(GC.M.MacroAttributeSetter_OnShowTooltip, ns.name, function() return w, macroInfo.name end)
        return
    end

    local spellId = GetMacroSpell(macroInfo.index)
    if not spellId then
        local _, itemLink = GetMacroItem(macroInfo.index)
        if not itemLink then
            GameTooltip:SetText(sformat(MACRO_WITHOUT_SPELL_FORMAT, macroInfo.name))
            return
        end
        GameTooltip:SetHyperlink(itemLink)
    else
        GameTooltip:SetSpellByID(spellId)
    end
    GameTooltip:AppendText(' ' .. sformat(MACRO_WITH_SPELL_FORMAT, macroInfo.name))
end

S.mt.__index = BaseAttributeSetter
S.mt.__call = S.SetAttributes
