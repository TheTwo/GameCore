local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local BattlePassConst = require("BattlePassConst")
local PlayerAutoRewardOpParameter = require("PlayerAutoRewardOpParameter")
local ConfigRefer = require("ConfigRefer")
local PayConfirmHelper = require("PayConfirmHelper")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local Utils = require("Utils")
local ActivityRewardType = require("ActivityRewardType")

---@class BattlePassPurchaseLvlMediator : BaseUIMediator
local BattlePassPurchaseLvlMediator = class("BattlePassPurchaseLvlMediator", BaseUIMediator)
local I18N_KEYS = BattlePassConst.I18N_KEYS

function BattlePassPurchaseLvlMediator:OnCreate()
    self.textDesc = self:Text("p_text_desc", I18N_KEYS.BUY_LVL_DESC)
    self.tableReward = self:TableViewPro('p_table_reward')

    self.luaSetBar = self:LuaObject('child_set_bar')
    self.inputField = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEditEnd))
    self.textInputLimit = self:Text('p_text_input_quantity')

    self.textPurchase = self:Text("p_text_purchase", I18N_KEYS.BUY_LVL_PAY_TXT)

    self.btnPurchase = self:Button('child_comp_btn_e_l', Delegate.GetOrCreate(self, self.OnBtnPurchaseClicked))
    self.imgCostItem = self:Image('p_icon_e')
    self.textCostItemNumGreen = self:Text('p_text_num_green_e')
    self.textCostItemNumRed = self:Text('p_text_num_red_e')
    self.textBtn = self:Text('p_text_e', I18N_KEYS.BUY_LVL)

    self.luaResource = self:LuaObject('child_resource')
    self.luaBackGround = self:LuaObject('child_popup_base_m')
end

function BattlePassPurchaseLvlMediator:OnOpened(param)
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self.curLvl = ModuleRefer.BattlePassModule:GetLevelByCfgId(self.cfgId)
    self.minNum = 1
    self.maxNum = ModuleRefer.BattlePassModule:GetMaxLevelByCfgId(self.cfgId) - self.curLvl
    self.textInputLimit.text = string.format(' / %d', self.maxNum)
    ---@type CommonNumberSliderData
    local setBarData = {
        minNum = 1,
        maxNum = self.maxNum,
        callBack = Delegate.GetOrCreate(self, self.OnSetBarValueChanged),
    }
    ---@type table<number, table<number, ItemIconData>>
    self.appenedDataEachLvl = {}
    self.dataLength = 0

    ---@type table<number, table<number, ItemIconData>>
    self.appendData = {}
    self.itemId2CellIndex = {}

    self.luaSetBar:FeedData(setBarData)
    self.rewardLvlUpperBound = self.curLvl
    self.curNum = self.luaSetBar.curNum
    self.inputField.text = tostring(self.luaSetBar.curNum)
    self.textDesc.text = I18N.GetWithParams(I18N_KEYS.BUY_LVL_DESC, self.curNum + self.curLvl)
    self:UpdateBtnInfo(self.curNum)
    self.tableReward:Clear()
    self:AddRewardItem(self.rewardLvlUpperBound + 1)

    self.luaResource:FeedData({
        itemId = self.costItemInfo.id,
        isShowPlus = false,
    })

    self.luaBackGround:FeedData({
        title = I18N_KEYS.BUY_LVL_PAY_TXT,
    })
end

function BattlePassPurchaseLvlMediator:OnClose()

end

function BattlePassPurchaseLvlMediator:OnEditEnd(text)
    if not text or text == '' then
        text = tostring(self.curNum or 1)
    end
    self.curNum = math.clamp(tonumber(text), self.minNum, self.maxNum)
    self.inputField.text = tostring(self.curNum)
    self.luaSetBar:OutInputChangeSliderValue(self.curNum)
    self:OnSetBarValueChanged(self.curNum)
end

function BattlePassPurchaseLvlMediator:OnSetBarValueChanged(curNum)
    self.curNum = curNum
    self.inputField.text = tostring(curNum)
    self.textDesc.text = I18N.GetWithParams(I18N_KEYS.BUY_LVL_DESC, curNum + self.curLvl)
    self:UpdateBtnInfo(curNum)
    self:AddRewardItem(curNum + self.curLvl)
    self:RemoveRewardItem(curNum + self.curLvl)
    -- self.tableReward:SetDataFocus(self.dataLength - 1, 0, CS.TableViewPro.MoveSpeed.Fast)
end

function BattlePassPurchaseLvlMediator:UpdateBtnInfo(curNum)
    self.costItemInfo = ModuleRefer.BattlePassModule:GetCostItemInfoForPurchaseLvl(self.cfgId, curNum)
    self.curOwnedCostItemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.costItemInfo.id)
    local costItemCfg = ConfigRefer.Item:Find(self.costItemInfo.id)
    g_Game.SpriteManager:LoadSprite(costItemCfg:Icon(), self.imgCostItem)
    self.textCostItemNumGreen.text = tostring(self.costItemInfo.count)
    self.textCostItemNumRed.text = tostring(self.costItemInfo.count)
    self.textCostItemNumGreen.gameObject:SetActive(self.curOwnedCostItemCount >= self.costItemInfo.count)
    self.textCostItemNumRed.gameObject:SetActive(self.curOwnedCostItemCount < self.costItemInfo.count)
end

function BattlePassPurchaseLvlMediator:AddRewardItem(newLvlBound)
    if self.rewardLvlUpperBound > newLvlBound then return end
    for i = self.rewardLvlUpperBound + 1, newLvlBound do
        self.appenedDataEachLvl[i] = {}
        local rewardNode = ModuleRefer.BattlePassModule:GetRewardInfosByCfgId(self.cfgId)[i]
        local normalItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardNode.normal)
        local advItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardNode.adv)
        for _, data in ipairs(normalItems) do
            local cellIdx = self.itemId2CellIndex[data.configCell:Id()]
            if not cellIdx then
                self.tableReward:AppendData(data)
                self.dataLength = self.dataLength + 1
                cellIdx = self.dataLength
                self.itemId2CellIndex[data.configCell:Id()] = cellIdx
                self.appendData[cellIdx] = data
            else
                local appendData = self.appendData[cellIdx]
                appendData.count = appendData.count + data.count
                self.tableReward:UpdateData(appendData)
            end
            local copiedData = {}
            Utils.CopyTable(data, copiedData)
            table.insert(self.appenedDataEachLvl[i], copiedData)
        end
        if ModuleRefer.BattlePassModule:IsVIP(self.cfgId) then
            for _, data in ipairs(advItems) do
                local cellIdx = self.itemId2CellIndex[data.configCell:Id()]
                if not cellIdx then
                    self.tableReward:AppendData(data)
                    self.dataLength = self.dataLength + 1
                    cellIdx = self.dataLength
                    self.itemId2CellIndex[data.configCell:Id()] = cellIdx
                    self.appendData[cellIdx] = data
                else
                    local appendData = self.appendData[cellIdx]
                    appendData.count = appendData.count + data.count
                    self.tableReward:UpdateData(appendData)
                end
                local copiedData = {}
                Utils.CopyTable(data, copiedData)
                table.insert(self.appenedDataEachLvl[i], copiedData)
            end
        end
    end
    self.rewardLvlUpperBound = newLvlBound
end

function BattlePassPurchaseLvlMediator:RemoveRewardItem(newLvlBound)
    if self.rewardLvlUpperBound <= newLvlBound then return end
    for i = newLvlBound + 1, self.rewardLvlUpperBound do
        for _, data in ipairs(self.appenedDataEachLvl[i]) do
            local cellIdx = self.itemId2CellIndex[data.configCell:Id()]
            local appendData = self.appendData[cellIdx]
            if appendData.count > data.count then
                appendData.count = appendData.count - data.count
                self.tableReward:UpdateData(appendData)
            else
                self.itemId2CellIndex[data.configCell:Id()] = nil
                self.appendData[cellIdx] = nil
                self.tableReward:RemData(appendData)
                self.dataLength = self.dataLength - 1
            end
        end
    end
    self.rewardLvlUpperBound = newLvlBound
end

function BattlePassPurchaseLvlMediator:OnBtnPurchaseClicked()
    if self.curOwnedCostItemCount < self.costItemInfo.count then
        local lackNum = self.costItemInfo.count - self.curOwnedCostItemCount
        PayConfirmHelper.ShowSimpleConfirmationPopupForInsufficientItem(self.costItemInfo.id, lackNum, function()
            g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, {tabId = 9})
        end)
        return
    end
    local op = wrpc.PlayerAutoRewardOperation()
    op.ConfigId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    op.OperationType = wrpc.AutoRewardOperationType.AutoRewardOperationBPBuyLevel
    op.Arg1 = self.curNum
    local msg = PlayerAutoRewardOpParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(self.btnPurchase.gameObject.transform, nil, nil, function(_, isSuccess, rsp)
        self:CloseSelf()
    end)
end

return BattlePassPurchaseLvlMediator