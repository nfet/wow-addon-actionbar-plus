--[[-----------------------------------------------------------------------------
ActionButtonMixin: Similar to ButtonMixin.lua
-------------------------------------------------------------------------------]]

--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p, pformat = O.Logger:NewLogger('ActionButtonMixin'), ns.pformat

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
    --- @type ActionButton
    button = nil,
    --- See: Interface/FrameXML/ActionButtonTemplate.xml
    --- @type CooldownFrame
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
        self.button = actionButton
        self.button.widget = self
        self.cooldown = actionButton.cooldown
    end

end; PropsAndMethods(L)
