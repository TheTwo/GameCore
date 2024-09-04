local BaseTableViewProCell = require('BaseTableViewProCell')
local ActivityShopConst = require('ActivityShopConst')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
---@class ActivityShopPackOptionCell : BaseTableViewProCell
local ActivityShopPackOptionCell = class('ActivityShopPackOptionCell', BaseTableViewProCell)

function ActivityShopPackOptionCell:OnCreate()
    self.item = self:LuaObject('child_item_standard_s')
    self.btnChange = self:Button('p_btn_change', Delegate.GetOrCreate(self, self.OnBtnChangeClick))
    self.btnAdd = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnBtnAddClick))
end

function ActivityShopPackOptionCell:OnFeedData(param)
    if not param then
        return
    end
    self.btnAdd.gameObject:SetActive(param.isAdd)
    self.btnChange.gameObject:SetActive(param.canChange)
    if not param.isAdd then
        self.item:SetVisible(true)
        self.item:FeedData(param)
        self.onClick = param.onClickChange
    else
        self.item:SetVisible(false)
        self.onClick = param.onClickAdd
    end
end

function ActivityShopPackOptionCell:OnBtnChangeClick()
    if self.onClick then
        self.onClick()
    end
end

function ActivityShopPackOptionCell:OnBtnAddClick()
    if self.onClick then
        self.onClick()
    end
end

return ActivityShopPackOptionCell