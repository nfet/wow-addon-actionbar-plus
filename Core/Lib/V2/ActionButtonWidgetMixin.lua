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

    placement = { rowNum = -1, colNum = -1 },
    --- @type number
    buttonPadding = 1,
}
ns.O.ActionButtonWidgetMixin = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]


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

end; PropsAndMethods(L)
