--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionBar')

--- @alias ActionBar ActionBarMixin | _Frame
--- @class ActionBarMixin
local L = {}
ABP_ActionBarMixin = L

---@param o ActionBarMixin | _Frame
local function PropsAndMethods(o)
    -- todo
end; PropsAndMethods(L)
