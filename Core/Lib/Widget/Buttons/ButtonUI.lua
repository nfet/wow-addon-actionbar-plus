--[[-----------------------------------------------------------------------------
WoW Vars
-------------------------------------------------------------------------------]]
local GetCursorInfo, ClearCursor, CreateFrame, UIParent = GetCursorInfo, ClearCursor, CreateFrame, UIParent
local InCombatLockdown, GameFontHighlightSmallOutline = InCombatLockdown, GameFontHighlightSmallOutline
local C_Timer, C_PetJournal = C_Timer, C_PetJournal

--[[-----------------------------------------------------------------------------
LUA Vars
-------------------------------------------------------------------------------]]
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local pformat = ns.pformat
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local AO = O.AceLibFactory:A()
local AceEvent, AceGUI, AceHook = AO.AceEvent, AO.AceGUI, AO.AceHook

local String = O.String
local A, P, PH = O.Assert, O.Profile, O.PickupHandler

local WMX, ButtonMX = O.WidgetMixin, O.ButtonMixin
local E, WAttr = GC.E, GC.WidgetAttributes

local IsBlank = String.IsBlank
local AssertThatMethodArgIsNotNil = A.AssertThatMethodArgIsNotNil

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ButtonUIWidgetBuilder : WidgetMixin
local _B = LibStub:NewLibrary(M.ButtonUIWidgetBuilder)

--- @class ButtonUILib
local _L = LibStub:NewLibrary(M.ButtonUI, 1)
local p = O.LogFactory:NewLogger(M.ButtonUI)

--- @return ButtonUIWidgetBuilder
function _L:WidgetBuilder() return _B end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
--- @param cursorInfo CursorInfo
local function IsValidDragSource(cursorInfo)
    --p:log("IsValidDragSource| CursorInfo=%s", cursorInfo)
    if not cursorInfo or IsBlank(cursorInfo.type) then
        -- This can happen if a chat tab or others is dragged into
        -- the action bar.
        --p:log(20, 'Received drag event with invalid cursor info. Skipping...')w
        return false
    end
    return O.ReceiveDragEventHandler:IsSupportedCursorType(cursorInfo)
end

---TODO: See the following implementation to mimic keydown
--- - https://wowpedia.fandom.com/wiki/CVar_ActionButtonUseKeyDown
--- - https://www.wowinterface.com/forums/showthread.php?t=58768
--- @param widget ButtonUIWidget
--- @param down boolean true if the press is KeyDown
local function RegisterForClicks(widget, event, down)
    local useKeyDown = GetCVarBool("ActionButtonUseKeyDown")
    if E.ON_LEAVE == event then
        if useKeyDown then
            widget.button:RegisterForClicks('AnyDown')
        else
            widget.button:RegisterForClicks('AnyUp')
        end
    elseif E.ON_ENTER == event then
        --widget.button:RegisterForClicks(WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        if useKeyDown then
            widget.button:RegisterForClicks(WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        else
            widget.button:RegisterForClicks('AnyUp')
        end
    elseif E.MODIFIER_STATE_CHANGED == event or 'PreClick' == event or 'PostClick' == event then
        --widget.button:RegisterForClicks(down and WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        if useKeyDown then
            widget.button:RegisterForClicks(down and WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        else
            widget.button:RegisterForClicks('AnyUp')
        end
    end
end

--- @param btn ButtonUI
--- @param key string The key clicked
--- @param down boolean true if the press is KeyDown
local function OnPreClick(btn, key, down)
    local w = btn.widget
    if w:IsBattlePet() and C_PetJournal then
        -- todo next: use ace message
        C_PetJournal.SummonPetByGUID(w:GetBattlePetData().guid)
        return
    elseif w:CanChangeEquipmentSet() then
        if btn:IsDragging() then return end
        -- todo next: use ace message
        p:log(20, 'Equipment Clicked: %s', w:GetEquipmentSetData())
        C_EquipmentSet.UseEquipmentSet(w:GetEquipmentSetData().id)
        -- PUT_DOWN_SMALL_CHAIN
        -- GUILD_BANK_OPEN_BAG
        PlaySound(SOUNDKIT.GUILD_BANK_OPEN_BAG)
        ActionButton_ShowOverlayGlow(btn)
        C_Timer.After(0.8, function() ActionButton_HideOverlayGlow(btn) end)
        if not PaperDollFrame:IsVisible() then
            ToggleCharacter('PaperDollFrame')
            C_Timer.After(0.1, function() GearManagerToggleButton:Click() end)
        end
    end
    -- This prevents the button from being clicked
    -- on sequential drag-and-drops (one after another)
    if PH:IsPickingUpSomething(btn) then btn:SetAttribute("type", "empty") end
    RegisterForClicks(w, 'PreClick', down)
end

--- @param btn ButtonUI
--- @param key string The key clicked
--- @param down boolean true if the press is KeyDown
local function OnPostClick(btn, key, down)
    -- This prevents the button from being clicked
    -- on sequential drag-and-drops (one after another)
    RegisterForClicks(btn.widget, 'PreClick', down)
end

--- @param btnUI ButtonUI
local function OnDragStart(btnUI)
    --- @type ButtonUIWidget
    local w = btnUI.widget
    if w:IsEmpty() then return end

    if InCombatLockdown() or not WMX:IsDragKeyDown() then return end
    w:Reset()
    p:log(20, 'DragStarted| Actionbar-Info: %s', pformat(btnUI.widget:GetActionbarInfo()))

    PH:Pickup(btnUI.widget)

    w:SetButtonAsEmpty()
    w:ShowEmptyGrid()
    w:ShowKeybindText(true)
    w:Fire('OnDragStart')
end

--- @param btn _Button
--- @param texture _Texture
--- @param texturePath string
local function CreateMask(btn, texture, texturePath)
    local mask = btn:CreateMaskTexture()
    local topx, topy = 1, -1
    local botx, boty = -1, 1
    local C = GC.C
    mask:SetPoint(C.TOPLEFT, texture, C.TOPLEFT, topx, topy)
    mask:SetPoint(C.BOTTOMRIGHT, texture, C.BOTTOMRIGHT, botx, boty)
    mask:SetTexture(texturePath, C.CLAMPTOBLACKADDITIVE, C.CLAMPTOBLACKADDITIVE)
    texture.mask = mask
    texture:AddMaskTexture(mask)
    return mask
end

--- Used with `button:RegisterForDrag('LeftButton')`
--- @param btnUI ButtonUI
local function OnReceiveDrag(btnUI)
    AssertThatMethodArgIsNotNil(btnUI, 'btnUI', 'OnReceiveDrag(btnUI)')
    local cursorUtil = ns:CreateCursorUtil()
    if not cursorUtil:IsValid() then
        p:log(20, 'OnReceiveDrag| CursorInfo: %s isValid: false', pformat:B()(cursorUtil:GetCursor()))
        return false
    else
        p:log(20, 'OnReceiveDrag| CursorInfo: %s', pformat:B()(cursorUtil:GetCursor()))
    end
    ClearCursor()

    --- @type ReceiveDragEventHandler
    O.ReceiveDragEventHandler:Handle(btnUI, cursorUtil)

    --local hTexture = btnUI:GetHighlightTexture()
    --if hTexture and not hTexture.mask then
    --    print('creating mask')
    --    hTexture.mask = CreateMask(btnUI, hTexture, GC.Textures.TEXTURE_EMPTY_GRID)
    --end

    btnUI.widget:Fire('OnReceiveDrag')
end

---Triggered by SetCallback('event', fn)
--- @param widget ButtonUIWidget
local function OnReceiveDragCallback(widget) widget:UpdateStateDelayed(0.01) end

--- @param widget ButtonUIWidget
--- @param event string
--- @param mouseButtonPressed string LMOUSECLICK, etc...
--- @param down boolean 1 or true if the press is KeyDown
local function OnModifierStateChanged(widget, event, mouseButtonPressed, down)
    RegisterForClicks(widget, E.MODIFIER_STATE_CHANGED, down)
    if widget:IsMacro() then if down == 1 then widget:UpdateMacroState() end end
end

--- @param widget ButtonUIWidget
local function OnBeforeEnter(widget)
    RegisterForClicks(widget, E.ON_ENTER)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)

    -- handle stuff before event
    --- @param down boolean true if the press is KeyDown
    --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, function(w, event, key, down)
    --    RegisterForClicks(w, E.MODIFIER_STATE_CHANGED, down)
    --end, widget)
end
--- @param widget ButtonUIWidget
local function OnBeforeLeave(widget)
    --RegisterMacroEvent(widget)
    if not widget:IsMacro() then
        --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)
        widget:UnregisterEvent(E.MODIFIER_STATE_CHANGED)
    end
    RegisterForClicks(widget, E.ON_LEAVE)
end
--- @param btn ButtonUI
local function OnEnter(btn)
    OnBeforeEnter(btn.widget)
    ---Receiver will get a func(widget, event) {}
    btn.widget:Fire(E.ON_ENTER)
end
--- @param btn ButtonUI
local function OnLeave(btn)
    OnBeforeLeave(btn.widget)
    ---Receiver will get a func(widget, event) {}
    btn.widget:Fire(E.ON_LEAVE)
end

local function OnClick_SecureHookScript(btn, mouseButton, down)
    --p:log(20, 'SecureHookScript| Actionbar: %s', pformat(btn.widget:GetActionbarInfo()))
    btn:RegisterForClicks(WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
    if not PH:IsPickingUpSomething() then return end
    OnReceiveDrag(btn)
end

--- @param widget ButtonUIWidget
--- @param event string Event string
local function OnUpdateButtonCooldown(widget, event)
    widget:UpdateCooldown()
    local cd = widget:GetCooldownInfo();
    if (cd == nil or cd.icon == nil) then return end
    widget:SetCooldownTextures(cd.icon)
end

--- @param widget ButtonUIWidget
--- @param event string Event string
local function OnUpdateButtonUsable(widget, event)
    if not widget.button:IsShown() then return end
    widget:UpdateUsable()
end

--- @param widget ButtonUIWidget
--- @param event string Event string
local function OnSpellUpdateUsable(widget, event)
    if not widget.button:IsShown() then return end
    widget:UpdateRangeIndicator()

    OnUpdateButtonUsable(widget, event)
end

--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerControlLost(widget, event, ...)
    if not widget:IsHideWhenTaxi() then return end
    C_Timer.After(1, function()
        local playerOnTaxi = UnitOnTaxi(GC.UnitId.player)
        p:log(10, 'Player on Taxi: %s [%s]', playerOnTaxi, GetTime())
        if playerOnTaxi ~= true then return end
        WMX:ShowActionbarsDelayed(false, 1)
    end)
end

--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerControlGained(widget, event, ...)
    --p:log('Event[%s] received flying=%s', event, flying)
    if not widget:IsHideWhenTaxi() then return end
    WMX:ShowActionbarsDelayed(true, 2)
end

--- @see "UnitDocumentation.lua"
--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerTargetChanged(widget, event) widget:UpdateRangeIndicator() end

--- @see "UnitDocumentation.lua"
--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerTargetChangedDelayed(widget, event)
    C_Timer.After(0.1, function() OnPlayerTargetChanged(widget, event) end)
end
local function OnPlayerStartedMoving(widget, event) OnPlayerTargetChangedDelayed(widget, event) end
--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param widget ButtonUIWidget
--- @param name string The widget name.
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

--- @param button ButtonUI
local function RegisterScripts(button)
    AceHook:SecureHookScript(button, 'OnClick', OnClick_SecureHookScript)

    button:SetScript("PreClick", OnPreClick)
    button:SetScript("PostClick", OnPostClick)

    button:SetScript('OnDragStart', OnDragStart)
    button:SetScript('OnReceiveDrag', OnReceiveDrag)
    button:SetScript(E.ON_ENTER, OnEnter)
    button:SetScript(E.ON_LEAVE, OnLeave)
end

--- @param widget ButtonUIWidget
local function RegisterCallbacks(widget)

    --TODO: Tracks changing spells such as Covenant abilities in Shadowlands.
    --SPELL_UPDATE_ICON

    --TODO next Move at the frame level
    widget:RegisterEvent(E.SPELL_UPDATE_COOLDOWN, OnUpdateButtonCooldown, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_LOST, OnPlayerControlLost, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_GAINED, OnPlayerControlGained, widget)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)
    widget:RegisterEvent(E.PLAYER_STARTED_MOVING, OnPlayerStartedMoving, widget)
    widget:RegisterEvent(E.SPELL_UPDATE_USABLE, OnSpellUpdateUsable, widget)

    -- Callbacks (fired via Ace Events)
    widget:SetCallback(E.ON_RECEIVE_DRAG, OnReceiveDragCallback)

    --- @param w ButtonUIWidget
    widget:SetCallback("OnEnter", function(w)
        if not GetCursorInfo() then return end
        w:SetHighlightEmptyButtonEnabled(true)
    end)
    widget:SetCallback("OnLeave", function(w)
        if not GetCursorInfo() then return end
        w:SetHighlightEmptyButtonEnabled(false)
    end)
end

--[[-----------------------------------------------------------------------------
Builder Methods
-------------------------------------------------------------------------------]]

---Creates a new ButtonUI
--- @param dragFrameWidget FrameWidget The drag frame this button is attached to
--- @param rowNum number The row number
--- @param colNum number The column number
--- @param btnIndex number The button index number
--- @return ButtonUIWidget
function _B:Create(dragFrameWidget, rowNum, colNum, btnIndex)

    local btnName = GC:ButtonName(dragFrameWidget.index, btnIndex)

    --- @class __ButtonUI
    local button = CreateFrame("Button", btnName, UIParent, GC.C.SECURE_ACTION_BUTTON_TEMPLATE)
    --- @alias ButtonUI __ButtonUI|_Button

    --local button = CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    button.text = WMX:CreateFontString(button)
    button.indexText = WMX:CreateIndexTextFontString(button)
    button.keybindText = WMX:CreateKeybindTextFontString(button)

    RegisterScripts(button)

    -- todo next: add ActionButtonUseKeyDown to options UI; add to abp_info
    --            iterate through all buttons and call #RegisterForClicks()
    -- /run SetCVar("ActionButtonUseKeyDown", 1)
    -- /run SetCVar("ActionButtonUseKeyDown", 0)
    -- /dump GetCVarBool("ActionButtonUseKeyDown")

    button:RegisterForDrag("LeftButton", "RightButton");
    button:RegisterForClicks("AnyDown", "AnyUp");

    --- @class Cooldown
    local cooldown = CreateFrame("Cooldown", btnName .. 'Cooldown', button,  "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetSwipeColor(1, 1, 1)
    cooldown:SetCountdownFont(GameFontHighlightSmallOutline:GetFont())
    cooldown:SetDrawEdge(true)
    cooldown:SetEdgeScale(0.0)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetUseCircularEdge(false)
    cooldown:SetPoint('CENTER')

    --- @class ButtonUIWidget : ButtonMixin
    local widget = {
        --- @type ActionbarPlus
        addon = ABP,
        --- @type Profile
        profile = P,
        --- @type number
        index = btnIndex,
        --- @type number
        frameIndex = dragFrameWidget:GetIndex(),
        --- @type string
        buttonName = btnName,
        --- @type FrameWidget
        dragFrame = dragFrameWidget,
        --- @type ButtonUI
        button = button,
        --- @type ButtonUI
        frame = button,
        --- @type Cooldown
        cooldown = cooldown,
        --- @type table
        cooldownInfo = nil,
        ---Don't make this 'LOW'. ElvUI AFK Disables it after coming back from AFK
        --- @type string
        frameStrata = dragFrameWidget.frameStrata or 'MEDIUM',
        frameLevel = (dragFrameWidget.frameLevel + 100) or 100,
        --- @type number
        buttonPadding = 1,
        buttonAttributes = GC.ButtonAttributes,
        placement = { rowNum = rowNum, colNum = colNum },
    }
    button.widget, cooldown.widget = widget, widget

    AceEvent:Embed(widget)
    ButtonMX:Mixin(widget)

    RegisterWidget(widget, btnName .. '::Widget')
    RegisterCallbacks(widget)

    widget:InitWidget()

    -- This is for mouseover effect
    ----- @param w ButtonUIWidget
    --widget:SetCallback("OnEnter", function(w)
    --    w.dragFrame.frame:SetAlpha(1.0)
    --    w.dragFrame:ApplyForEachButtons(function(bw)
    --        bw.button:SetAlpha(1)
    --    end)
    --end)
    ----- @param w ButtonUIWidget
    --widget:SetCallback("OnLeave", function(w)
    --    w.dragFrame.frame:SetAlpha(0)
    --    w.dragFrame:ApplyForEachButtons(function(bw)
    --        bw.button:SetAlpha(0.4)
    --    end)
    --end)

    return widget
end
