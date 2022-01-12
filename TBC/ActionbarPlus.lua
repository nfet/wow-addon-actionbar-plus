---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by tony.
--- DateTime: 1/2/2022 5:43 PM
---
-- local _G, unpack, format = _G, table.unpackIt, string.format
local ADDON_NAME, LibStub  = ADDON_NAME, LibStub
local StaticPopupDialogs, StaticPopup_Show, ReloadUI, IsShiftKeyDown = StaticPopupDialogs, StaticPopup_Show, ReloadUI, IsShiftKeyDown
local PrettyPrint = PrettyPrint
local format, pformat = string.format, PrettyPrint.pformat
local ACELIB, MC = AceLibFactory, MacroIconCategories
local ART_TEXTURES = ART_TEXTURES
local TextureDialog = ABP_MacroTextureDialog
local DEBUG_DIALOG_GLOBAL_FRAME_NAME = 'ABP_DebugPopupDialogFrame'
--local TEXTURE_DIALOG_GLOBAL_FRAME_NAME = 'ABP_DebugPopupDialogFrame'

local MAJOR, MINOR = ADDON_NAME .. '-1.0', 1 -- Bump minor on changes
local A = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
if not A then return end
ABP = A

local ACEDB, ACEDBO, ACECFG, ACECFGD = unpack(ACELIB:GetAddonAceLibs())
local libModules = WidgetLibFactory:GetAddonStdLibs()
local C, P, B, BF = unpack(libModules)
LogFactory:EmbedLogger(A)

-- ### Local Vars

--local macroIcons = nil
local debugDialog = nil

function A:RegisterSlashCommands()
    self:RegisterChatCommand("abp", "OpenConfig")
    self:RegisterChatCommand("cv", "SlashCommand_CheckVariable")
end

--A.categoryCache = {}

function A:CreateDebugPopupDialog()
    local AceGUI = ACELIB:GetAceGUI()
    local frame = AceGUI:Create("Frame")
    -- The following makes the "Escape" close the window
    _G[DEBUG_DIALOG_GLOBAL_FRAME_NAME] = frame.frame
    table.insert(UISpecialFrames, DEBUG_DIALOG_GLOBAL_FRAME_NAME)

    frame:SetTitle("Debug Frame")
    frame:SetStatusText('')
    frame:SetCallback("OnClose", function(widget)
        widget:SetTextContent('')
        widget:SetStatusText('')
    end)
    frame:SetLayout("Flow")
    --frame:SetWidth(800)

    -- PrettyPrint.format(obj)
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel('')
    editbox:SetText('')
    editbox:SetFullWidth(true)
    editbox:SetFullHeight(true)
    editbox.button:Hide()
    frame:AddChild(editbox)
    frame.editBox = editbox

    function frame:SetTextContent(text)
        self.editBox:SetText(text)
    end
    function frame:SetIcon(iconPathOrId)
        if not iconPathOrId then return end
        self.iconFrame:SetImage(iconPathOrId)
    end

    frame:Hide()
    return frame
end


--function A:FetchMacroIcons()
--    if macroIcons == nil or table.isEmpty(macroIcons) then macroIcons = GetMacroItemIcons() end
--    return macroIcons
--end

--function A:CreateTexturePopupDialog()
--    local iconSize = 50
--    local defaultIcon = TEXTURE_EMPTY
--
--    local AceGUI = ACELIB:GetAceGUI()
--    local frame = AceGUI:Create("Frame")
--
--    -- The following makes the "Escape" close the window
--    _G[TEXTURE_DIALOG_GLOBAL_FRAME_NAME] = frame.frame
--    table.insert(UISpecialFrames, TEXTURE_DIALOG_GLOBAL_FRAME_NAME)
--
--    frame:SetTitle("Macro Icons")
--    frame:SetStatusText('')
--    frame:SetCallback("OnClose", function(widget)
--        widget:SetStatusText('')
--    end)
--    frame:SetLayout("Flow")
--    --frame:SetWidth(700)
--    --frame:SetHeight(700)
--    frame.iconsScrollFrame = nil
--
--    local iconCategoryDropDown = AceGUI:Create("Dropdown")
--    iconCategoryDropDown:SetLabel("Category:")
--    iconCategoryDropDown:SetList(MC:GetDropDownItems())
--    frame:AddChild(iconCategoryDropDown)
--
--    local ICON_PREFIX = 'Interface/Icons/'
--    local function toIconName(iconPath)
--        return string.replace(iconPath, ICON_PREFIX, '')
--    end
--
--    local function onValueChanged(selectedCategory)
--        local categoryItems = A.categoryCache[selectedCategory]
--        if categoryItems == nil or table.isEmpty(categoryItems) then
--            --self:log(1, 'Retrieving category items: %s', selectedCategory)
--            categoryItems = MC:GetItemsByCategory(macroIcons, selectedCategory)
--            A.categoryCache[selectedCategory] = categoryItems
--        end
--        frame:SetList(categoryItems)
--        frame.iconsScrollFrame:ReleaseChildren()
--
--        -- TODO: Toggle Children by Category (Cache)
--
--        for iconId, iconPath in pairs(categoryItems) do
--            local icon = AceGUI:Create("Icon")
--            icon:SetImage(iconPath)
--            icon:SetImageSize(iconSize, iconSize)
--            icon:SetRelativeWidth(0.09)
--            icon.iconDetails = {
--                id = iconId, path = iconPath,
--                getIconName = function() return toIconName(iconPath) end,
--                getTooltip = function()
--                    return format("%s (%s)", iconPath, iconId)
--                end,
--            }
--            icon:SetCallback('OnClick', function(widget)
--                frame:SetEnteredIcon(widget.iconDetails.path)
--                frame:SetIconPath(widget.iconDetails.id, widget.iconDetails.getIconName())
--            end)
--            icon:SetCallback('OnEnter', function(widget)
--                GameTooltip:SetOwner(widget.frame, ANCHOR_TOPLEFT)
--                GameTooltip:SetText(widget.iconDetails.getTooltip())
--            end)
--            icon:SetCallback('OnLeave', function(widget)
--                GameTooltip:Hide()
--            end)
--            frame.iconsScrollFrame:AddChild(icon)
--        end
--    end
--
--    iconCategoryDropDown:SetCallback("OnValueChanged", function(choice)
--        onValueChanged(choice:GetValue())
--    end)
--
--    local baseWidth = 500
--    local iconDropDown = AceGUI:Create("Dropdown")
--    iconDropDown:SetLabel("Icon:")
--    iconDropDown:SetWidth(baseWidth)
--    iconDropDown:SetList({})
--    iconDropDown:SetCallback("OnValueChanged", function(choice)
--        -- choice is the drop-down list
--        -- frame:SetTextContent(PrettyPrint.pformat(choice))
--        local iconId = choice:GetValue()
--        local iconTextPath = ART_TEXTURES[tonumber(iconId)]
--        frame:SetSelectedIcon(iconId)
--        frame:SetEnteredIcon(iconTextPath)
--        frame:SetIconPath(iconId, toIconName(iconTextPath))
--    end )
--    frame:AddChild(iconDropDown)
--
--    local iconFrameByDropDown = AceGUI:Create("Icon")
--    iconFrameByDropDown:SetImage(defaultIcon)
--    iconFrameByDropDown:SetImageSize(iconSize, iconSize)
--    --iconFrameByDropDown:SetLabel("''")
--    --ic:SetAttribute('type', 'spell')
--    --ic:SetAttribute('spell', 'Cooking')
--    frame:AddChild(iconFrameByDropDown)
--
--    local iconEditbox = AceGUI:Create("EditBox")
--    iconEditbox:SetLabel("or Select Icon By ID or Texture Path:")
--    iconEditbox:SetWidth(baseWidth)
--    iconEditbox:SetCallback("OnEnterPressed", function(widget, event, text)
--        local value = ICON_PREFIX .. text
--        if type(tonumber(text)) == 'number' then
--            value = text
--        end
--        frame:SetEnteredIcon(value)
--    end)
--    frame:AddChild(iconEditbox)
--
--    local iconFrameByInput = AceGUI:Create("Icon")
--    -- ic:SetImage("Interface\\Icons\\inv_misc_note_05")
--    iconFrameByInput:SetImage(defaultIcon)
--    iconFrameByInput:SetImageSize(iconSize, iconSize)
--    frame:AddChild(iconFrameByInput)
--
--    local iconsScrollFrame = AceGUI:Create("ScrollFrame")
--    iconsScrollFrame:SetFullHeight(true)
--    iconsScrollFrame:SetFullWidth(true)
--    iconsScrollFrame:SetLayout("Flow")
--
--    --function iconsScrollFrame:HasChildren()
--    --    return false
--    --end
--    --function iconsScrollFrame:SetVisibleState(self, isVisible)
--    --    local children = self.children
--    --    print('children:', children)
--    --    for i = 1, #children do
--    --        --AceGUI:Hide(children[i])
--    --        if isVisible then
--    --            children[i].frame:Show()
--    --        else
--    --            children[i].frame:Hide()
--    --        end
--    --        --children[i] = nil
--    --    end
--    --end
--
--    frame:AddChild(iconsScrollFrame)
--    frame.iconsScrollFrame = iconsScrollFrame
--
--    -- ################################
--
--    function frame:SetSelectedIcon(iconPathOrId)
--        if not iconPathOrId then return end
--        iconFrameByDropDown:SetImage(iconPathOrId)
--    end
--    function frame:SetEnteredIcon(iconPathOrId)
--        if not iconPathOrId then return end
--        iconFrameByInput:SetImage(iconPathOrId)
--    end
--    function frame:SetIconPath(iconId, iconPath)
--        iconEditbox:SetText(iconPath)
--        frame:SetStatusText(format("%s (%s)", iconPath, iconId))
--    end
--    function frame:SetList(list)
--        iconDropDown:SetList(list)
--    end
--
--    function frame:SetSelectedCategory(category)
--        iconCategoryDropDown:SetValue(category)
--        onValueChanged(category)
--    end
--
--    --frame:SetSelectedCategory('Misc')
--    frame:Hide()
--    return frame
--end

local function listContains(list, path)
    for _,v in ipairs(list) do
        local matchText = '_' .. string.lower(v)
        if string.find(string.lower(path), matchText) then 
            print('match: path:', path, 'v', v)
            return true 
        end
    end
    return false
end

local function filter(iconList, categories)
    local list = {}
    for _,iconId in ipairs(iconList) do
        local path = ART_TEXTURES[iconId]
        if path ~= nil then
            -- print('insert', path)
            if not listContains(categories, path) then
                table.insert(list, {
                    id = iconId,
                    path = path
                })
            end
        end
    end
    return list
end

function A:ShowTextureDialog()
    TextureDialog:Show()
end

function A:SlashCommand_CheckVariable(spaceSeparatedArgs)
    --self:log('vars: ', spaceSeparatedArgs)
    local vars = table.parseSpaceSeparatedVar(spaceSeparatedArgs)
    if table.isEmpty(vars) then return end
    local firstVar = vars[1]

    if firstVar == '<profile>' then
        self:HandleSlashCommand_ShowProfile()
        return
    end

    local firstObj = _G[firstVar]
    PrettyPrint.setup({ indent_size = 4, level_width = 120, show_all = true, depth_limit=5 })
    local strVal = PrettyPrint.pformat(firstObj)
    debugDialog:SetTextContent(strVal)
    debugDialog:SetStatusText(format('Var: %s type: %s', firstVar, type(firstObj)))
    debugDialog:Show()

end

function A:HandleSlashCommand_ShowProfile()
    PrettyPrint.setup({ show_all = true } )
    local profileData = self:GetCurrentProfileData()
    local strVal = PrettyPrint.pformat(profileData)
    local profileName = self.db:GetCurrentProfile()
    debugDialog:SetTextContent(strVal)
    debugDialog:SetStatusText(format('Current Profile Data for [%s]', profileName))
    debugDialog:Show()
end

function A:ShowDebugDialog(obj, optionalLabel)
    local text = nil
    local label = optionalLabel or ''
    if type(obj) ~= 'string' then
        text = PrettyPrint.pformat(obj)
    else
        text = tostring(nil)
    end
    debugDialog:SetTextContent(text)
    debugDialog:SetStatusText(label)
    debugDialog:Show()
end

function A:DBG(obj, optionalLabel) self:ShowDebugDialog(obj, optionalLabel) end
function A:TI()
    -- local macroIcons = GetMacroItemIcons()
    -- self:ShowTextureDialog(macroIcons, 'Macro Icons')
end

function A:RegisterKeyBindings()
    --SetBindingClick("SHIFT-T", self:Info())
    --SetBindingClick("SHIFT-F1", BoxerButton3:GetName())
    --SetBindingClick("ALT-CTRL-F1", BoxerButton1:GetName())

    -- Warning: Replaces F5 keybinding in Wow Config
    -- SetBindingClick("F5", BoxerButton3:GetName())
    -- TODO: Configure Button 1 to be the Boxer Follow Button (or create an invisible one)
    --SetBindingClick("SHIFT-R", BoxerButton1:GetName())
end

function A:OnProfileChanged()
    self:ConfirmReloadUI()
end

function A:ConfirmReloadUI()
    if IsShiftKeyDown() then
        ReloadUI()
        return
    end
    ShowReloadUIConfirmation()
end

function A:OpenConfig(_)
    ACECFGD:Open(ADDON_NAME)
end

function A:OnUpdate()
    self:log('OnUpdate called...')
end

-----@param isEnabled boolean Current enabled state
--function A:SetAddonState(isEnabled)
--    local enabledFrames = { 'ActionbarPlusF1', 'ActionbarPlusF2' }
--    for _,fn in ipairs(enabledFrames) do
--        local f = _G[fn]
--        if type(f.ShowGroup) == 'function' then
--            if isEnabled then f:ShowGroup()
--            else f:HideGroup() end
--        end
--    end
--end
--
--function A:SetAddonEnabledState(isEnabled)
--    if isEnabled then self:Enable()
--    else self:Disable() end
--end

-- AceAddon Hook
function A:OnEnable()
    local prefetch = false
    if not prefetch then return end

    local categories = MC:GetCategoryNames()
    local routines = {}
    self:log('Macro Icons Size: %s', #macroIcons)
    for _, cat in ipairs(categories) do
        local co = coroutine.create(function()
            self:log('Prefetching <Misc> macro icon category')
            --local category = 'Misc'
            local categoryItems = MC:GetItemsByCategory(macroIcons, cat)
            A.categoryCache[cat] = categoryItems
            self:log('Done prefetching <Misc> macro icon category: %s', tostring(A.categoryCache[cat]))
        end)
        routines[cat] = co
        coroutine.resume(co)
    end

    for _, cat in ipairs(categories) do
        assert('dead' == coroutine.status(routines[cat]), 'Invalid coroutine status')
    end
end

-- AceAddon Hook
function A:OnDisable()
    -- Log or print() doesn't work with ElvUI; works when ElvUI is disabled
    A:log('OnDisable...')
end

function A:InitDbDefaults()
    local profileName = self.db:GetCurrentProfile()
    local defaultProfile = P:CreateDefaultProfile(profileName)
    local defaults = { profile =  defaultProfile }
    self.db:RegisterDefaults(defaults)
    self.profile = self.db.profile
    if table.isEmpty(ABP_PLUS_DB.profiles[profileName]) then
        ABP_PLUS_DB.profiles[profileName] = defaultProfile
        --error(profileName .. ': ' .. table.toStringSorted(ABP_PLUS_DB.profiles[profileName]))
    end
end

function A:GetCurrentProfileData()
    return self.profile
end

function A:OnInitialize()
    -- Set up our database
    self.db = ACEDB:New(ABP_PLUS_DB_NAME)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self:InitDbDefaults()

    debugDialog = self:CreateDebugPopupDialog()

    for _, module in ipairs(libModules) do
        module:OnInitialize{ handler = A, profile= A.profile }
    end

    local options = C:GetOptions()
    -- Register options table and slash command
    ACECFG:RegisterOptionsTable(ADDON_NAME, options, { "abp_options" })
    --cfgDialog:SetDefaultSize(ADDON_NAME, 800, 500)
    ACECFGD:AddToBlizOptions(ADDON_NAME, ADDON_NAME)

    -- Get the option table for profiles
    options.args.profiles = ACEDBO:GetOptionsTable(self.db)

    self:RegisterSlashCommands()
    self:RegisterKeyBindings()

    --macroIcons = self:FetchMacroIcons()
end

-- ##################################################################################

function getBindingByName(bindingName)
    local bindCount = GetNumBindings()
    if bindCount <=0 then return nil end

    for i = 1, bindCount do
        local command,cat,key1,key2 = GetBinding(i)
        if bindingName == command then
            return { name = command, category = cat, key1 = key1, key2 = key2 }
        end
    end
    return nil
end

function getBarBindings(beginsWith)
    local bindCount = GetNumBindings()
    if bindCount <=0 then return nil end

    --print('beginsWith:', beginsWith)
    -- key: name, value: binding obj
    local bindings = {}
    for i = 1, bindCount do
        local command,cat,key1,key2 = GetBinding(i)
        --print('bindingName: ', command)
        if string.find(command, beginsWith) then
            local value = { name = command, category = cat, key1 = key1, key2 = key2 }
            local keyName = 'BINDING_NAME_' .. command
            local key = _G[keyName]
            if key then
                bindings[key] = value
            end
        end
    end
    return bindings
end

local function BindActions()
    local barIndex = 1
    local buttonIndex = 3
    local nameFormat = format('ABP_ACTIONBAR1_BUTTON3', barnIndex, buttonIndex)
    local frameDetails = ProfileInitializer:GetAllActionBarSizeDetails()

    local bindingNames = getBarBindings('ABP_ACTIONBAR1')
    --ABP:DBG(bindingNames, 'Binding Names')
    local button3Binding = bindingNames[BINDING_NAME_ABP_ACTIONBAR1_BUTTON3]
    --print('Binding[ABP_ACTIONBAR1_BUTTON3]', pformat(button3Binding))
    if button3Binding then
        if button3Binding.key1 then
            local button3 = 'ActionbarPlusF1Button3'
            ClearOverrideBindings(_G[button3]);
            SetOverrideBindingClick(_G[button3], true, button3Binding.key1, button3)
            -- TODO: Does not respond after binding change event, need to add a listener to event UPDATE_BINDINGS
            if button3Binding.key2 then
                SetOverrideBindingClick(_G[button3], true, button3Binding.key2, button3)
            end
        end
    end
    --LoadBindings(1);
end

function Binding_ActionBar1()
    ABP:DBG(ABP.profile, 'Current Profile')
end

function Binding_ActionBar2()
    ABP:ShowTextureDialog()
end

function Binding_ActionBar3(...)
    --local bindings = getBarBindings('ABP_ACTIONBAR1')
    --ABP:DBG(bindings, 'Key Bindings')
    BindActions()
end

local function BindingUpdated(frame, event)
    --PrettyPrint.setup({ show_all = true })
    --print('frame', frame:GetName(), 'event', event, 'arg3', arg3)
    --LoadBindings(1)
    --ABP:DBG(frame, 'frame')
    BindActions()
end

local function AddonLoaded(frame, event)

    if (event == 'UPDATE_BINDINGS') then
        BindingUpdated(frame, event)
        return
    end

    for _, module in ipairs(libModules) do module:OnAddonLoaded() end
    A:log("%s.%s initialized", MAJOR, MINOR)
    A:printf('Available commands: /abp to open config dialog.')
    A:printf('Right-click on the button drag frame to open config dialog.')
    A:printf('More at https://kapresoft.com/wow-addon-actionbar-plus')

    BindActions()

end



local frame = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent)
frame:SetScript("OnEvent", AddonLoaded)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent('UPDATE_BINDINGS')

--local bindingFrame = CreateFrame("Frame", ADDON_NAME .. "BindingFrame", UIParent)
--bindingFrame:SetScript("OnEvent", BindingUpdated)
--bindingFrame:RegisterEvent('UPDATE_BINDINGS')
-- Temp
--Profile = P

