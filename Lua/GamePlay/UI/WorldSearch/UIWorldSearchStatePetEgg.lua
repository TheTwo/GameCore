local UIWorldSearchState = require("UIWorldSearchState")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local SearchCategory = require('SearchCategory')
local OutputResourceType = require("OutputResourceType")

---@class UIWorldSearchStatePetEgg : UIWorldSearchState
local UIWorldSearchStatePetEgg = class("UIWorldSearchStatePetEgg", UIWorldSearchState)

---@param data UIWorldSearchStateResourceFieldParameter
function UIWorldSearchStatePetEgg:Select(mediator, data)
    UIWorldSearchStatePetEgg.super.Select(self, mediator, data)
    self.resourceFieldConfigList = data.resourceFieldConfigList
    self.category = SearchCategory.ResourcePetEgg
    self.outputType = OutputResourceType.PetEgg

    self.mediator.p_text_egg_collect.text = I18N.Get("mining_info_collect_reward")
    self.mediator.p_text_reward.text = I18N.Get("searchentity_info_possible_reward")

    self.mediator.p_reward:SetVisible(false)
    self.mediator.p_search_resources:SetVisible(false)
    self.mediator.p_search_pet:SetVisible(false)
    self.mediator.p_search_egg:SetVisible(true)
end

function UIWorldSearchStatePetEgg:SetLevel(level)
    UIWorldSearchStatePetEgg.super.SetLevel(self, level)

    ---@type FixedMapBuildingConfigCell
    local resourceFieldConfig
    for _, configID in ipairs(self.resourceFieldConfigList) do
        local config = ConfigRefer.FixedMapBuilding:Find(configID)
        if config:OutputType() == self.outputType and config:Level() == level then
            resourceFieldConfig = config
            break
        end
    end

    if resourceFieldConfig then
        self:RefreshPetRewards(resourceFieldConfig)
        self:RefreshSearchState(level)
    end
end

---@param resourceFieldConfig FixedMapBuildingConfigCell
function UIWorldSearchStatePetEgg:RefreshPetRewards(resourceFieldConfig)
    local petEggName = I18N.Get("mining_info_pet_egg")
    local totalAmount = resourceFieldConfig:OutputResourceMax()
    self.mediator.p_text_egg_collect_quantity.text = ("%sx%s"):format(petEggName, totalAmount)

    self.mediator.p_table_egg:Clear()
    if resourceFieldConfig then
        local petConfigs = ModuleRefer.WorldSearchModule:GetPetEggDrop(resourceFieldConfig:OutputResourcePetDrop())

        for _, petConfig in ipairs(petConfigs) do
            ---@type CommonPetIconBaseData
            local petIconData = {}
            petIconData.cfgId = petConfig:Id()
            petIconData.selected = false

            ---@type WorldSearchPetTableData
            local iconData = {}
            iconData.petData = petIconData
            iconData.isNew = false
            self.mediator.p_table_egg:AppendData(iconData)
        end
    end
    self.mediator.p_table_egg:RefreshAllShownItem()
end

function UIWorldSearchStatePetEgg:RefreshSearchState(level)
    local landID = ModuleRefer.WorldSearchModule:GetResourceFieldOpenLandID(self.resourceFieldConfigList, self.outputType, level)
    if not ModuleRefer.LandformModule:IsLandformUnlockByCfgId(landID) then
        local landConfigCell = ConfigRefer.Land:Find(landID)
        local landName = I18N.Get(landConfigCell:Name())
        self.mediator.p_text_tips.text = I18N.GetWithParams("mining_info_collection_after_stage", landName)
        self.mediator.p_text_tips:SetVisible(true)
        self.mediator.p_btn_search:SetVisible(false)
    else
        self.mediator.p_text_tips:SetVisible(false)
        self.mediator.p_btn_search:SetVisible(true)
    end
end

---@return number, number
function UIWorldSearchStatePetEgg:GetMaxLevels()
    local maxLevel = ModuleRefer.WorldSearchModule:GetMaxResourceFieldLevel(OutputResourceType.PetEgg)
    return maxLevel, maxLevel
end

function UIWorldSearchStatePetEgg:GetSearchCategory()
    return self.category
end

function UIWorldSearchStatePetEgg:GetSelectedID()
    return self.outputType
end

return UIWorldSearchStatePetEgg