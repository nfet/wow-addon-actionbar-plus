--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub


ABP_ActionBarMixin = {}

function ABP_ActionBarMixin:OnLoad()
    print('ActionBarMixin: OnLoad...')
    self:Show()
end
