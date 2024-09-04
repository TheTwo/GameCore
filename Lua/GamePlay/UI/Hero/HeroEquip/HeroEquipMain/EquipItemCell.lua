local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local EquipItemCell = class('EquipItemCell',BaseTableViewProCell)

function EquipItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.compChildCardHeroS = self:LuaBaseComponent('child_card_hero_s')
end

function EquipItemCell:Select()
    self.delayTimer = TimerUtility.DelayExecuteInFrame(function()
        if Utils.IsNullOrEmpty(self.compChildItemStandardS) then
            return
        end
        self.compChildItemStandardS.Lua:ChangeSelectStatus(true)
    end, 3)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_EQUIP, self.data)
end

function EquipItemCell:OnClose()
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
end

function EquipItemCell:UnSelect()
    self.compChildItemStandardS.Lua:ChangeSelectStatus(false)
end

function EquipItemCell:OnIconClick()
    local equipMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipUIMediator)
    equipMediator.tableviewproTableItem:SetToggleSelect(self.uid)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_EQUIP, self.data)
end

function EquipItemCell:OnFeedData(uid)
    self.uid = uid
    self.data = ModuleRefer.InventoryModule:GetItemInfoByUid(uid)
    self.compChildItemStandardS.Lua:ChangeSelectStatus(false)
    if self.data.EquipInfo.HeroConfigId and self.data.EquipInfo.HeroConfigId > 0 then
        self.compChildCardHeroS.gameObject:SetActive(true)
        self.compChildCardHeroS:FeedData(self.data.EquipInfo.HeroConfigId)
    else
        self.compChildCardHeroS.gameObject:SetActive(false)
    end
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(self.data.ConfigId)
    itemData.showCount = false
    itemData.showRightCount = self.data.EquipInfo.StrengthenLevel > 0
    itemData.count = self.data.EquipInfo.StrengthenLevel
    itemData.gearProtect = self.data.EquipInfo.IsLock
    itemData.onClick = function()
        self:OnIconClick()
    end
    self.compChildItemStandardS:FeedData(itemData)
end

return EquipItemCell
