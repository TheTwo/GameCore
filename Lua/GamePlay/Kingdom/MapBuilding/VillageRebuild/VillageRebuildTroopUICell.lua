local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@class VillageRebuildTroopUICell : BaseTableViewProCell
---@field heroIds table<number>
---@field heroDataList table<HeroConfigCache>
---@field headPlayer PlayerInfoComponent
---@field heroHeadList HeroInfoItemSmallComponent[]
local VillageRebuildTroopUICell = class("VillageRebuildTroopUICell", BaseTableViewProCell)

function VillageRebuildTroopUICell:OnCreate(param)
    self.headPlayer = self:LuaObject("child_ui_head_player")
    self.textNamePlayer = self:Text('p_text_name_player')
    self.textNameOneself = self:Text('p_text_name_oneself')
    ---@type HeroInfoItemSmallComponent
    self.head1 = self:LuaObject('p_hero_head_1')
    ---@type HeroInfoItemSmallComponent
    self.head2 = self:LuaObject('p_hero_head_2')
    ---@type HeroInfoItemSmallComponent
    self.head3 = self:LuaObject('p_hero_head_3')

    ---@type HeroInfoItemSmallComponent[]
    self.heroHeadList = {}
    table.insert(self.heroHeadList, self.head1)
    table.insert(self.heroHeadList, self.head2)
    table.insert(self.heroHeadList, self.head3)

    self.heroIds = {}
    self.heroDataList = {}
end

---@param param wds.ArmyMemberInfo
function VillageRebuildTroopUICell:OnFeedData(param)
    local armyMemberInfo = param

    table.clear(self.heroDataList)
    for i = 1, #armyMemberInfo.HeroTId do
        local heroID = armyMemberInfo.HeroTId[i]
        local heroLevel = armyMemberInfo.HeroLevel[i]
        local heroStar = armyMemberInfo.StarLevel[i]
        local heroConfig = ConfigRefer.Heroes:Find(heroID)
        local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
        ---@type HeroConfigCache
        local heroData = {}
        heroData.id = heroID
        heroData.configCell = heroConfig
        heroData.resCell = heroResConfig
        heroData.lv = heroLevel
        heroData.star = heroStar
        table.insert(self.heroDataList, heroData)
    end
    local fullName = ModuleRefer.PlayerModule.FullName(armyMemberInfo.AllianceAbbr, armyMemberInfo.Name)

    self.textNamePlayer.text = fullName
    self.headPlayer:FeedData(armyMemberInfo.PortraitInfo)
    for i = 1, #self.heroHeadList do
        local heroHead = self.heroHeadList[i]
        if i <= #self.heroDataList then
            ---@type HeroInfoData
            local headInfo = {}
            headInfo.heroData = self.heroDataList[i]
            heroHead:FeedData(headInfo)
            heroHead:SetVisible(true)
        else
            heroHead:SetVisible(false)
        end
    end
end

return VillageRebuildTroopUICell