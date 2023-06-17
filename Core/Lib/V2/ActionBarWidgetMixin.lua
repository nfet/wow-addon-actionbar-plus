--[[-----------------------------------------------------------------------------
ActionBarWidgetMixin: Similar to FrameWidget
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p, pformat = O.Logger:NewLogger('ActionBarWidgetMixin'), ns.pformat

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarWidget ActionbarWidgetMixin
--- @class ActionbarWidgetMixin
local L = {
    index = -1,
    --- @type ActionBarFrame
    frame = nil,

    frameHandleHeight = 4,
    dragHandleHeight = 0,
    padding = 2,
    horizontalButtonPadding = 1,
    verticalButtonPadding = 1,

    --- @type FrameStrata
    frameStrata = 'MEDIUM',
    --- @type FrameLevel
    frameLevel = 1,
}
ns.O.ActionbarWidgetMixin = L


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionbarWidgetMixin
local function PropsAndMethods(o)

    --- ### Usage:
    --- ```
    --- frameWidget = CreateAndInitFromMixin('ActionBarWidgetMixin', actionBarFrame)
    --- ```
    function o:Init(actionBarFrame)
        self.frame = actionBarFrame
        self.frame.widget = self
    end


end; PropsAndMethods(L)
