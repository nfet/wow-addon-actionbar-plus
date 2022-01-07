local AssertNotNil = Assert.AssertNotNil
local WLIB, SpellAttributeSetter = WidgetLibFactory, SpellAttributeSetter
local ButtonAttributes, _API_Spell = ButtonAttributes, _API_Spell
local LOG = LogFactory

local P = WLIB:GetProfile()

local S = {}
LOG:EmbedLogger(S, 'SpellDragEventHandler')
SpellDragEventHandler = S

---@param spellCursorInfo table Structure `{ type = actionType, name='TODO', bookIndex = info1, bookType = info2, id = info3 }`
function S:Handle(btnUI, spellCursorInfo)
    if spellCursorInfo == nil or spellCursorInfo.id == nil then return end
    local spellInfo = _API_Spell:GetSpellInfo(spellCursorInfo.id)
    AssertNotNil(spellInfo, 'spellInfo')
    --self:logp('spellInfo', spellInfo)

    local actionbarInfo = btnUI:GetActionbarInfo()
    self:logp('ActionBar', actionbarInfo)
    local btnName = btnUI:GetName()
    local barData = P:GetBar(actionbarInfo.index)
    --local key = actionbarInfo.name .. btnName
    --P.profile[key] = P:GetTemplate().Button
    --local btnData = P.profile[key]
    --self:logp({ actionbar=actionbarInfo.name, frameIndex=actionbarInfo.index, value=barData })

    local btnData = barData.buttons[btnName] or P:GetTemplate().Button
    btnData.type = ButtonAttributes.SPELL
    btnData[ButtonAttributes.SPELL] = spellInfo
    barData.buttons[btnName] = btnData
    --P.profile.bars[actionbarInfo.name].buttons[btnName] = btnData
    --P.profile.bars[actionbarInfo.name] = barData
    self:logp('Saved', { actionbar=frameName, btn={ name=btnName, value=btnData }})

    SpellAttributeSetter(btnUI, btnData)
end
