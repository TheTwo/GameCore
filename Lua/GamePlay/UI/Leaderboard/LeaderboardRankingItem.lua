local BaseUIComponent = require('BaseUIComponent')
local NumberFormatter = require('NumberFormatter')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local LeaderboardUIPetCircle = require('LeaderboardUIPetCircle')
local Utils = require('Utils')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")

local LeaderboardHeadType = require('LeaderboardHeadType')
local LeaderElementTextType = require('LeaderElementTextType')
local LeaderElementIconType = require('LeaderElementIconType')

---@class LeaderboardRankingItemData
---@field rankMemData wds.TopListMemData
---@field rank number
---@field color CS.UnityEngine.Color
---@field leaderboardId number
---@field leaderboardActivityID number @LeaderboardActivity
---@field isBottom boolean

---@class LeaderboardRankingItem:BaseUIComponent
---@field new fun():LeaderboardRankingItem
---@field super BaseUIComponent
local LeaderboardRankingItem = class('LeaderboardRankingItem', BaseUIComponent)

function LeaderboardRankingItem:OnCreate()
    self.goGroupRank = self:GameObject('p_rank')
    self.goRankTop1 = self:GameObject('p_icon_rank_top_1')
    self.goRankTop2 = self:GameObject('p_icon_rank_top_2')
    self.goRankTop3 = self:GameObject('p_icon_rank_top_3')
    self.txtRankOther = self:Text('p_text_rank')
    self.imgBg = self:Image('p_base_content')

    self.goGroupPet = self:GameObject('p_pet')
    ---@type CommonPetIconBase
    self.petCicle = self:LuaObject('child_card_pet_circle')

    self.goGroupHero = self:GameObject('p_hero')
    ---@type HeroInfoItemSmallComponent
    self.child_card_hero_s_ex = self:LuaObject('child_card_hero_s_ex')

    self.goGroupPlayer = self:GameObject('p_player')
    ---@type PlayerInfoComponent
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')

    self.goGroupLeague = self:GameObject('p_league')
    ---@type CommonAllianceLogoComponent
    self.leagueLogo = self:LuaObject('child_league_logo')
    self.txtLeagueName = self:Text('p_text_league')
    self.p_btn_alliance = self:Button("p_btn_alliance", Delegate.GetOrCreate(self, self.OnClickAlliance))

    self.goGroupBehemoth = self:GameObject('p_behemoth')
    ---@type AllianceBehemothHeadCell
    self.behemothIcon = self:LuaObject('child_behemoth_head')

    self.goGroupLeader = self:GameObject('p_leader')
    self.txtLeaderName = self:Text('p_text_leader')
    ---@type PlayerInfoComponent
    self.leaderIcon = self:LuaObject('child_ui_head_player_leader')

    self.goGroupPvplevel = self:GameObject('p_pvplevel')
    self.imgPvplevelIcon = self:Image('p_icon_pvplevel')
    self.imgPvplevelNum = self:Image('p_icon_pvplevel_num')

    self.goGroupSchedule = self:GameObject('p_text_schedule')
    self.txtSchedule = self:Text('p_text_schedule')

    self.goGroupTime = self:GameObject('p_time')
    self.txtDate = self:Text('p_text_tower_schedule')
    self.txtHours = self:Text('p_text_tower_time')

    self.goGroupPower = self:GameObject('p_text_power')
    self.txtPower = self:Text('p_text_power')

    self.goGroupScore = self:GameObject('p_text_score')
    self.txtScore = self:Text('p_text_score')

    self.goGroupDistrict = self:GameObject('p_text_province')
    self.txtDistrict = self:Text('p_text_province')
    
    self.goGroupRewards = self:GameObject('p_reward')
    self.tableRewards = self:TableViewPro('p_table_reward')

    -- 这里的顺序，约定跟：LeaderboardHeadType 一致
    ---@type table <number, CS.UnityEngine.GameObject>
    self.groups = {}
    self.groups[LeaderboardHeadType.Rank] = self.goGroupRank
    self.groups[LeaderboardHeadType.Pet] = self.goGroupPet
    self.groups[LeaderboardHeadType.Hero] = self.goGroupHero
    self.groups[LeaderboardHeadType.Player] = self.goGroupPlayer
    self.groups[LeaderboardHeadType.League] = self.goGroupLeague
    self.groups[LeaderboardHeadType.Behemoth] = self.goGroupBehemoth
    self.groups[LeaderboardHeadType.Leader] = self.goGroupLeader
    self.groups[LeaderboardHeadType.PvpLevel] = self.goGroupPvplevel
    self.groups[LeaderboardHeadType.Schedule] = self.goGroupSchedule
    self.groups[LeaderboardHeadType.Time] = self.goGroupTime
    self.groups[LeaderboardHeadType.Power] = self.goGroupPower
    self.groups[LeaderboardHeadType.Score] = self.goGroupScore
    self.groups[LeaderboardHeadType.District] = self.goGroupDistrict
    self.groups[LeaderboardHeadType.Rewards] = self.goGroupRewards
end

---@param data LeaderboardRankingItemData
function LeaderboardRankingItem:OnFeedData(data)
    self.rank = data.rank
    self.leaderboardId = data.leaderboardId
    self.leaderboardActivityID = data.leaderboardActivityID
    self.rankMemData = data.rankMemData
    self.isBottom = data.isBottom
    self.color = data.color
    
    self:SetRank(self.rank)
    self:SetupElements()
end

---@param rank number
function LeaderboardRankingItem:SetRank(rank)
    self.goRankTop1:SetVisible(rank == 1)
    self.goRankTop2:SetVisible(rank == 2)
    self.goRankTop3:SetVisible(rank == 3)
    self.txtRankOther:SetVisible(rank > 3)
    if rank > 3 then
        self.txtRankOther.text = tostring(rank)
    end

    local bgImage = ModuleRefer.LeaderboardModule:GetRankItemBackgroundImagePath(rank, self.isBottom)
    g_Game.SpriteManager:LoadSprite(bgImage, self.imgBg)
end

function LeaderboardRankingItem:SetupElements()
    for index, group in pairs(self.groups) do
        if index ~= 1 then
            group:SetVisible(false)
        end
    end

    local leaderboardConfigCell = ConfigRefer.Leaderboard:Find(self.leaderboardId)
    for i = 1, leaderboardConfigCell:ShowElemLength() do
        local elementId = leaderboardConfigCell:ShowElem(i)
        self:SetupElement(elementId)
    end
end

function LeaderboardRankingItem:SetupElement(elementId)
    local elementConfigCell = ConfigRefer.LeaderElement:Find(elementId)
    local headerIndex = ModuleRefer.LeaderboardModule:GetLeaderboardHeadTypeIndex(elementConfigCell)
    if headerIndex == LeaderboardHeadType.Pet then
        self:SetupElementPet(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Hero then
        self:SetupElementHero(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Player then
        self:SetupElementPlayer(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.League then
        self:SetupElementLeague(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Behemoth then
        self:SetupElementBehemoth(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Leader then
        self:SetupElementLeader(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.PvpLevel then
        self:SetupElementPvpLevel(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Schedule then
        self:SetupElementSchedule(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Time then
        self:SetupElementTime(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Power then
        self:SetupElementPower(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Score then
        self:SetupElementScore(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.District then
        self:SetupElementDistrict(elementConfigCell)
    elseif headerIndex == LeaderboardHeadType.Rewards then
        self:SetupElementRewards(elementConfigCell)
    end
end

---宠物, 巨兽头像展示
---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementPet(elementConfigCell)
    self.goGroupPet:SetVisible(true)

    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if textType == LeaderElementTextType.PetName and iconType == LeaderElementIconType.PetPortrait then

        local skillInfo = self.rankMemData.Pet.SkillQualityLevel
        local skillLevels = {}
        for k, v in pairs(skillInfo) do
            local data = {}
            data.quality = k
            data.level = v
            table.insert(skillLevels, data)
        end

        local petData = {}
        petData.cfgId = self.rankMemData.Pet.PetTid
        petData.level = self.rankMemData.Pet.PetLevel
        petData.rank = self.rankMemData.Pet.PetStarLevel
        -- petData.id = self.rankMemData.Pet.PetCompId
        petData.skillLevels = skillLevels
        self.petCicle:FeedData(petData)
    elseif textType == LeaderElementTextType.BehemothLevel and iconType == LeaderElementIconType.None then
        ---@type LeaderboardUIPetCircleData
        local behemothData = {}
        behemothData.type = LeaderboardUIPetCircle.Type.Behemoth
        behemothData.cfgId = self.rankMemData.Behemoth.MonsterCfgId
        behemothData.level = self.rankMemData.Behemoth.Level
        self.petCicle:FeedData(behemothData)
    end
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementHero(elementConfigCell)
    self.goGroupHero:SetVisible(true)

    local heroConfigCell = ConfigRefer.Heroes:Find(self.rankMemData.Hero.HeroTid)
    local heroResConfigCell = ConfigRefer.HeroClientRes:Find(heroConfigCell:ClientResCfg())
    local heroData = {}
    heroData.Id = heroConfigCell:Id()
    heroData.lv = self.rankMemData.Hero.HeroLevel
    heroData.starLevel = self.rankMemData.Hero.HeroStarLevel
    heroData.configCell = heroConfigCell
    heroData.resCell = heroResConfigCell
    self.child_card_hero_s_ex:FeedData({heroData = heroData, })
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementPlayer(elementConfigCell)
    self.goGroupPlayer:SetVisible(true)

    local param = {}
    Utils.CopyTable(self.rankMemData.Player.PortraitInfo, param)
    param.PlayerId = self.rankMemData.PlayerId
    param.TypeName = "wds.PortraitInfo"
    self.playerIcon:FeedData(param)
    self.txtPlayerName.text = self.rankMemData.Player.PlayerName
    self.txtPlayerName.color = self.color or self.txtPlayerName.color
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementLeague(elementConfigCell)
    self.goGroupLeague:SetVisible(true)

    self.leagueLogo:FeedData(self.rankMemData.Alliance.Flag)
    self.txtLeagueName.text = self.rankMemData.Alliance.AllianceName
    self.txtLeagueName.color = self.color or self.txtLeagueName.color
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementBehemoth(elementConfigCell)
    self.goGroupBehemoth:SetVisible(true)
    local cfgId = self.rankMemData.Behemoth.MonsterCfgId
    local kMonsterCfg = ConfigRefer.KmonsterData:Find(cfgId)
    local _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(kMonsterCfg)
    ---@type AllianceBehemothHeadCellData
    local behemothData = {}
    behemothData.icon = icon
    behemothData.lv = self.rankMemData.Behemoth.Level
    behemothData.isSelected = false
    self.behemothIcon:FeedData(behemothData)
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementLeader(elementConfigCell)
    self.goGroupLeader:SetVisible(true)

    local param = {}
    Utils.CopyTable(self.rankMemData.Alliance.AllianceLeader.PortraitInfo, param)
    param.PlayerId = self.rankMemData.Alliance.AllianceLeader.PlayerId
    param.TypeName = "wds.PortraitInfo"
    self.leaderIcon:FeedData(param)
    self.txtLeaderName.text = self.rankMemData.Alliance.AllianceLeader.PlayerName
    self.txtLeaderName.color = self.color or self.txtLeaderName.color
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementPvpLevel(elementConfigCell)
    self.goGroupPvplevel:SetVisible(true)

    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if iconType == LeaderElementIconType.PvpTitle and textType == LeaderElementTextType.None then
        local pvpTitleStageCfgCell = ConfigRefer.PvpTitleStage:Find(self.rankMemData.PVP.TitleStageTid)
        if pvpTitleStageCfgCell then
            self:LoadSprite(pvpTitleStageCfgCell:Icon(), self.imgPvplevelIcon)
            self.imgPvplevelNum:SetVisible(pvpTitleStageCfgCell:LevelIcon() > 0)
            if pvpTitleStageCfgCell:LevelIcon() > 0 then
                self:LoadSprite(pvpTitleStageCfgCell:LevelIcon(), self.imgPvplevelNum)
            end
        end
    end
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementSchedule(elementConfigCell)
    self.goGroupSchedule:SetVisible(true)

    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if iconType == LeaderElementIconType.None and textType == LeaderElementTextType.HuntLevel then
        local sectionConfigCell = ConfigRefer.HuntingSection:Find(self.rankMemData.Hunt.SectorId)
        if sectionConfigCell then
            self.txtSchedule.text = I18N.Get(sectionConfigCell:Name())
            self.txtSchedule.color = self.color or self.txtSchedule.color
        end
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.TowerLevel then
        local sectionConfigCell = ConfigRefer.ClimbTowerSection:Find(self.rankMemData.Tower.Sector)
        if sectionConfigCell then
            self.txtSchedule.text = I18N.Get(sectionConfigCell:Name())
            self.txtSchedule.color = self.color or self.txtSchedule.color
        end
    else
        self.txtSchedule.text = '*NotSupport'
        self.txtSchedule.color = self.color or self.txtSchedule.color
    end
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementTime(elementConfigCell)
    self.goGroupTime:SetVisible(true)

    local timestampInSeconds = 0
    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if iconType == LeaderElementIconType.None and textType == LeaderElementTextType.TowerFirstTime then
        timestampInSeconds = self.rankMemData.Tower.FirstTimestamp.Seconds
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.HuntFirstTime then
        timestampInSeconds = self.rankMemData.Hunt.FirstTimestamp.Seconds
    end

    local csDate = CS.TimeUtils.GetDateTimeFromTimestampSeconds(timestampInSeconds)
    self.txtDate.text = csDate:ToShortDateString()
    self.txtHours.text = csDate:ToString('HH:mm:ss')
    self.txtDate.color = self.color or self.txtDate.color
    self.txtHours.color = self.color or self.txtHours.color
end

---需要写自定义逻辑，从db中取power数据
---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementPower(elementConfigCell)
    self.goGroupPower:SetVisible(true)

    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if iconType == LeaderElementIconType.None and textType == LeaderElementTextType.PlayerPower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Player.PlayerPower)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.AlliancePower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Alliance.AlliancePower)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.HeroPower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Hero.HeroPower)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.PetPower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Pet.PetPower)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.AllianceFaction then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Alliance.AllianceFaction)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.PvpPresetPower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.PVP.PresetPower)
        self.txtPower.color = self.color or self.txtPower.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.BehemothPower then
        self.txtPower.text = NumberFormatter.Normal(self.rankMemData.Behemoth.Power)
        self.txtPower.color = self.color or self.txtPower.color
    end
end

---需要写自定义逻辑，从db中取score数据
---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementScore(elementConfigCell)
    self.goGroupScore:SetVisible(true)

    local iconType = elementConfigCell:IconType()
    local textType = elementConfigCell:TextType()
    if iconType == LeaderElementIconType.None and textType == LeaderElementTextType.ReplicaPvpScore then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.PVP.Score)
        self.txtScore.color = self.color or self.txtScore.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.PlayerWorldStagePlanScore then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.Player.StagePlan)
        self.txtScore.color = self.color or self.txtScore.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.AllianceWorldStagePlanScore then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.Alliance.AllianceStagePlan)
        self.txtScore.color = self.color or self.txtScore.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.PlayerWorldStageContribution then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.Player.StageContribution)
        self.txtScore.color = self.color or self.txtScore.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.AllianceWorldStageContribution then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.Alliance.AllianceStageContribution)
        self.txtScore.color = self.color or self.txtScore.color
    elseif iconType == LeaderElementIconType.None and textType == LeaderElementTextType.AllianceScoreRewardScore then
        self.txtScore.text = NumberFormatter.Normal(self.rankMemData.Alliance.ScoreRewardScore)
        self.txtScore.color = self.color or self.txtScore.color
    end
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementDistrict(elementConfigCell) 
    self.goGroupDistrict:SetVisible(true)

    local districtID = self.rankMemData.MapBasic.DistrictId
    self.txtDistrict.text = ModuleRefer.TerritoryModule:GetDistrictName(districtID)
end

---@param elementConfigCell LeaderElementConfigCell
function LeaderboardRankingItem:SetupElementRewards(elementConfigCell)
    self.goGroupRewards:SetVisible(true)
    self.tableRewards:Clear()
    
    local leaderboardActivityConfig = ConfigRefer.LeaderboardActivity:Find(self.leaderboardActivityID)
    if not leaderboardActivityConfig then
        return 0
    end

    local itemGroupID = ModuleRefer.LeaderboardModule:GetActivityLeaderboardRankRewardByRank(leaderboardActivityConfig, self.rank)
    if itemGroupID > 0 then
        local itemGroupConfig = ConfigRefer.ItemGroup:Find(itemGroupID)
        local length = itemGroupConfig:ItemGroupInfoListLength()
        for i = 1, length do
            local itemInfo = itemGroupConfig:ItemGroupInfoList(i)
            local itemID = itemInfo:Items()
            local itemCount = itemInfo:Nums()
            ---@type ItemIconData
            local iconData = 
            {
                configCell = ConfigRefer.Item:Find(itemID),
                showCount = true,
                count = itemCount,
            }
            self.tableRewards:AppendData(iconData)
        end
        self.tableRewards:RefreshAllShownItem()
    end
end

function LeaderboardRankingItem:OnClickAlliance()
    local msg = require("GetPlayerBriefInfoParameter").new()
    msg.args.PlayerIds:Add(self.rankMemData.Alliance.AllianceLeader.PlayerId)
    msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            local playerInfo = resp.PlayerInfos[1]
            if not playerInfo then
                g_Logger.Error("无法找到联盟盟主，可能是机器人或者已被清库")
                return
            end
            g_Game.UIManager:Open(UIMediatorNames.AllianceInfoPopupMediator, {allianceId = playerInfo.AllianceId, tab = 1})
        else
            return
        end
    end)
end

return LeaderboardRankingItem