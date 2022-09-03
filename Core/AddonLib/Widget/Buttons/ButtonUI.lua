--[[-----------------------------------------------------------------------------
WoW Vars
-------------------------------------------------------------------------------]]
local PickupSpell, ClearCursor, GetCursorInfo, CreateFrame, UIParent =
    PickupSpell, ClearCursor, GetCursorInfo, CreateFrame, UIParent
local GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show =
    GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show
local InCombatLockdown, GameFontHighlightSmallOutline = InCombatLockdown, GameFontHighlightSmallOutline
local GetMacroSpell, GetMacroItem, GetItemInfoInstant = GetMacroSpell, GetMacroItem, GetItemInfoInstant

--[[-----------------------------------------------------------------------------
LUA Vars
-------------------------------------------------------------------------------]]
local pack, fmod = table.pack, math.fmod
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local LibStub, M, A, P, LSM, W, CC, G = ABP_WidgetConstants:LibPack()
local Mixin = __K_Core:LibPack_Mixin()

local _, AceGUI, AceHook = G:LibPack_AceLibrary()
local ButtonDataBuilder = G:LibPack_ButtonDataBuilder()
local AceEvent = ABP_LibGlobals:LibPack_AceLibrary()

local _, Table, String, LogFactory = G:LibPackUtils()
local ToStringSorted = ABP_LibGlobals:LibPackPrettyPrint()

local IsBlank = String.IsBlank
local PH = ABP_PickupHandler
local WU = ABP_LibGlobals:LibPack_WidgetUtil()
local E = ABP_WidgetConstants.E

---@type LogFactory
local p = LogFactory:NewLogger('ButtonUI')

local AssertThatMethodArgIsNotNil = A.AssertThatMethodArgIsNotNil
local SECURE_ACTION_BUTTON_TEMPLATE = SECURE_ACTION_BUTTON_TEMPLATE
local SPELL, ITEM, MACRO = ABP_WidgetConstants:LibPack_SpellItemMacro()

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function IsValidDragSource(cursorInfo)
    if IsBlank(cursorInfo.type) then
        -- This can happen if a chat tab or others is dragged into
        -- the action bar.
        --p:log(20, 'Received drag event with invalid cursor info. Skipping...')w
        return false
    end
    if not (cursorInfo.type == SPELL or cursorInfo.type == ITEM or cursorInfo.type == MACRO) then
        return false
    end

    return true
end
---@param btnUI ButtonUI
local function OnDragStart(btnUI)
    ---@type ButtonUIWidget
    local w = btnUI.widget

    if InCombatLockdown() or not WU:IsDragKeyDown() then return end
    w:Reset()
    p:log(20, 'DragStarted| Actionbar-Info: %s', pformat(btnUI.widget:GetActionbarInfo()))

    local btnData = btnUI.widget:GetConfig()
    PH:Pickup(btnData)

    w:SetButtonAsEmpty()
    btnUI.widget:Fire('OnDragStart')
end

--- Used with `button:RegisterForDrag('LeftButton')`
---@param btnUI ButtonUI
local function OnReceiveDrag(btnUI)
    AssertThatMethodArgIsNotNil(btnUI, 'btnUI', 'OnReceiveDrag(btnUI)')
    --p:log('OnReceiveDrag|_state_type: %s', pformat(btnUI._state_type))

    -- TODO: Move to TBC/API
    local actionType, info1, info2, info3 = GetCursorInfo()

    local cursorInfo = { type = actionType or '', info1 = info1, info2 = info2, info3 = info3 }
    --p:log(20, 'OnReceiveDrag Cursor-Info: %s', ToStringSorted(cursorInfo))
    if not IsValidDragSource(cursorInfo) then return end
    ClearCursor()

    ---@type ReceiveDragEventHandler
    local dragEventHandler = W:LibPack_ReceiveDragEventHandler()
    dragEventHandler:Handle(btnUI, actionType, cursorInfo)

    btnUI.widget:Fire('OnReceiveDrag')
end

---Triggered by SetCallback('event', fn)
---@param _widget ButtonUIWidget
local function OnReceiveDragCallback(_widget) _widget:UpdateStateDelayed(0.01) end

---@param widget ButtonUIWidget
---@param down boolean true if the press is KeyDown
local function RegisterForClicks(widget, event, down)
    if E.ON_LEAVE == event then
        widget.button:RegisterForClicks('AnyDown')
    elseif E.ON_ENTER == event then
        widget.button:RegisterForClicks(WU:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
    elseif E.MODIFIER_STATE_CHANGED == event or 'PreClick' == event then
        widget.button:RegisterForClicks(down and WU:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
    end
end

---@param widget ButtonUIWidget
---@param down boolean true if the press is KeyDown
local function OnModifierStateChanged(widget, down)
    RegisterForClicks(widget, E.MODIFIER_STATE_CHANGED, down)
    if widget:IsMacro() then
        C_Timer.After(0.05, function() widget:Fire('OnModifierStateChanged') end)
    end
end

---@param widget ButtonUIWidget
local function OnModifierStateChangedCallback(widget, event)
    local scd = widget:GetMacroSpellCooldown()
    if not (scd and scd.spell) then return end
    --p:log('OnModifierStateChangedCallback: update cooldown: %s', scd.spell.name)
    widget:SetIcon(scd.spell.icon)
    widget:UpdateCooldown()
end

---@param widget ButtonUIWidget
local function OnEnter(widget)
    RegisterForClicks(widget, E.ON_ENTER)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)

    -- handle stuff before event
    ---@param down boolean true if the press is KeyDown
    --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, function(w, event, key, down)
    --    RegisterForClicks(w, E.MODIFIER_STATE_CHANGED, down)
    --end, widget)
end

---@param widget ButtonUIWidget
local function OnLeave(widget)
    --RegisterMacroEvent(widget)
    if not widget:IsMacro() then
        --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)
        widget:UnregisterEvent(E.MODIFIER_STATE_CHANGED)
    end
    RegisterForClicks(widget, E.ON_LEAVE)
end

local function OnClick(btn, mouseButton, down)
    --p:log(20, 'SecureHookScript| Actionbar: %s', pformat(btn.widget:GetActionbarInfo()))
    btn:RegisterForClicks(WU:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
    if not PH:IsPickingUpSomething() then return end
    OnReceiveDrag(btn)
end

---@param widget ButtonUIWidget
---@param event string Event string
local function OnUpdateButtonCooldown(widget, event)
    widget:UpdateCooldown()
    local cd = widget:GetCooldownInfo();
    if (cd == nil or cd.icon == nil) then return end
    widget:SetCooldownTextures(cd.icon)
end

---@param widget ButtonUIWidget
---@param event string Event string
local function OnUpdateButtonState(widget, event)
    if not widget.button:IsShown() then return end
    widget:UpdateState()
end

---@param widget ButtonUIWidget
---@param event string Event string
local function OnUpdateButtonUsable(widget, event)
    if not widget.button:IsShown() then return end
    WU:UpdateUsable(widget)
end

---@param widget ButtonUIWidget
---@param event string Event string
local function OnBagUpdateDelayed(widget, event)
    if not widget.button:IsShown() then return end
    widget:UpdateItemState()
end

---#### Non-Instant Start-Cast Handler
---@param widget ButtonUIWidget
---@param event string Event string
local function OnSpellCastStart(widget, event, ...)
    if not widget.button:IsShown() then return end
    local unitTarget, castGUID, spellID = ...
    if 'player' ~= unitTarget then return end
    local profileButton = widget:GetConfig()
    if widget:IsMatchingItemSpellID(spellID, profileButton)
            or widget:IsMatchingSpellID(spellID, profileButton) then
        widget:SetHighlightInUse()
    end
end

---#### Non-Instant Stop-Cast Handler
---@param widget ButtonUIWidget
---@param event string Event string
local function OnSpellCastStop(widget, event, ...)
    if not widget.button:IsShown() then return end

    local unitTarget, castGUID, spellID = ...
    if 'player' ~= unitTarget then return end
    local profileButton = widget:GetConfig()
    if widget:IsMatchingItemSpellID(spellID, profileButton)
            or widget:IsMatchingSpellID(spellID, profileButton) then
        widget:ResetHighlight()
    end
end

---@param widget ButtonUIWidget
---@param event string
local function OnPlayerControlLost(widget, event, ...)
    if not widget.buttonData:IsHideWhenTaxi() then return end
    WU:SetEnabledActionBarStatesDelayed(false, 1)
end

---@param widget ButtonUIWidget
---@param event string
local function OnPlayerControlGained(widget, event, ...)
    --p:log('Event[%s] received flying=%s', event, flying)
    if not widget.buttonData:IsHideWhenTaxi() then return end
    WU:SetEnabledActionBarStatesDelayed(true, 2)
end

---@param widget ButtonUIWidget
---@param event string
local function OnSpellCastSent(widget, event, ...)
    local castingUnit, _, _, spellID = ...
    if not 'player' == castingUnit then return end
    if not ('player' == castingUnit and widget:IsMatchingMacroOrSpell(spellID)) then return end
    widget.button:SetButtonState('NORMAL')

    C_Timer.After(0.5, function()
        widget:Fire('OnAfterSpellCastSent')
    end)
end

---@param _widget ButtonUIWidget
---@param event string
local function OnSpellCastFailedQuiet(_widget, event, ...)
    local castingUnit, _, spellID = ...
    if not 'player' == castingUnit then return end
    if not ('player' == castingUnit and _widget:IsMatchingMacroOrSpell(spellID)) then return end

    _widget.button:SetButtonState('NORMAL')
end

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
---Font Flags: OUTLINE, THICKOUTLINE, MONOCHROME
---@see "https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont"
---@param b ButtonUI The button UI
local function CreateIndexTextFontString(b)
    local font = LSM:Fetch(LSM.MediaType.FONT, LSM.DefaultMedia.font)
    local fs = b:CreateFontString(b, "OVERLAY", "NumberFontNormalSmallGray")
    local fontName, fontHeight = fs:GetFont()
    fs:SetFont(fontName, fontHeight - 1, "OUTLINE")
    --fs:SetFont(font, 9, "THICKOUTLINE")
    fs:SetTextColor(100/255, 100/255, 100/255)
    --fs:SetTextColor(200/255, 200/255, 200/255)
    fs:SetPoint("BOTTOMLEFT", 4, 4)
    return fs
end

---Font Flags: OUTLINE, THICKOUTLINE, MONOCHROME
---@see "https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont"
---@param b ButtonUI The button UI
local function CreateKeybindTextFontString(b)
    local fs = b:CreateFontString(b, "OVERLAY", "NumberFontNormalSmallGray")
    --local fontName, fontHeight, fontFlags = fs:GetFont()
    --fs:SetFont(fontName, fontHeight, "OUTLINE")
    fs:SetTextColor(200/255, 200/255, 200/255)
    fs:SetPoint("TOP", 2, -2)
    return fs
end

---@param widget ButtonUIWidget
---@param name string The widget name.
local function RegisterWidget(widget, name)
    assert(widget ~= nil)
    assert(name ~= nil)

    local WidgetBase = AceGUI.WidgetBase
    widget.userdata = {}
    widget.events = {}
    widget.base = WidgetBase
    widget.frame.obj = widget
    local mt = {
        __tostring = function() return name  end,
        __index = WidgetBase
    }
    setmetatable(widget, mt)
end

---@param button ButtonUI
local function RegisterScripts(button)
    AceHook:SecureHookScript(button, 'OnClick', OnClick)

    ---@param btn ButtonUI
    button:SetScript("PreClick", function(btn, mouseButton, down)
        -- This prevents the button from being clicked
        -- on sequential drag-and-drops (one after another)
        if PH:IsPickingUpSomething(btn) then btn:SetAttribute("type", "empty") end
        RegisterForClicks(btn.widget, 'PreClick', down)
    end)

    button:SetScript('OnDragStart', OnDragStart)
    button:SetScript('OnReceiveDrag', OnReceiveDrag)

    ---@param b ButtonUI
    button:SetScript(E.ON_ENTER, function(b)
        OnEnter(b.widget)
        ---Receiver will get a func(widget, event) {}
        b.widget:Fire(E.ON_ENTER)
    end)
    ---@param b ButtonUI
    button:SetScript(E.ON_LEAVE, function(b)
        OnLeave(b.widget)
        ---Receiver will get a func(widget, event) {}
        b.widget:Fire(E.ON_LEAVE)
    end)

end

---@param w ButtonUIWidget
local function RegisterCallbacks(widget)

    --TODO: Tracks changing spells such as Covenant abilities in Shadowlands.
    --SPELL_UPDATE_ICON

    widget:RegisterEvent(E.SPELL_UPDATE_COOLDOWN, OnUpdateButtonCooldown, widget)
    widget:RegisterEvent(E.SPELL_UPDATE_USABLE, OnUpdateButtonUsable, widget)
    widget:RegisterEvent(E.BAG_UPDATE_DELAYED, OnBagUpdateDelayed, widget)
    widget:RegisterEvent(E.UNIT_SPELLCAST_START, OnSpellCastStart, widget)
    widget:RegisterEvent(E.UNIT_SPELLCAST_STOP, OnSpellCastStop, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_LOST, OnPlayerControlLost, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_GAINED, OnPlayerControlGained, widget)
    widget:RegisterEvent(E.UNIT_SPELLCAST_SENT, OnSpellCastSent, widget)
    widget:RegisterEvent(E.UNIT_SPELLCAST_FAILED_QUIET, OnSpellCastFailedQuiet, widget)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)

    widget:SetCallback(E.ON_RECEIVE_DRAG, OnReceiveDragCallback)
    widget:SetCallback('OnModifierStateChanged', OnModifierStateChangedCallback)

    --------------------------------------------
    ---@param w ButtonUIWidget
    --widget:SetCallback('OnAfterSpellCastSent', function(w, event)
    --    if w:IsMacro() then
    --        local msc = w:GetMacroSpellCooldown()
    --        if msc then
    --            local c = w:GetConfig()
    --            p:log('macro[%s]: %s/%s', c.macro.name, msc.spell.id, msc.spell.name)
    --        end
    --    end
    --end)
    --if widget:GetName() == "ActionbarPlusF1Button12" then
    --    p:log('Registered: %s', widget:GetName())
    --    ---@param w ButtonUIWidget
    --    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, function(w, event, key, down)
    --        --local c = w:GetConfig()
    --        --if not (IsShiftKeyDown() and down == 1) then return end
    --        C_Timer.After(0.05, function()
    --            w:Fire('OnModifierStateChanged')
    --        end)
    --    end, widget)
    --end


    -----SPELL_UPDATE_ICON Event fires once on login
    -----@see SpellBookDocumentation.lua
    -----@param w ButtonUIWidget
    --widget:RegisterEvent('SPELL_UPDATE_ICON', function(w, event)
    --    p:log('%s', event)
    --end, widget)

    ---@param w ButtonUIWidget
    --widget:RegisterEvent('UNIT_SPELLCAST_START', function(w, event, ...)
    --    local castingUnit, _, spellID = ...
    --    if not (castingUnit == 'player' and w:IsMatchingSpellID(spellID)) then return end
    --    --p:log('spellInfo: %s', s)
    --    --local s = _API:GetSpellInfo(spellID)
    --    p:log('%s: castingUnit: %s spellID: %s', event, castingUnit, spellID)
    --end, widget)

end

local function CreateFontString(button)
    local fs = button:CreateFontString(button:GetName() .. 'Text', nil, "NumberFontNormal")
    fs:SetPoint("BOTTOMRIGHT",-3, 2)
    button.text = fs
end

--[[-----------------------------------------------------------------------------
Widget Methods
-------------------------------------------------------------------------------]]
---@param widget ButtonUIWidget
local function ApplyMixins(widget) G:Mixin(widget, G:LibPack_ButtonMixin()) end

--[[-----------------------------------------------------------------------------
Builder Methods
-------------------------------------------------------------------------------]]
---@class ButtonUIWidgetBuilder
local _B = LogFactory:NewLogger('ButtonUIWidgetBuilder', {})

---Creates a new ButtonUI
---@param dragFrameWidget FrameWidget The drag frame this button is attached to
---@param rowNum number The row number
---@param colNum number The column number
---@param btnIndex number The button index number
---@return ButtonUIWidget
function _B:Create(dragFrameWidget, rowNum, colNum, btnIndex)

    local frameName = dragFrameWidget:GetName()
    local btnName = format('%sButton%s', frameName, tostring(btnIndex))

    ---@class ButtonUI
    local button = CreateFrame("Button", btnName, UIParent, SECURE_ACTION_BUTTON_TEMPLATE)
    button.indexText = CreateIndexTextFontString(button)
    button.keybindText = CreateKeybindTextFontString(button)

    RegisterScripts(button)
    CreateFontString(button)

    button:RegisterForDrag("LeftButton", "RightButton");
    button:RegisterForClicks("AnyDown");

    ---@class Cooldown
    local cooldown = CreateFrame("Cooldown", btnName .. 'Cooldown', button,  "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetSwipeColor(1, 1, 1)
    cooldown:SetCountdownFont(GameFontHighlightSmallOutline:GetFont())
    cooldown:SetDrawEdge(true)
    --cooldown:SetSize(0, 0)
    cooldown:SetEdgeScale(0.0)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetUseCircularEdge(false)
    cooldown:SetPoint('CENTER')

    ---@class ButtonUIWidget : ButtonMixin @ButtonUIWidget extends ButtonMixin
    local widget = {
        ---@type ActionbarPlus
        addon = ABP,
        ---@type Logger
        p = p,
        ---@type Profile
        profile = P,
        ---@type number
        index = btnIndex,
        ---@type number
        frameIndex = dragFrameWidget:GetIndex(),
        ---@type string
        buttonName = btnName,
        ---@type FrameWidget
        dragFrame = dragFrameWidget,
        ---@type ButtonUI
        button = button,
        ---@type ButtonUI
        frame = button,
        ---@type Cooldown
        cooldown = cooldown,
        ---@type table
        cooldownInfo = nil,
        ---Don't make this 'LOW'. ElvUI AFK Disables it after coming back from AFK
        ---@type string
        frameStrata = 'MEDIUM',
        ---@type number
        buttonPadding = 2,
        ---@type table
        buttonAttributes = CC.ButtonAttributes,
        placement = { rowNum = rowNum, colNum = colNum },
    }
    AceEvent:Embed(widget)

    ---@type ButtonData
    local buttonData = ButtonDataBuilder:Create(widget)
    widget.buttonData =  buttonData
    button.widget, cooldown.widget, buttonData.widget = widget, widget, widget

    --for method, func in pairs(methods) do widget[method] = func end
    ApplyMixins(widget)
    RegisterWidget(widget, btnName .. '::Widget')
    RegisterCallbacks(widget)
    widget:Init()

    return widget
end

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@return ButtonUILib
local function NewLibrary()

    ---@class ButtonUILib
    local _L = LibStub:NewLibrary(M.ButtonUI, 1)

    ---@return ButtonUIWidgetBuilder
    function _L:WidgetBuilder() return _B end
    return _L
end

NewLibrary()

--local function OnEvent(self, event, key, down)
--    --if down == 1 then
--    --    print("pressed in", key)
--    --end
--    local macroIndex = 121
--    local spellID = GetMacroSpell(macroIndex)
--    p:log('key: %s shift: %s down: %s spellID: %s', key, IsShiftKeyDown(), down, tostring(spellID))
--
--end
--
--local f = CreateFrame("Frame")
--f:RegisterEvent("MODIFIER_STATE_CHANGED")
--f:SetScript("OnEvent", OnEvent)