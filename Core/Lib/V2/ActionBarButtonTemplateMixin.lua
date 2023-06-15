--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local pformat = ns.pformat
local p = O.Logger:NewLogger('ActionBarButtonCode')
local ButtonEvents = ABP_ActionBarButtonEventsFrameMixin

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarButtonCode ActionBarControllerMixin | _CheckButton
--- @class ActionBarButtonCodeMixin
local L = {}
ABP_ActionBarButtonTemplateMixin = L

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionBarButtonCodeMixin | _CheckButton
local function PropsAndMethods(o)

    function o:OnLoad()
        p:log(10, 'OnLoad: %s buttonSize: %s', self:GetName(),
                tostring(self:GetAttribute("buttonSize")))

        ButtonEvents:RegisterFrame(self)

        -- cvar ActionButtonUseKeyDown set to 1
        self:RegisterForDrag("LeftButton", "RightButton")
        self:RegisterForClicks("AnyDown")
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:PreClick(button, down)
        p:log(10, 'PreClick')
        self:UpdateState(button, down)
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:PostClick(button, down)
        p:log(10, 'PostClick')
        self:UpdateState(button, down)
    end

    function o:OnDragStart(...)
        p:log('OnDragStart: %s', pformat({...}))
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:UpdateState(button, down)
        C_Timer.After(0.1, function()
            self:SetChecked(false)
        end)
    end

    -- This doesn't get called
    function o:OnEvent(event)
        p:log('ActionBarButtonCodeMixin::OnEvent: %s', self:GetName())
    end

end; PropsAndMethods(L)
