local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class CommonTipsInfoContentcell : BaseTableViewProCell
local CommonTipsInfoContentcell = class('CommonTipsInfoContentcell', BaseTableViewProCell)

---@class CommonTipsInfoContentCellParam
---@field content string
---@field num string
---@field state number

function CommonTipsInfoContentcell:OnCreate()
    self.goCheck = self:GameObject('p_icon_check')
    self.goDot = self:GameObject('p_icon_dot')
    self.textContent = self:Text('p_text_content')
    self.textContentNum = self:Text('p_text_content_num')
    self.statusContent = self:StatusRecordParent('')
end

---@param param CommonTipsInfoContentCellParam
function CommonTipsInfoContentcell:OnFeedData(param)
    if not param then
        return
    end

    self.textContent.text = param.content
    self.textContentNum.text = param.num
    if param.state then
        self.statusContent:ApplyStatusRecord(param.state)
    end
end

return CommonTipsInfoContentcell