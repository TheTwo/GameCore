--- scene:scene_world_popup_behemoth_award

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local UIHelper = require("UIHelper")
local ItemGroupType = require("ItemGroupType")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothCageRewardPopupMediator:BaseUIMediator
---@field new fun():AllianceBehemothCageRewardPopupMediator
---@field super BaseUIMediator
local AllianceBehemothCageRewardPopupMediator = class('AllianceBehemothCageRewardPopupMediator', BaseUIMediator)

function AllianceBehemothCageRewardPopupMediator:ctor()
    AllianceBehemothCageRewardPopupMediator.super.ctor(self)
    self._tab = 0
    ---@type {prefabIdx:number, cellData:string}[]|nil
    self._gainTableCells = nil
    self._rewardGenerated = false
    ---@type {go:CS.UnityEngine.GameObject,comp:CS.DragonReborn.UI.BaseComponent}[]
    self._rewardCells = {}
end

function AllianceBehemothCageRewardPopupMediator:OnCreate(param)
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

    self._p_group_gain = self:GameObject("p_group_gain")
    self._p_group_reward = self:GameObject("p_group_reward")

    self._p_table_gain = self:TableViewPro("p_table_gain")
    self._p_table_award = self:TableViewPro("p_table_award")
end

---@param param AllianceVillageOccupationGainMediatorParameter
function AllianceBehemothCageRewardPopupMediator:OnOpened(param)
    self._village = param and param.village
    self._villageConfig = nil
    if param.fixedMapCfgId then
        self._villageConfig = ConfigRefer.FixedMapBuilding:Find(param.fixedMapCfgId)
    else
        if self._village and self._village.MapBasics and self._village.MapBasics.ConfID then
            self._villageConfig = ConfigRefer.FixedMapBuilding:Find(self._village.MapBasics.ConfID)
        end
    end
    if param.randomAllianceAttrGroup then
        self.villageRandomAttr = param.randomAllianceAttrGroup
    else
        self.villageRandomAttr  = self._village and self._village.Village and self._village.Village.RandomAllianceAttrGroup or {}
    end
    self:ChangeTab(1, true)
end

function AllianceBehemothCageRewardPopupMediator:OnClickTabGain()
    self:ChangeTab(1)
end

function AllianceBehemothCageRewardPopupMediator:OnClickTabReward()
    self:ChangeTab(2)
end

function AllianceBehemothCageRewardPopupMediator:ChangeTab(tab, force)
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
        self:GenerateTableReward(force)
    end
end

function AllianceBehemothCageRewardPopupMediator:ParseAttrInfo(attrTypeAndValue, addToTable)
    ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, addToTable, true)
end

function AllianceBehemothCageRewardPopupMediator:GenerateTableGain(force)
    if self._gainTableCells and not force then
        return
    end
    self._gainTableCells = table.clear(self._gainTableCells) or {}
    self._p_table_gain:Clear()
    if not self._village or not self._villageConfig then
        return
    end
    local allianceAttr = ConfigRefer.AttrGroup:Find(self._villageConfig:AllianceAttrGroup())
    if allianceAttr and allianceAttr:AttrListLength() > 0 then
        local allianceGainAttr = {}
        for i = 1,  allianceAttr:AttrListLength() do
            local attrTypeAndValue = allianceAttr:AttrList(i)
            self:ParseAttrInfo(attrTypeAndValue, allianceGainAttr)
        end
        for i = 1, #allianceGainAttr do
            allianceGainAttr[i].prefabIdx = 1
        end
        table.addrange(self._gainTableCells, allianceGainAttr)
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
    if currency then
        local villageGain = {prefabIdx=1, cellData={strLeft=I18N.Get(currency:Name()), strRight = ("+%s"):format(self._villageConfig:OccupyAllianceCurrencyNum()), icon = currency:Icon()}}
        table.insert(self._gainTableCells, villageGain)
    end
    if self._villageConfig:FactionValue() > 0 then
        local villageGain = {prefabIdx=1, cellData={strLeft=I18N.Get("village_info_Alliance_forces"), strRight = ("+%s"):format(self._villageConfig:FactionValue()), icon = "sp_comp_icon_achievement_1"}}
        table.insert(self._gainTableCells, villageGain)
    end
    for i, v in ipairs(self._gainTableCells) do
        self._p_table_gain:AppendData(v.cellData, v.prefabIdx)
    end
end

function AllianceBehemothCageRewardPopupMediator:GenerateTableReward(force)
    if self._rewardGenerated and not force then
        return
    end
    if force then
        self._p_table_award:Clear()
    end
    self._rewardGenerated = true
    if not self._villageConfig then
        return
    end
    self:SetUpAllianceRewardReadFromMail()
    self:SetupDamageRankReward()
end

function AllianceBehemothCageRewardPopupMediator:SetUpAllianceRewardReadFromMail()
    local mail = ConfigRefer.Mail:Find(self._villageConfig:FirstOccupyRewardMail())
    if not mail or mail:Attachment() == 0 then
        return
    end
    local itemGroup = ConfigRefer.ItemGroup:Find(mail:Attachment())
    if not itemGroup or itemGroup:Type() ~= ItemGroupType.OneByOne or itemGroup:ItemGroupInfoListLength() <= 0 then
        return
    end
    self._p_table_award:AppendData(I18N.Get("village_info_First_alliance_reward"))
    local ItemConfig = ConfigRefer.Item
    ---@type ItemIconData[]
    local itemCells = {}
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local itemInfo = itemGroup:ItemGroupInfoList(i)
        ---@type ItemIconData
        local itemData = {}
        itemData.configCell = ItemConfig:Find(itemInfo:Items())
        itemData.count = itemInfo:Nums()
        itemData.countUseBigNumber = true
        table.insert(itemCells, itemData)
    end
    self._p_table_award:AppendData(itemCells, 1)
end

function AllianceBehemothCageRewardPopupMediator:SetupDamageRankReward()
    self:SetUpRankReward(I18N.Get("alliance_behemoth_title_OccupyReward"), self._villageConfig:FirstOccupyDamageRankReward())
end

function AllianceBehemothCageRewardPopupMediator:SetupDestroyRankReward()
    self:SetUpRankReward(I18N.Get("village_info_Ranked_reward_2"), self._villageConfig:FirstOccupyDestroyRankReward())
end

---@param title string
---@param rewardConfigId number
function AllianceBehemothCageRewardPopupMediator:SetUpRankReward(title, rewardConfigId)
    local rankReward = ConfigRefer.RankReward:Find(rewardConfigId)
    if not rankReward or rankReward:TopRewardLength() <= 0 then
        return
    end
    self._p_table_award:AppendData(title, 0)
    local ItemGroupConfig = ConfigRefer.ItemGroup
    local lastTop = 1
    for i = 1, rankReward:TopRewardLength() do
        local reward = rankReward:TopReward(i)
        local top= reward:Top()
        local itemGroup =  ItemGroupConfig:Find(reward:Reward())
        ---@type AllianceBehemothCageFirstOccupationRankRewardCellData
        local cellData = {}
        cellData.lv = lastTop
        cellData.lvEnd = top
        cellData.cells = {}
        for j = 1, itemGroup:ItemGroupInfoListLength() do
            local info = itemGroup:ItemGroupInfoList(j)
            ---@type ItemIconData
            local item = {}
            item.configCell = ConfigRefer.Item:Find(info:Items())
            item.count = info:Nums()
            table.insert(cellData.cells, item)
        end
        self._p_table_award:AppendData(cellData, 2)
        lastTop = top + 1
    end
end

return AllianceBehemothCageRewardPopupMediator