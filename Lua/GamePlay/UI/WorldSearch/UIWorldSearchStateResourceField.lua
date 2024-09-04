local UIWorldSearchState = require("UIWorldSearchState")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local SearchCategory = require('SearchCategory')

---@class UIWorldSearchStateResourceFieldParameter
---@field category number
---@field outputType number
---@field resourceFieldConfigList number[]


---@class UIWorldSearchStateResourceField : UIWorldSearchState
---@field resourceFieldConfigList number[]
---@field resourceIconDataMap table<number, ResourceFieldIconData>
---@field category number
---@field outputType number
local UIWorldSearchStateResourceField = class("UIWorldSearchStateResourceField", UIWorldSearchState)

---@param data UIWorldSearchStateResourceFieldParameter
function UIWorldSearchStateResourceField:Select(mediator, data)
    UIWorldSearchStateResourceField.super.Select(self, mediator, data)
    self.resourceFieldConfigList = data.resourceFieldConfigList
    self.category = data.category
    self.outputType = data.outputType

    self.mediator.p_text_reward.text = I18N.Get("searchentity_info_bound_reward")

    self.mediator.p_reward:SetVisible(true)
    self.mediator.p_search_resources:SetVisible(false)
    self.mediator.p_search_pet:SetVisible(false)
    self.mediator.p_search_egg:SetVisible(false)
end


function UIWorldSearchStateResourceField:SetLevel(level)
    UIWorldSearchStateResourceField.super.SetLevel(self, level)

    self:RefreshRewards(self.outputType, level)
    self:RefreshSearchState(level)
end

function UIWorldSearchStateResourceField:RefreshRewards(type, level)
    ---@type FixedMapBuildingConfigCell
    local resourceFieldConfig
    for _, configID in ipairs(self.resourceFieldConfigList) do
        local config = ConfigRefer.FixedMapBuilding:Find(configID)
        if config:OutputType() == type and config:Level() == level then
            resourceFieldConfig = config
            break
        end
    end
    
    self.mediator.p_table_reward:Clear()

    if resourceFieldConfig then
        ---@type ItemIconData
        local iconData = {}
        iconData.configCell = ConfigRefer.Item:Find(resourceFieldConfig:OutputResourceItem())
        iconData.showCount = true
        iconData.count = resourceFieldConfig:OutputResourceMax()
        self.mediator.p_table_reward:AppendData(iconData)
    end
    self.mediator.p_table_reward:RefreshAllShownItem()
end

function UIWorldSearchStateResourceField:RefreshSearchState(level)
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
function UIWorldSearchStateResourceField:GetMaxLevels()
    local maxLevel = ModuleRefer.WorldSearchModule:GetMaxResourceFieldLevel(self.outputType)
    return maxLevel, maxLevel
end

function UIWorldSearchStateResourceField:GetSearchCategory()
    return self.category
end

function UIWorldSearchStateResourceField:GetSelectedID()
    return self.outputType
end

return UIWorldSearchStateResourceField