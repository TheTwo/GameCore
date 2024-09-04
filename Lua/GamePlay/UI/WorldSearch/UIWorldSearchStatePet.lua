local UIWorldSearchState = require("UIWorldSearchState")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local SearchCategory = require('SearchCategory')
local Delegate = require('Delegate')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')

---@class UIWorldSearchStatePet : UIWorldSearchState
---@field petMonsterConfigList number[]
---@field petIconDataMap table<number,WorldSearchPetTableData>
---@field petMonsterConfigMap table<number,KmonsterDataConfigCell>
---@field selectedPetID number
local UIWorldSearchStatePet = class("UIWorldSearchStatePet", UIWorldSearchState)

---@param data table<number>
function UIWorldSearchStatePet:Select(mediator, data)
    UIWorldSearchStatePet.super.Select(self, mediator, data)
    self.petMonsterConfigList = data

    self.mediator.p_text_reward.text = I18N.Get("searchentity_info_bound_reward")

    self.mediator.p_reward:SetVisible(true)
    self.mediator.p_search_resources:SetVisible(false)
    self.mediator.p_search_pet:SetVisible(false)
    self.mediator.p_search_egg:SetVisible(false)
    self.mediator.p_text_tips:SetVisible(false)

    self.petIconDataMap = {}
    self.petMonsterConfigMap = {}
    ---@type WorldSearchPetTableData[]
    local petIconDataList = {}
    for _, configID in ipairs(self.petMonsterConfigList) do
        local config = ConfigRefer.KmonsterData:Find(configID)
        if config:Level() == 1 then
            local petConfigID = config:SearchPetId()
            
            local disabled = ModuleRefer.WorldSearchModule:IsPetMonsterLockedByVillage(config) 
                        or ModuleRefer.WorldSearchModule:IsPetMonsterLockedByLandform(config)

            ---@type CommonPetIconBaseData
            local petIconData = {}
            petIconData.cfgId = petConfigID
            petIconData.selected = false
            petIconData.showMask = disabled
            petIconData.onClick = Delegate.GetOrCreate(self, self.OnPetSelected)

            ---@type WorldSearchPetTableData
            local iconData = {}
            iconData.petData = petIconData
            iconData.isNew = false
            self.petIconDataMap[petConfigID] = iconData
            self.petMonsterConfigMap[petConfigID] = config
            table.insert(petIconDataList, iconData)
        end
    end
    table.sort(petIconDataList, function(a, b)
        return a.petData.cfgId < b.petData.cfgId
    end)
    
    self.mediator.p_table_pet:Clear()
    if table.nums(petIconDataList) > 0 then
        for _, iconData in ipairs(petIconDataList) do
            self.mediator.p_table_pet:AppendData(iconData)
        end
        self.mediator.p_table_pet:RefreshAllShownItem()

        local firstData = petIconDataList[1].petData
        firstData.selected = true
        self.selectedPetID = firstData.cfgId
        self:OnPetSelected(firstData)
    end
end

function UIWorldSearchStatePet:Unselect()
    if self.mediator then
        self.mediator.p_btn_search:SetVisible(true)
    end
    UIWorldSearchStatePet.super.Unselect(self)
end

function UIWorldSearchStatePet:SetLevel(level)
    UIWorldSearchStatePet.super.SetLevel(self, level)

    self:RefreshRewards(self.selectedPetID, level)
end

---@param petIconData CommonPetIconBaseData
function UIWorldSearchStatePet:OnPetSelected(petIconData)
    local prevIconData = self.petIconDataMap[self.selectedPetID]
    prevIconData.petData.selected = false
    local iconData = self.petIconDataMap[petIconData.cfgId]
    iconData.petData.selected = true
    self.selectedPetID = petIconData.cfgId
    self.mediator.p_table_pet:RefreshAllShownItem()

    self:RefreshRewards(petIconData.cfgId, self.level)
    self:RefreshSearchState()
end

function UIWorldSearchStatePet:RefreshRewards(petConfigID, level)
    ---@type KmonsterDataConfigCell
    local petMonsterConfig
    for _, configID in ipairs(self.petMonsterConfigList) do
        local config = ConfigRefer.KmonsterData:Find(configID)
        if config:SearchPetId() == petConfigID and config:Level() == level then
            petMonsterConfig = config
            break
        end
    end

    self.mediator.p_table_reward:Clear()

    if petMonsterConfig then
        local items = ModuleRefer.WorldSearchModule:GetMonsterDropItems(petMonsterConfig)
        if items then
            for _, itemGroupInfo in ipairs(items) do
                local itemConfig = ConfigRefer.Item:Find(itemGroupInfo:Items())
                ---@type ItemIconData
                local iconData = {}
                iconData.configCell = itemConfig
                iconData.showCount = true
                iconData.count = itemGroupInfo:Nums()
                self.mediator.p_table_reward:AppendData(iconData)
            end
        end
    end
    self.mediator.p_table_reward:RefreshAllShownItem()
end

function UIWorldSearchStatePet:RefreshSearchState()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        self.mediator.p_text_tips.text = I18N.Get("searchentity_info_after_join_alliance")
        self.mediator.p_text_tips.color = UIHelper.TryParseHtmlString(ColorConsts.warning)
        self.mediator.p_text_tips:SetVisible(true)
        self.mediator.p_btn_search:SetVisible(false )
        return
    end
    
    --if not petMonsterConfig or not ModuleRefer.LandformModule:IsLandformUnlockByCfgId(petMonsterConfig:LandId()) then
    --    self.mediator.p_text_tips.text = I18N.Get("mining_info_collection_after_stage")
    --    self.mediator.p_text_tips.color = UIHelper.TryParseHtmlString(ColorConsts.warning)
    --    self.mediator.p_btn_search:SetVisible(false )
    --    return
    --end

    local petConfig = ConfigRefer.Pet:Find(self.selectedPetID)
    local petMonsterConfig = self.petMonsterConfigMap[self.selectedPetID]

    local lockedByVillage = ModuleRefer.WorldSearchModule:IsPetMonsterLockedByVillage(petMonsterConfig)
    local lockedByLandform = ModuleRefer.WorldSearchModule:IsPetMonsterLockedByLandform(petMonsterConfig)
    if lockedByVillage then
        local villageConfig =  ConfigRefer.FixedMapBuilding:Find(petConfig:VillageBuildingId())
        local villageName = I18N.Get(villageConfig:Name())
        local petName = I18N.Get(petConfig:Name())
        local tip = I18N.GetWithParams("searchentity_info_after_occupying", villageConfig:Level(), villageName, petName)
        self.mediator.p_text_tips.text = tip
        self.mediator.p_text_tips.color = UIHelper.TryParseHtmlString(ColorConsts.warning)
        self.mediator.p_text_tips:SetVisible(true)
        self.mediator.p_btn_search:SetVisible(false )
    elseif lockedByLandform then
        local landConfig =  ConfigRefer.Land:Find(petMonsterConfig:LandId())
        local landName = I18N.Get(landConfig:Name())
        local tip = I18N.GetWithParams("land_pet_movecity_unlock", landName)
        self.mediator.p_text_tips.text = tip
        self.mediator.p_text_tips.color = UIHelper.TryParseHtmlString(ColorConsts.warning)
        self.mediator.p_text_tips:SetVisible(true)
        self.mediator.p_btn_search:SetVisible(false )
    else
        self.mediator.p_text_tips.color = UIHelper.TryParseHtmlString(ColorConsts.dark_grey_1)
        self.mediator.p_text_tips:SetVisible(false)
        self.mediator.p_btn_search:SetVisible(true  )
    end
end

---@return number, number
function UIWorldSearchStatePet:GetMaxLevels()
    local maxAttackLevel = ModuleRefer.WorldSearchModule:GetCanAttackNormalMobLevel()
    local maxLevel = ModuleRefer.WorldSearchModule:GetMaxMobLevel()
    return maxAttackLevel, maxLevel
end

function UIWorldSearchStatePet:GetReachMaxAttackLevelTip()
    local maxAttackLevel = ModuleRefer.WorldSearchModule:GetCanAttackPetLevel()
    return I18N.GetWithParams("searchentity_toast_lowlv_4", maxAttackLevel)
end

function UIWorldSearchStatePet:GetSearchCategory()
    return SearchCategory.Pet
end

function UIWorldSearchStatePet:GetSelectedID()
    return self.selectedPetID
end

return UIWorldSearchStatePet