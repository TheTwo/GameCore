local UIWorldSearchState = require("UIWorldSearchState")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local SearchCategory = require('SearchCategory')

---@class UIWorldSearchStateMonster : UIWorldSearchState
---@field monsterConfigs table<number>
local UIWorldSearchStateMonster = class("UIWorldSearchStateMonster", UIWorldSearchState)

function UIWorldSearchStateMonster:Select(mediator, data)
    UIWorldSearchStateMonster.super.Select(self, mediator, data)
    self.monsterConfigs = data

    self.mediator.p_reward:SetVisible(true)
    self.mediator.p_search_resources:SetVisible(false)
    self.mediator.p_search_pet:SetVisible(false)
    self.mediator.p_search_egg:SetVisible(false)
    self.mediator.p_text_tips:SetVisible(false)
    self.mediator.p_btn_search:SetVisible(true)
end

function UIWorldSearchStateMonster:SetLevel(level)
    UIWorldSearchStateMonster.super.SetLevel(self, level)

    ---@type ItemGroupInfo[]
    local itemInfos
    if ModuleRefer.WorldSearchModule:IsFirstKillMonster(level) then
        self.mediator.p_text_reward.text = I18N.Get("searchentity_info_firstkill_reward")
        itemInfos = ModuleRefer.WorldSearchModule:GetMonsterFirstKillDropItems(level)
    else
        self.mediator.p_text_reward.text = I18N.Get("searchentity_info_bound_reward")
        local monsterConfig
        for _, configID in ipairs(self.monsterConfigs) do
            local config = ConfigRefer.KmonsterData:Find(configID)
            if config:Level() == level then
                monsterConfig = config
                break
            end
        end
        if monsterConfig then
            itemInfos = ModuleRefer.WorldSearchModule:GetMonsterDropItems(monsterConfig)
        end
    end

    self.mediator.p_table_reward:Clear()
    if itemInfos then
        for _, item in ipairs(itemInfos) do
            local itemConfig = ConfigRefer.Item:Find(item:Items())
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = itemConfig
            iconData.showCount = true
            iconData.count = item:Nums()
            self.mediator.p_table_reward:AppendData(iconData)
        end
    end
    self.mediator.p_table_reward:RefreshAllShownItem()
end

---@return number, number
function UIWorldSearchStateMonster:GetMaxLevels()
    local maxAttackLevel = ModuleRefer.WorldSearchModule:GetCanAttackNormalMobLevel()
    local maxLevel = ModuleRefer.WorldSearchModule:GetMaxMobLevel()
    return maxAttackLevel, maxLevel
end

function UIWorldSearchStateMonster:GetReachMaxAttackLevelTip()
    local maxAttackLevel = ModuleRefer.WorldSearchModule:GetCanAttackNormalMobLevel()
    return I18N.GetWithParams("searchentity_toast_lowlv_1", maxAttackLevel)
end

function UIWorldSearchStateMonster:GetSearchCategory()
    return SearchCategory.Monster
end

function UIWorldSearchStateMonster:GetSelectedID()
    return 0
end

return UIWorldSearchStateMonster