--[[-----------------------------------------------------------------------------
ActionButtonMixin: Similar to ButtonMixin.lua
-------------------------------------------------------------------------------]]

--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p, pformat = O.Logger:NewLogger('ActionButtonWidgetMixin'), ns.pformat

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @alias ActionButtonWidget ActionButtonWidgetMixin
--- @class ActionButtonWidgetMixin
local L = {
    --- @type number
    index = -1,
    --- @type number
    frameIndex = -1,
    --- @type fun():ActionButton
    button = nil,
    --- See: Interface/FrameXML/ActionButtonTemplate.xml
    --- @type fun():CooldownFrame
    cooldown = nil,

    --- @type fun():Profile_Button
    config = nil,

    placement = { rowNum = -1, colNum = -1 },
    --- @type number
    buttonPadding = 1,
}
ns.O.ActionButtonWidgetMixin = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Removes a particular actionType data from Profile_Button
--- @param btnData Profile_Button
local function CleanupActionTypeData(btnData)
    local function removeElement(tbl, value)
        for i, v in ipairs(tbl) do if v == value then tbl[i] = nil end end
    end
    if btnData == nil or btnData.type == nil then return end
    local actionTypes = O.ActionType:GetOtherNamesExcept(btnData.type)
    for _, v in ipairs(actionTypes) do if v ~= nil then btnData[v] = {} end end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionButtonWidgetMixin
local function PropsAndMethods(o)

    ---@param actionButton ActionButton
    function o:Init(actionButton)
        self.button = function() return actionButton end
        self.button().widget = function() return self end
        self.cooldown = function() return actionButton.cooldown end
        self.frameIndex = self.button():GetParent().index
    end

    --- ### See: [UIHANDLER_OnReceiveDrag](https://wowpedia.fandom.com/wiki/UIHANDLER_OnReceiveDrag)
    function o:OnReceiveDragHandler()
        p:log(10, 'OnReceiveDragHandler[%s]: cursor=%s',
                self.button():GetName(), pformat(O.API:GetCursorInfo()))
        local cursor = ns:CreateCursorUtil()
        if not cursor:IsValid() then
            p:log(20, 'OnReceiveDrag| CursorInfo: %s isValid: false', pformat:B()(cursor:GetCursor()))
            return false else
        end

        p:log(20, 'OnReceiveDrag| CursorInfo: %s', pformat:B()(cursor:GetCursor()))
        --cursorUtil:ClearCursor()

        self:HandleCursor(cursor)

        --local hTexture = btnUI:GetHighlightTexture()
        --if hTexture and not hTexture.mask then
        --    print('creating mask')
        --    hTexture.mask = CreateMask(btnUI, hTexture, GC.Textures.TEXTURE_EMPTY_GRID)
        --end
        --self.widget:Fire('OnReceiveDrag')
    end

    ---@param cursor CursorUtil
    function o:HandleCursor(cursor)
        --- @type ReceiveDragEventHandler
        local handled = O.ReceiveDragEventHandler:HandleV2(self, cursor)
        if handled then cursor:ClearCursor() end
    end

    --- @return Profile_Button
    function o:config()
        local p = O.Profile:GetButtonData(self.frameIndex, self.button():GetName())
        CleanupActionTypeData(p)
        return p
    end

    --- @param type ActionTypeName One of: spell, item, or macro
    function o:GetButtonTypeData(type) return self:config()[type] end
    --- @return Profile_Spell
    function o:GetSpellData() return self:GetButtonTypeData('spell') end

    --- @return ButtonAttributes
    function o:GetButtonAttributes() return GC.ButtonAttributes end
    function o:ResetWidgetAttributes()
        if InCombatLockdown() then return end
        local button = self.button()
        for _, v in pairs(self:GetButtonAttributes()) do
            if not InCombatLockdown() then button:SetAttribute(v, nil) end
        end
    end

    --- @param icon string Blizzard Icon
    function o:SetIcon(icon)
        if not icon then return end
        local btn = self.button()
        btn:SetNormalTexture(icon)
        btn:SetPushedTexture(icon)
        btn:GetNormalTexture():SetAllPoints(btn)
    end

    --- Sets an attribute on the frame.
    --- @param name string
    --- @param value any
    function o:SetAttribute(name, value) self.button():SetAttribute(name, value) end

end; PropsAndMethods(L)
