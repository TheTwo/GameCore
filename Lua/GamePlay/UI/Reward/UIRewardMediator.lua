local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local UIMediatorNames = require("UIMediatorNames")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local EventConst = require("EventConst")
---@type RewardModule

local COUNT_MULTILINE_THRESHOLD = 7

---@class UIRewardMediator : BaseUIMediator
local UIRewardMediator = class('UIRewardMediator', BaseUIMediator)

---@class UIRewardMediatorItemData
---@field id number
---@field count number

---@class UIRewardMediatorParameter
---@field itemInfo UIRewardMediatorItemData[]
---@field itemProfiteType wds.enum.ItemProfitType
---@field closeCallback fun()

function UIRewardMediator:ctor()

end

function UIRewardMediator:OnCreate()
    self:InitObjects()
end

function UIRewardMediator:InitObjects()
    self.tableList = self:TableViewPro('p_table_list')
    self.tableListCenter = self:TableViewPro('p_table_list_center')
    self.titleText = self:Text('p_text_title', "equip_getreward")
    self.detailText = self:Text('p_text_detail')
    self.hintText = self:Text('p_text_hint', "equip_clickempty")
    self.btnBaseButton = self:Button('p_base_button', Delegate.GetOrCreate(self, self.OnBtnBaseButtonClicked))

end

---@param self UIRewardMediator
---@param param UIRewardMediatorParameter
function UIRewardMediator:OnShow(param)
    self.closeCallback = param.closeCallback
    self:RefreshUI(param)
end

function UIRewardMediator:OnHide(param)
end

function UIRewardMediator:OnOpened(param)
end

function UIRewardMediator:OnClose(param)
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
    if self.closeCallback then
        self.closeCallback()
    end
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
end

--- 刷新UI
---@param self UIRewardMediator
---@param data UIRewardMediatorParameter
function UIRewardMediator:RefreshUI(data)
    local itemInfo = (data or {}).itemInfo
    if (not data or #itemInfo == 0) then
        g_Logger:Error("No reward to show!")
        self:CloseSelf()
        return
    end

    local table
    if (#itemInfo > COUNT_MULTILINE_THRESHOLD) then
        table = self.tableList
        self.tableList.gameObject:SetActive(true)
        self.tableListCenter.gameObject:SetActive(false)
    else
        table = self.tableListCenter
        self.tableList.gameObject:SetActive(false)
        self.tableListCenter.gameObject:SetActive(true)
    end

    table:Clear()
    if data.itemProfiteType == wds.enum.ItemProfitType.ItemAddByEquipBuild then
        self.forbidClose = true
        if self.delayTimer then
            TimerUtility.StopAndRecycle(self.delayTimer)
            self.delayTimer = nil
        end
        self.delayTimer = TimerUtility.DelayExecute(function()
            self.forbidClose = false
        end, 2)
        for _, item in ipairs(itemInfo) do
            local singleItem = ModuleRefer.InventoryModule:GetItemInfoByUid(item.id)
            if singleItem then
                local itemCfg = ConfigRefer.Item:Find(singleItem.ConfigId)
                if (itemCfg) then
                    local itemData = {
                        configCell = itemCfg,
                        count = item.count,
                        customData = item.id,
                        onClick = Delegate.GetOrCreate(self, self.OnEquipItemClick),
                    }
                    table:AppendData(itemData)
                end
            end
        end
    else
        for _, item in ipairs(itemInfo) do
            local itemCfg = ConfigRefer.Item:Find(item.id)
            if (itemCfg) then
                local itemData = {
                    configCell = itemCfg,
                    count = item.count,
                    showTips = true,
                }
                table:AppendData(itemData)
            end
        end
    end
    table:RefreshAllShownItem()
end

function UIRewardMediator:OnEquipItemClick(_, customData, itemBase)
    local param = {}
    param.clickTransform = itemBase.transform
    param.itemUid = customData
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end


function UIRewardMediator:OnBtnBaseButtonClicked(args)
    if self.forbidClose then
        return
    end
    self:CloseSelf()
end

return UIRewardMediator
