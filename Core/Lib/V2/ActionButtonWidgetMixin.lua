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

---@param o ActionButtonWidgetMixin
local function PropsAndMethods(o)

    ---@param actionButton ActionButton
    function o:Init(actionButton)
        self.button = function() return actionButton end
        self.button().widget = function() return self end
        self.cooldown = function() return actionButton.cooldown end
        self.frameIndex = self.button():GetParent().index
    end

    function o:OnReceiveDragHandler(...)
        p:log('OnReceiveDragHandler[%s]: args=%s cursor=%s',
                self.button():GetName(), pformat({...}), pformat(O.API:GetCursorInfo()))
    end

end; PropsAndMethods(L)
