local BaseUIComponent = require('BaseUIComponent')
local ActivityShopConst = require('ActivityShopConst')
local I18N = require('I18N')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local DBEntityPath = require('DBEntityPath')
---@class ActivityShopPackOptionContent : BaseUIComponent
local ActivityShopPackOptionContent = class('ActivityShopPackOptionContent', BaseUIComponent)

function ActivityShopPackOptionContent:OnCreate()
    self.arrows = {}
    self.selectedItemEachSlotEachPack = {}
    for i = 1, ActivityShopConst.PACK_NUM do
        self.arrows[i] = self:GameObject('p_arrow_' .. i)
        self.selectedItemEachSlotEachPack[i] = {}
    end
    self.textSubtitle = self:Text('p_text_subtitle', I18N.Get(ActivityShopConst.I18N_KEYS.GUIDE_OPTION))

    self.btnPurchase = self:Button('p_comp_btn_b', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.btnPurchaseText = self:Text('p_text')
    self.textExchangePoints = self:Text('p_text_num')
    self.goExchangePoints = self:GameObject('p_btn_recharge_points')

    self.textLimited = self:Text('p_text_limited')
    self.textLimitedNums = self:Text('p_text_limited_num')

    self.soldOut = self:GameObject('p_content_sold_out')
    self.textSoldOut = self:Text('p_text_content_sold_out', I18N.Get(ActivityShopConst.I18N_KEYS.SOLD_OUT))
    self.tableOption = self:TableViewPro('p_table_option_item')

    self.rectTableCellTemplate = self:RectTransform('p_item_cell')
    self.goCellTemplate = self:GameObject('p_item_cell')
end

function ActivityShopPackOptionContent:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_CUSTOM_ITEM, Delegate.GetOrCreate(self, self.OnSelectCustomItem))
    if self.goExchangePoints then
        self.goExchangePoints:SetActive(true)
    end
end

function ActivityShopPackOptionContent:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_CUSTOM_ITEM, Delegate.GetOrCreate(self, self.OnSelectCustomItem))
end

function ActivityShopPackOptionContent:OnFeedData(param)
    if not param then
        return
    end
    self.goCellTemplate:SetActive(false)
    self:OnSelectPack(param)
end

function ActivityShopPackOptionContent:OnSelectPack(packInfo)
    ---@type PackInfo
    self.info = packInfo
    self.info.numSlots = 0

    local packCfg = ConfigRefer.PayGoods:Find(self.info.packId)
    self.fixedItemId = packCfg:ItemGroupId()
    local chooseGoods = ConfigRefer.PayChooseGoods:Find(packCfg:ChooseItems())
    self.fixedItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.fixedItemId)[1]
    self.chooseItemsIds = {}
    for i = 1, chooseGoods:StageLength() do
        if chooseGoods:Stage(i):ChooseItemGroupsLength() ~= 0 then
            self.chooseItemsIds[i] = chooseGoods:Stage(i)
            self.info.numSlots = self.info.numSlots + 1
        end
    end
    self:UpdateOptionTable(self.info.index)
    self:SetSoldOutDisplay(self.info.isSoldOut)
    self.btnPurchaseText.text = string.format('%s %.2f', self.info.currency, self.info.price)
    self.textLimited.text = I18N.Get(ActivityShopConst.I18N_KEYS.GENERAL_LIMIT_TEXT)
    self.textLimitedNums.text = I18N.GetWithParams(ActivityShopConst.I18N_KEYS.GENERAL_LIMIT_NUM,
                                                    string.format(' %d/%d', self.info.limitNum - self.info.curNum, self.info.limitNum))
    self.textExchangePoints.text = '+' .. ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(self.info.packId)
    self:SetArrow(self.info.index)
end

function ActivityShopPackOptionContent:UpdateOptionTable(index)
    self.tableOption:Clear()
    for i = 1, #self.chooseItemsIds + 1 do
        if i == 1 then
            self.fixedItem.isAdd = false
            self.fixedItem.canChange = false
            self.tableOption:AppendData(self.fixedItem)
        else
            local data = {}
            if self.selectedItemEachSlotEachPack[index][i] ~= nil then
                local itemCfg = ModuleRefer.InventoryModule:
                    ItemGroupId2ItemArrays(self.selectedItemEachSlotEachPack[index][i].itemId)[1].configCell
                data = {
                    isAdd = false,
                    canChange = true and not self.info.isSoldOut,
                    configCell = itemCfg,
                    count = self.selectedItemEachSlotEachPack[index][i].count,
                    showTips = true,
                    showCount = true,
                    onClickChange = function()
                        self:OnOptionItemClick(i)
                    end,
                }
            else
                data = {
                    isAdd = true,
                    canChange = false,
                    onClickAdd = function()
                        self:OnOptionItemClick(i)
                    end,
                }
            end
            self.tableOption:AppendData(data)
        end
    end
end

function ActivityShopPackOptionContent:SetSoldOutDisplay(isSoldOut)
    self.soldOut:SetActive(isSoldOut)
    self.btnPurchase.gameObject:SetActive(not isSoldOut)
end

function ActivityShopPackOptionContent:SetBtnStatus(status)
    self.btnPurchase.gameObject:SetActive(status == ActivityShopConst.PACK_STATUS.LOCKED)
    self.soldOut:SetActive(status == ActivityShopConst.PACK_STATUS.UNLOCKED)
end

function ActivityShopPackOptionContent:SetArrow(index)
    for i, arrow in ipairs(self.arrows) do
        arrow:SetActive(index == i)
    end
end

function ActivityShopPackOptionContent:OnBtnClick()
    if self:GetSelectedNum(self.info.index) < self.info.numSlots then
        ModuleRefer.ToastModule:AddTopToast({content = I18N.Get(ActivityShopConst.I18N_KEYS.TIPS_ON_NO_CHOOSE)})
        for i = 2, self.info.numSlots + 1 do
            if self.selectedItemEachSlotEachPack[self.info.index][i] == nil then
                self:OnOptionItemClick(i)
                break
            end
        end
        return
    end
    local goodsId = self.info.packId
    local chooseItems = {}
    for _, info in pairs(self.selectedItemEachSlotEachPack[self.info.index]) do
        if info then
            table.insert(chooseItems, info.itemId)
        end
    end
    ModuleRefer.ActivityShopModule:PurchaseGoods(goodsId, chooseItems, false)
end

function ActivityShopPackOptionContent:IsItemSelected(itemGroupId, packIndex)
    for _, info in pairs(self.selectedItemEachSlotEachPack[packIndex]) do
        if info.itemId == itemGroupId then
            return true
        end
    end
    return false
end

function ActivityShopPackOptionContent:GetSelectedNum(packIndex)
    local num = 0
    for _, info in pairs(self.selectedItemEachSlotEachPack[packIndex]) do
        if info then
            num = num + 1
        end
    end
    return num
end

function ActivityShopPackOptionContent:OnOptionItemClick(index)
    if self.info.isSoldOut then
        return
    end
    local itemGroups = self.chooseItemsIds[index - 1]
    local itemList = {}
    for i = 1, itemGroups:ChooseItemGroupsLength() do
        local itemGroupId = itemGroups:ChooseItemGroups(i)
        local item = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)[1]
        item.isSelected = self:IsItemSelected(itemGroupId, self.info.index)
        item.groupId = itemGroupId
        item.name = I18N.Get(item.configCell:NameKey())
        itemList[i] = item
    end
    local data = {
        slotIndex = index,
        packIndex = self.info.index,
        itemList = itemList,
        clickTrans = self.tableOption:GetCell(index - 1).gameObject.transform,
        offset = CS.UnityEngine.Vector3(self.rectTableCellTemplate.rect.width / 2, 0, 0),
    }
    g_Game.UIManager:Open(UIMediatorNames.ActivityShopPackChooseTipsMediator, data)
end

function ActivityShopPackOptionContent:OnSelectCustomItem(param)
    if not param then
        return
    end
    local itemId = param.itemId
    local slot = param.slotIndex
    local packIndex = param.packIndex
    if param.isSelected then
        self.selectedItemEachSlotEachPack[packIndex][slot] = {
            itemId = itemId,
            count = param.count,
        }
    else
        self.selectedItemEachSlotEachPack[packIndex][slot] = nil
    end
    self:UpdateOptionTable(packIndex)
end

return ActivityShopPackOptionContent