local BaseUIMediator = require('BaseUIMediator')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ActivityShopConst = require('ActivityShopConst')
---@class ActivityShopPackChooseTipsMediator : BaseUIMediator
local ActivityShopPackChooseTipsMediator = class('ActivityShopPackChooseTipsMediator', BaseUIMediator)

local ArrowDirectionDefine = {
    Up = 1,
    Down = -1,
}

function ActivityShopPackChooseTipsMediator:OnCreate()
    self.textTitle = self:Text('p_text_select_level', I18N.Get(ActivityShopConst.I18N_KEYS.TIPS_TITLE_OPTION))
    self.tableItems = self:TableViewPro('p_table_item')
    self.goArrow = self:GameObject('p_arrow')
    self.goContent = self:GameObject('p_content')
    self.goRoot = self:GameObject('')
    self.transform = self:RectTransform('p_content')
end

function ActivityShopPackChooseTipsMediator:OnOpened(param)
    self.itemList = param.itemList
    self.clickTrans = param.clickTrans
    self.slotIndex = param.slotIndex
    self.packIndex = param.packIndex
    self.offset = param.offset
    if self.clickTrans then
        self:SetPos(param.arrowDirection)
    end
    self:FillTable()

    g_Game.EventManager:AddListener(EventConst.ON_SELECT_CUSTOM_ITEM, Delegate.GetOrCreate(self, self.OnSelectCustomItem))
end

function ActivityShopPackChooseTipsMediator:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_CUSTOM_ITEM, Delegate.GetOrCreate(self, self.OnSelectCustomItem))
end

function ActivityShopPackChooseTipsMediator:OnSelectCustomItem(param)
    for _, item in ipairs(self.itemList) do
        if item.groupId== param.itemId then
            item.isSelected = param.isSelected
        else
            item.isSelected = false
        end
    end
    self:FillTable()
end

function ActivityShopPackChooseTipsMediator:FillTable()
    self.tableItems:Clear()
    for i = 1, #self.itemList do
        self.itemList[i].slotIndex = self.slotIndex
        self.itemList[i].packIndex = self.packIndex
        self.tableItems:AppendData(self.itemList[i])
    end
end

function ActivityShopPackChooseTipsMediator:SetPos(arrowDirection)
    UIHelper.SetOtherUIAnchor(self.goRoot.transform, self.clickTrans, CS.UnityEngine.Vector3.zero)
    self.goContent.transform.localPosition = self.offset
end

return ActivityShopPackChooseTipsMediator