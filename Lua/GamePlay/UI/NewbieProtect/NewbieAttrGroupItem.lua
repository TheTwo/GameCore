local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class NewbieAttrGroupItem : BaseTableViewProCell
local NewbieAttrGroupItem = class('NewbieAttrGroupItem', BaseTableViewProCell)

---@class NewbieAttrGroupItemParam
---@field textEffectName string
---@field textParam1 string
---@field textParam2 string

function NewbieAttrGroupItem:OnCreate()
    self.textEffectName = self:Text('p_text_1')
    self.textParam1 = self:Text('p_text_2')
    self.textParam2 = self:Text('p_text_3')
end

---@param param NewbieAttrGroupItemParam
function NewbieAttrGroupItem:OnFeedData(param)
    if not param then
        return
    end
    self.textEffectName.text = param.textEffectName
    self.textParam1.text = param.textParam1
    self.textParam2.text = param.textParam2
end


return NewbieAttrGroupItem