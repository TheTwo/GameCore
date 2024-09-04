local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require("NotificationType")

---@class CommonSkillCardTableViewCell : BaseTableViewProCell
---@field data HeroConfigCache
local CommonSkillCardTableViewCell = class('CommonSkillCardTableViewCell', BaseTableViewProCell)

function CommonSkillCardTableViewCell:ctor()

end

function CommonSkillCardTableViewCell:OnCreate(param)
    
end


function CommonSkillCardTableViewCell:OnShow(param)
end

function CommonSkillCardTableViewCell:OnOpened(param)
end

function CommonSkillCardTableViewCell:OnClose(param)
end

function CommonSkillCardTableViewCell:OnFeedData(param)
    self._card = self:LuaObject(param.nodeName)
    self._card:FeedData(param.data)
    self._order = self:GameObject(param.orderName)
    self._orderText = self:Text(param.orderTextName)
    if (self._order) then
        self._order:SetActive(param.showOrder == true)
    end
    if (self._orderText) then
        self._orderText.text = param.orderText or ""
    end
end

function CommonSkillCardTableViewCell:Select(param)

end

function CommonSkillCardTableViewCell:UnSelect(param)

end


return CommonSkillCardTableViewCell;
