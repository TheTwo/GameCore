--- scene:scene_world_popup_occupation_gain

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ItemGroupType = require("ItemGroupType")
local UIHelper = require("UIHelper")
local AttrValueType = require("AttrValueType")
local Utils = require("Utils")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceVillageOccupationGainMediatorParameter
---@field village wds.Village
---@field fixedMapCfgId number @FixedMapBuildingConfigCell:Id()
---@field randomAllianceAttrGroup number[] | RepeatedField

---@class AllianceVillageOccupationGainMediator:BaseUIMediator
---@field new fun():AllianceVillageOccupationGainMediator
---@field super BaseUIMediator
local AllianceVillageOccupationGainMediator = class('AllianceVillageOccupationGainMediator', BaseUIMediator)

function AllianceVillageOccupationGainMediator:ctor()
    BaseUIMediator.ctor(self)
    self._tab = 0
    ---@type {prefabIdx:number, cellData:string}[]|nil
    self._gainTableCells = nil
    self._rewardGenerated = false
    ---@type {go:CS.UnityEngine.GameObject,comp:CS.DragonReborn.UI.BaseComponent}[]
    self._rewardCells = {}
    self._isMyAllianceCenter = false
    ---@type FixedMapBuildingConfigCell
    self._villageConfig = nil
    ---@type AllianceCenterConfigCell
    self._allianceCenterConfig = nil
end

function AllianceVillageOccupationGainMediator:OnCreate(param)
    self._p_text_title = self:Text("p_text_title", "village_info_Occupy_gains")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    
    self._p_btn_gain = self:Button("p_btn_gain", Delegate.GetOrCreate(self, self.OnClickTabGain))
    self._p_btn_gain_status = self:StatusRecordParent("p_btn_gain")
    self._p_text_gain_n = self:Text("p_text_gain_n", "village_btn_Occupy_gains")
    self._p_text_gain_selected = self:Text("p_text_gain_selected", "village_btn_Occupy_gains")
    
    self._p_btn_reward = self:Button("p_btn_reward", Delegate.GetOrCreate(self, self.OnClickTabReward))
    self._p_btn_reward_statue = self:StatusRecordParent("p_btn_reward")
    self._p_text_reward_n = self:Text("p_text_reward_n", "village_btn_First_occupy_reward")
    self._p_text_reward_selected = self:Text("p_text_reward_selected", "village_btn_First_occupy_reward")
    
    self._p_group_tab = self:GameObject("p_group_tab")
    self._p_group_gain = self:GameObject("p_group_gain")
    self._p_group_reward = self:GameObject("p_group_reward")
    self._p_block = self:GameObject("p_block")
    
    self._p_table_gain = self:TableViewPro("p_table_gain")
    self._p_item_title_reward = self:GameObject("p_item_title_reward")
    self._p_text_reward = self:Text("p_text_reward", "village_info_First_alliance_reward")
    self._p_group_all_reward = self:Transform("p_group_all_reward")
    self._p_item_reward_template = self:GameObject("p_item_reward")
    self._p_item_reward_template:SetVisible(false)
    
    
    self._p_group_left_list = self:Transform("p_group_left_list")
    self._p_text_reward_list_left = self:Text("p_text_reward_list_left", "village_info_Ranked_reward_1")
    self._p_group_reward_l_template = self:LuaBaseComponent("p_group_reward_l")
    self._p_group_reward_l_template:SetVisible(false)

    self._p_group_right_list = self:Transform("p_group_right_list")
    self._p_text_reward_list_right = self:Text("p_text_reward_list_right", "village_info_Ranked_reward_2")
    self._p_group_reward_r_template = self:LuaBaseComponent("p_group_reward_r")
    self._p_group_reward_r_template:SetVisible(false)

    self._p_item_title_rebuild_reward = self:GameObject("p_item_title_rebuild_reward")
    self._p_text_rebuild_reward = self:Text("p_text_rebuild_reward", "village_outpost_info_rebuild_reward")
    self._p_text_rebuild_reward_content = self:Text("p_text_rebuild_reward_content")


end

---@param param AllianceVillageOccupationGainMediatorParameter
function AllianceVillageOccupationGainMediator:OnOpened(param)
    self._village = param and param.village
    self._isMyAllianceCenter = false
    self._villageConfig = nil
    self._allianceCenterConfig = nil
    if param.fixedMapCfgId then
        self._villageConfig = ConfigRefer.FixedMapBuilding:Find(param.fixedMapCfgId)
    else
        if self._village and self._village.MapBasics and self._village.MapBasics.ConfID then
            self._villageConfig = ConfigRefer.FixedMapBuilding:Find(self._village.MapBasics.ConfID)
            self._isMyAllianceCenter = self._village.ID == ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
            if self._isMyAllianceCenter then
                self._allianceCenterConfig = ConfigRefer.AllianceCenter:Find(self._villageConfig:BuildAllianceCenter())
            end
        end
    end
    if self._isMyAllianceCenter then
        self._p_text_title.text = I18N.Get("alliance_center_info_gains_title")
    else
        self._p_text_title.text = I18N.Get("village_info_Occupy_gains")
    end
    self._p_group_tab:SetVisible(not self._isMyAllianceCenter)
    self._p_block:SetVisible(not self._isMyAllianceCenter)
    if param.randomAllianceAttrGroup then
        self.villageRandomAttr = param.randomAllianceAttrGroup
    else  
        self.villageRandomAttr  = self._village and self._village.Village and self._village.Village.RandomAllianceAttrGroup or {}
    end

    local contributionValue = ConfigRefer.AllianceConsts:AllianceRuinRebuildRewardContribution()
    local contributionLimitID = ConfigRefer.AllianceConsts:AllianceRuinRebuildRewardLimit()
    local contributionLimitCount = ConfigRefer.CommonUseLimit:Find(contributionLimitID):LimitCount()
    local rebuildRewardDesc = I18N.GetWithParams("village_outpost_info_rebuild_reward_content", contributionValue, contributionLimitCount)
    self._p_text_rebuild_reward_content.text = rebuildRewardDesc
    
    self:ChangeTab(1, true)
end

function AllianceVillageOccupationGainMediator:OnClose(data)
    for i, v in pairs(self._rewardCells) do
        if Utils.IsNotNull(v.comp) then
            v.comp:Close()
        end
        UIHelper.DeleteUIGameObject(v.go)
    end
    table.clear(self._rewardCells)
end

function AllianceVillageOccupationGainMediator:OnClickTabGain()
    self:ChangeTab(1)
end

function AllianceVillageOccupationGainMediator:OnClickTabReward()
    self:ChangeTab(2)
end

function AllianceVillageOccupationGainMediator:ChangeTab(tab, force)
    if self._tab == tab and not force then
        return
    end

    self._p_btn_gain_status:SetState(tab == 1 and 1 or 0)
    self._p_btn_reward_statue:SetState(tab == 2 and 1 or 0)
    self._p_group_gain:SetVisible(tab == 1)
    self._p_group_reward:SetVisible(tab == 2)
    if tab == 1 then
        self:GenerateTableGain(force)
    elseif tab == 2 then
        self:GenerateTableReward()
    end
end

function AllianceVillageOccupationGainMediator:ParseAttrInfo(attrTypeAndValue, addToTable)
    ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, addToTable, true)
end

function AllianceVillageOccupationGainMediator:GenerateTableGain(force)
    if self._gainTableCells and not force then
        return
    end
    self._gainTableCells = table.clear(self._gainTableCells) or {}
    self._p_table_gain:Clear()
    if not self._village or not self._villageConfig then
        return
    end
    ---@type table<number, AttrTypeAndValue>
    local appendAttr = {}
    if self._allianceCenterConfig then
        local appendAttrGroup = ConfigRefer.AttrGroup:Find(self._allianceCenterConfig:AllianceAttrGroup())
        if appendAttrGroup and appendAttrGroup:AttrListLength() > 0 then
            for i = 1, appendAttrGroup:AttrListLength() do
                local pair = appendAttrGroup:AttrList(i)
                appendAttr[pair:TypeId()] = pair
            end
        end
    end
    local allianceAttr = ConfigRefer.AttrGroup:Find(self._villageConfig:AllianceAttrGroup())
    if allianceAttr and allianceAttr:AttrListLength() > 0 then
        local allianceGainAttr = {}
        for i = 1,  allianceAttr:AttrListLength() do
            local attrTypeAndValue = allianceAttr:AttrList(i)
            local typeId = attrTypeAndValue:TypeId()
            local appendValue = appendAttr[typeId]
            if appendValue then
                appendAttr[typeId] = nil
                local baseValue = attrTypeAndValue:Value()
                attrTypeAndValue = {
                    TypeId = function(_) return typeId  end,
                    Value = function(_) return baseValue + appendValue:Value()  end
                }
            end
            self:ParseAttrInfo(attrTypeAndValue, allianceGainAttr)
        end
        for i = 1, #allianceGainAttr do
            allianceGainAttr[i].prefabIdx = 3
        end
        table.addrange(self._gainTableCells, allianceGainAttr)
    end
    if self._villageConfig:VillageShowExtraPetItemLength() > 0 then
        ---@type AllianceVillageOccupationGainPetCellParameter
        local cellData = {}
        cellData.content = I18N.Get("village_newpet_after_occupied")
        cellData.petConfigIds = {}
        for i = 1, self._villageConfig:VillageShowExtraPetItemLength() do
            table.insert(cellData.petConfigIds, self._villageConfig:VillageShowExtraPetItem(i))
        end
        local villageGain = {prefabIdx=4, cellData=cellData}
        table.insert(self._gainTableCells, villageGain)
    end
    local personal = {}
    ---@type number[]
    local villageRandomAttr = self.villageRandomAttr
    for _, attrGroupId in ipairs(villageRandomAttr) do
        local attrGroupConfig = ConfigRefer.AttrGroup:Find(attrGroupId)
        if attrGroupConfig then
            for i = 1, attrGroupConfig:AttrListLength() do
                local attrTypeAndValue = attrGroupConfig:AttrList(i)
                local typeId = attrTypeAndValue:TypeId()
                local appendValue = appendAttr[typeId]
                if appendValue then
                    appendAttr[typeId] = nil
                    local baseValue = attrTypeAndValue:Value()
                    attrTypeAndValue = {
                        TypeId = function(_) return typeId  end,
                        Value = function(_) return baseValue + appendValue:Value()  end
                    }
                end
                self:ParseAttrInfo(attrTypeAndValue, personal)
            end
        end
    end
    for _, v in pairs(appendAttr) do
        self:ParseAttrInfo(v, personal)
    end
    if #personal > 0 then
        local titleCell = {prefabIdx=0, cellData=I18N.Get("village_info_Personal_resource")}
        table.insert(self._gainTableCells, titleCell)
        table.addrange(self._gainTableCells, personal)
    end
    local hasInCome = false
    local currency = ConfigRefer.AllianceCurrency:Find(self._villageConfig:OccupyAllianceCurrencyType())
    if currency or self._villageConfig:FactionValue() > 0 then
        hasInCome = true
    end
    if hasInCome then
        local titleCell = {prefabIdx=0, cellData=I18N.Get("village_info_Alliance_income")}
        table.insert(self._gainTableCells, titleCell)
    end
    local currencyNum = self._villageConfig:OccupyAllianceCurrencyNum()
    if currency and currencyNum > 0 then
        local villageGain = {prefabIdx=2, cellData={strLeft=I18N.Get(currency:Name()), strRight = ("+%s"):format(currencyNum), icon = currency:Icon()}}
        table.insert(self._gainTableCells, villageGain)
    end
    if self._villageConfig:FactionValue() > 0 then
        local villageGain = {prefabIdx=2, cellData={strLeft=I18N.Get("village_info_Alliance_forces"), strRight = ("+%s"):format(self._villageConfig:FactionValue()), icon = "sp_comp_icon_achievement_1"}}
        table.insert(self._gainTableCells, villageGain)
    end
    if self._villageConfig:AdditionalDesLength() > 0 then
        local titleCell = {prefabIdx=0, cellData=I18N.Get("village_info_Territory_protection")}
        table.insert(self._gainTableCells, titleCell)
        for i = 1, self._villageConfig:AdditionalDesLength() do
            table.insert(self._gainTableCells, {prefabIdx=1, cellData=I18N.Get(self._villageConfig:AdditionalDes(i))})
        end
    end
    for i, v in ipairs(self._gainTableCells) do
        self._p_table_gain:AppendData(v.cellData, v.prefabIdx)
    end
end

function AllianceVillageOccupationGainMediator:GetVillageRingIndex()
    return 1
end

function AllianceVillageOccupationGainMediator:GenerateTableReward()
    if self._rewardGenerated then
        return
    end
    self._rewardGenerated = true
    if not self._villageConfig then
        return
    end

    self:SetUpAllianceRewardReadFromMail()
    if ModuleRefer.VillageModule:IsVillageRuined(self._village) 
        or ModuleRefer.VillageModule:IsVillageRuinRebuilding(self._village) then
        self:HideDamageRankReward()
        self:HideDestroyRankReward()
        self:ShowRebuildRewardTip()
    else
        self:ShowDamageRankReward()
        self:ShowDestroyRankReward()
        self:HideRebuildRewardTip()
    end
  
end

function AllianceVillageOccupationGainMediator:SetUpAllianceRewardReadFromMail()
    self._p_item_title_reward:SetVisible(false)
    self._p_group_all_reward:SetVisible(false)
    local mail = ConfigRefer.Mail:Find(self._villageConfig:FirstOccupyRewardMail())
    if not mail or mail:Attachment() == 0 then
        return
    end
    local itemGroup = ConfigRefer.ItemGroup:Find(mail:Attachment())
    if not itemGroup or itemGroup:Type() ~= ItemGroupType.OneByOne or itemGroup:ItemGroupInfoListLength() <= 0 then
        return
    end
    self._p_item_title_reward:SetVisible(true)
    self._p_group_all_reward:SetVisible(true)
    self._p_item_reward_template:SetVisible(true)
    local ItemConfig = ConfigRefer.Item
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local itemInfo = itemGroup:ItemGroupInfoList(i)
        local addItem = UIHelper.DuplicateUIGameObject(self._p_item_reward_template, self._p_group_all_reward)
        ---@type CS.DragonReborn.UI.LuaBaseComponent
        local csComp = addItem:GetComponentInChildren(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        csComp:ManualTransformParentChanged()
        ---@type BaseItemIcon
        local itemComponent = csComp.Lua
        ---@type ItemIconData
        local itemData = {}
        itemData.configCell = ItemConfig:Find(itemInfo:Items())
        itemData.count = itemInfo:Nums()
        itemData.countUseBigNumber = true
        itemComponent:FeedData(itemData)
        table.insert(self._rewardCells, {go=addItem,comp=csComp})
    end
    self._p_item_reward_template:SetVisible(false)
end

function AllianceVillageOccupationGainMediator:ShowDamageRankReward()
    self._p_group_left_list:SetVisible(true)
    self:SetUpRankReward(self._p_group_left_list, self._villageConfig:FirstOccupyDamageRankReward(), self._p_group_reward_l_template)
end

function AllianceVillageOccupationGainMediator:HideDamageRankReward()
    self._p_group_left_list:SetVisible(false)
end

function AllianceVillageOccupationGainMediator:ShowDestroyRankReward()
    self._p_group_right_list:SetVisible(true)
    self:SetUpRankReward(self._p_group_right_list, self._villageConfig:FirstOccupyDestroyRankReward(), self._p_group_reward_r_template)
end

function AllianceVillageOccupationGainMediator:HideDestroyRankReward()
    self._p_group_right_list:SetVisible(false)
end

---@param baseTrans CS.UnityEngine.Transform
---@param rewardConfigId number
---@param template CS.DragonReborn.UI.LuaBaseComponent
function AllianceVillageOccupationGainMediator:SetUpRankReward(baseTrans, rewardConfigId, template)
    baseTrans:SetVisible(false)
    local rankReward = ConfigRefer.RankReward:Find(rewardConfigId)
    if not rankReward or rankReward:TopRewardLength() <= 0 then
        return
    end
    baseTrans:SetVisible(true)
    template:SetVisible(true)
    local ItemGroupConfig = ConfigRefer.ItemGroup
    local lastTop = 1
    for i = 1, rankReward:TopRewardLength() do
        local reward = rankReward:TopReward(i)
        local top= reward:Top()
        local itemGroup =  ItemGroupConfig:Find(reward:Reward())
        local rankItem = UIHelper.DuplicateUIComponent(template, baseTrans)
        rankItem:FeedData({rangeStart = lastTop, to = top, reward = itemGroup})
        lastTop = top + 1
    end
    template:SetVisible(false)
end

function AllianceVillageOccupationGainMediator:ShowRebuildRewardTip()
    self._p_item_title_rebuild_reward:SetVisible(true)
end

function AllianceVillageOccupationGainMediator:HideRebuildRewardTip()
    self._p_item_title_rebuild_reward:SetVisible(false)
end

return AllianceVillageOccupationGainMediator