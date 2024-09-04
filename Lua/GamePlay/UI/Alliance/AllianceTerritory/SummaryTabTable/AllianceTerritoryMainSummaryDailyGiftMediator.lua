--- scene:scene_league_territory
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local MapBuildingType = require("MapBuildingType")
local MapBuildingSubType = require("MapBuildingSubType")
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local ActivityCenterConst = require("ActivityCenterConst")
local AllianceModuleDefine = require('AllianceModuleDefine')
local NotificationType = require('NotificationType')
local BaseUIMediator = require("BaseUIMediator")

local AllianceTerritoryMainSummaryDailyGiftMediator = class('AllianceTerritoryMainSummaryDailyGiftMediator', BaseUIMediator)

function AllianceTerritoryMainSummaryDailyGiftMediator:ctor()
end

function AllianceTerritoryMainSummaryDailyGiftMediator:OnCreate(param)
    self.overview = self:GameObject('p_pet_book_overview')
    self.p_text_name = self:Text('p_text_name', 'bw_info_land_mob_reward')
    self.p_text_influence = self:Text('p_text_influence', 'Alliance_bj_shilizhi')
    self.p_text_influence_number = self:Text('p_text_influence_number')
    self.p_text_content = self:Text('p_text_content', 'alliance_territory_reward_desc')
    self.icon_influence = self:Image('icon_influence')
    self.p_table = self:TableViewPro('p_table')
end

function AllianceTerritoryMainSummaryDailyGiftMediator:OnOpened(curValue)
    self.p_text_influence_number.text = curValue
    local cfg = ConfigRefer.AllianceConsts
    local lastIndex = cfg:FactionDailyRewardNeedFactionLength()
    self.p_table:Clear()
    for i = 1, lastIndex do
        local itemGroup = ConfigRefer.ItemGroup:Find(cfg:FactionDailyRewardItemGroup(i))
        local lastValue = cfg:FactionDailyRewardNeedFaction(i)
        local nextIndex = i + 1
        local isLast
        local percent = 0
        if nextIndex <= lastIndex then
            isLast = false
            local nextValue = cfg:FactionDailyRewardNeedFaction(nextIndex)
            percent = (curValue - lastValue) / (nextValue - lastValue)
        else
            isLast = true
        end
        local isReach = curValue >= lastValue
        self.p_table:AppendData({itemGroup = itemGroup, value = lastValue, isLast = isLast, isReach = isReach, percent = percent})

    end
end

function AllianceTerritoryMainSummaryDailyGiftMediator:OnShow(param)
end

function AllianceTerritoryMainSummaryDailyGiftMediator:OnHide(param)
end

return AllianceTerritoryMainSummaryDailyGiftMediator
