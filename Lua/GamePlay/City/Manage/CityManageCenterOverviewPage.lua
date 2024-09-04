local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityManageCenterI18N = require("CityManageCenterI18N")
local NumberFormatter = require("NumberFormatter")

local I18N = require("I18N")
local CityAttrType = require("CityAttrType")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityManageCenterOverviewPage:BaseUIComponent
local CityManageCenterOverviewPage = class('CityManageCenterOverviewPage', BaseUIComponent)

function CityManageCenterOverviewPage:OnCreate()
    --- 宠物状态emoji总览
    self._banner = self:GameObject("banner")
    self._p_status_fine = self:GameObject("p_status_fine")
    self._p_status_bad = self:GameObject("p_status_bad")
    self._p_status_normal = self:GameObject("p_status_normal")
    self._p_text_status = self:Text("p_text_status")

    self._p_need_food = self:GameObject("p_need_food")
    self._p_text_need = self:Text("p_text_need", "animal_work_interface_desc06")
    self._p_text_number = self:Text("p_text_number")

    self._p_btn_goto_banner = self:Button("p_btn_goto_banner", Delegate.GetOrCreate(self, self.OnClickGotoMakingFood))
    self._p_text_goto = self:Text("p_text_goto", "animal_work_interface_desc41")

    --- 仓库满了的情况
    self._p_hint_storehouse = self:GameObject("p_hint_storehouse")
    self._p_text_hint_storehouse = self:Text("p_text_hint_storehouse", CityManageCenterI18N.UIHint_StoreroomFull)
    self._p_btn_goto_storehouse = self:Button("p_btn_goto_storehouse", Delegate.GetOrCreate(self, self.OnClickUpgradeStoreroom))

    --- 宠物饥饿状态
    self._p_hint_pet_status = self:GameObject("p_hint_pet_status")
    self._p_text_hint_pet = self:Text("p_text_hint_pet")
    self._p_btn_goto_pet = self:Button("p_btn_goto_pet", Delegate.GetOrCreate(self, self.OnClickGotoMakingFood))
    self._layout_pet_starved = self:GameObject("layout_pet_starved")

    self._p_item_pet_starved_1 = self:GameObject("p_item_pet_starved_1")
    ---@type CommonPetIconSmall
    self._child_card_pet_circle_1 = self:LuaObject("child_card_pet_circle_1")
    self._p_set_bar_1 = self:Slider("p_set_bar_1")
    self._p_text_hp_starved_1 = self:Text("p_text_hp_starved_1")

    self._p_item_pet_starved_2 = self:GameObject("p_item_pet_starved_2")
    ---@type CommonPetIconSmall
    self._child_card_pet_circle_2 = self:LuaObject("child_card_pet_circle_2")
    self._p_set_bar_2 = self:Slider("p_set_bar_2")
    self._p_text_hp_starved_2 = self:Text("p_text_hp_starved_2")

    self._p_dot = self:GameObject("p_dot")

    --- 队列总览
    self._p_queue = self:GameObject("p_queue")
    self._p_text_queue_build = self:Text("p_text_queue_build")
    self._p_text_queue_egg = self:Text("p_text_queue_egg")
    self._p_table_build = self:TableViewPro("p_table_build")
    self._p_table_egg = self:TableViewPro("p_table_egg")

    --- 没有宠物无法生效的家具
    self._p_hint_need_pet = self:Transform("p_hint_need_pet")
    self._p_text_need_pet = self:Text("p_text_need_pet")
    self._p_layout_furniture = self:Transform("p_layout_furniture")
    ---@type CityManageCannotWorkWithoutPetFurniture
    self._p_item_furniture = self:LuaBaseComponent("p_item_furniture")
    self._pool_cannot_work = LuaReusedComponentPool.new(self._p_item_furniture, self._p_layout_furniture)

    --- 效率提升（暂时不做）
    self._p_hint_efficiency = self:GameObject("p_hint_efficiency")
    self._p_text_title_efficiency = self:Text("name", CityManageCenterI18N.UIHint_EfficiencyUp)
    self._p_layout_efficiency = self:Transform("p_layout_efficiency")
    ---@type CityManageEfficiencyUp
    self._p_item_efficiency = self:LuaBaseComponent("p_item_efficiency")
    self._pool_efficiency = LuaReusedComponentPool.new(self._p_item_efficiency, self._p_layout_efficiency)

    --- 可处理（暂时不做）
    self._p_hint_processable = self:GameObject("p_hint_processable")
    self._p_text_title_processable = self:Text("p_text_title_processable", CityManageCenterI18N.UIHint_DealWith)
    self._p_layout_processable = self:Transform("p_layout_processable")
    ---@type CityManageDealWith
    self._p_item_processable = self:LuaBaseComponent("p_item_processable")

    --- 运转正常
    self._p_hint_empty = self:GameObject("p_hint_empty")
    self._p_text_empty = self:Text("p_text_empty", CityManageCenterI18N.UIHint_EverythingOK)
end

---@param data CityManageCenterUIParameter
function CityManageCenterOverviewPage:OnFeedData(data)
    self.data = data
    self:UpdateEmoji()
    self:UpdateStoreroom()
    self:UpdateHungryPet()
    self:UpdateQueue()
    self:UpdateNonPetFurniture()
    self:UpdateEfficiencyUp()
    self:UpdateDealWith()
    self:UpdateEverythingOK()
end

function CityManageCenterOverviewPage:UpdateEmoji()
    local status, statusContent = self.data:GetAllPetsEmojiStatus()
    self._p_status_fine:SetActive(status == 0)
    self._p_status_normal:SetActive(status == 1)
    self._p_status_bad:SetActive(status == 2)
    self._p_btn_goto_banner:SetVisible(status ~= 0)
    self._p_text_status.text = statusContent
    self._p_need_food:SetActive(status ~= 0)
    self._p_text_number.text = self.data:GetFoodHintText()
end

function CityManageCenterOverviewPage:UpdateStoreroom()
    self.isFull = self.data:IsStoreroomFull()
    self._p_hint_storehouse:SetActive(self.isFull)
end

function CityManageCenterOverviewPage:UpdateHungryPet()
    self._p_hint_pet_status:SetActive(self.data:IsAnyPetHungry())
    local count = self.data:GetHungryPetCount()
    self._p_text_hint_pet.text = I18N.GetWithParams(CityManageCenterI18N.UIHint_PetHungry, count)
    self._p_item_pet_starved_1:SetActive(count >= 1)
    if count >= 1 then
        local petDatum = self.data:GetHungryPet(1)
        local pet = ModuleRefer.PetModule:GetPetByID(petDatum.id)
        local compData = {
            id = petDatum.id,
            cfgId = pet.ConfigId,
            selected = false,
            level = pet.Level,
            rank = pet.RankLevel
        }
        self._child_card_pet_circle_1:FeedData(compData)
        local curHp = petDatum.hp
        local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()]
        self._p_set_bar_1.value = curHp / maxHp
        self._p_text_hp_starved_1.text = NumberFormatter.Percent(curHp / maxHp)
    end

    self._p_item_pet_starved_2:SetActive(count >= 2)
    if count >= 2 then
        local petDatum = self.data:GetHungryPet(2)
        local pet = ModuleRefer.PetModule:GetPetByID(petDatum.id)
        local compData = {
            id = petDatum.id,
            cfgId = pet.ConfigId,
            selected = false,
            level = pet.Level,
            rank = pet.RankLevel
        }
        self._child_card_pet_circle_2:FeedData(compData)
        local curHp = petDatum.hp
        local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()]
        self._p_set_bar_2.value = curHp / maxHp
        self._p_text_hp_starved_2.text = NumberFormatter.Percent(curHp / maxHp)
    end
    
    self._p_dot:SetActive(count >= 3)
    self.hungryPetCount = count
end

function CityManageCenterOverviewPage:UpdateQueue()
    local buildQueue = self.data:GetBuildQueue()
    local buildQueueMax = self.data:GetBuildQueueMax()
    local eggQueue = self.data:GetEggQueue()
    local eggQueueMax = self.data:GetEggQueueMax()
    self._p_text_queue_build.text = I18N.GetWithParams(CityManageCenterI18N.UITitle_QueueUpgrade, buildQueue, buildQueueMax)
    self._p_text_queue_egg.text = I18N.GetWithParams(CityManageCenterI18N.UITitle_QueueHatchEgg, eggQueue, eggQueueMax)

    self:UpdateBuildQueueTable()
    self:UpdateHatchEggQueueTable()
end

function CityManageCenterOverviewPage:UpdateBuildQueueTable()
    self._p_table_build:Clear()

    for i, v in ipairs(self.data:GetBuildQueueList()) do
        self._p_table_build:AppendData(v)
    end
end

function CityManageCenterOverviewPage:UpdateHatchEggQueueTable()
    self._p_table_egg:Clear()

    for i, v in ipairs(self.data:GetHatchEggQueueList()) do
        self._p_table_egg:AppendData(v)
    end
end

function CityManageCenterOverviewPage:OnClickUpgradeStoreroom()
    self.data:GotoUpgradeStoreroom()
end

function CityManageCenterOverviewPage:UpdateNonPetFurniture()
    self._p_text_need_pet.text = I18N.GetWithParams(CityManageCenterI18N.UIHint_NeedPet, self.data:GetNonPetFurnitureCount())
    self._pool_cannot_work:HideAll()
    self.nonPetFurCount = 0
    for _, furniture in ipairs(self.data:GetNonPetFurnitureList()) do
        local item = self._pool_cannot_work:GetItem()
        item:FeedData(furniture)
        self.nonPetFurCount = self.nonPetFurCount + 1
    end

    self._p_hint_need_pet:SetVisible(self.nonPetFurCount > 0)
end

function CityManageCenterOverviewPage:UpdateEfficiencyUp()
    self.efficiencyCount = 0
    ---TODO:处理效率增加条目
    self._p_hint_efficiency:SetVisible(false)
end

function CityManageCenterOverviewPage:UpdateDealWith()
    self.dealwithCount = 0
    ---TODO:处理可处理条目
    self._p_hint_processable:SetVisible(false)
end

function CityManageCenterOverviewPage:UpdateEverythingOK()
    self._p_hint_empty:SetActive(self:IsEverythingOK())
end

function CityManageCenterOverviewPage:IsEverythingOK()
    return not self.isFull and self.hungryPetCount == 0 and self.nonPetFurCount == 0 and self.efficiencyCount == 0 and self.dealwithCount == 0
end

function CityManageCenterOverviewPage:OnClickGotoMakingFood()
    self.data:GotoMakingFood()
end

return CityManageCenterOverviewPage