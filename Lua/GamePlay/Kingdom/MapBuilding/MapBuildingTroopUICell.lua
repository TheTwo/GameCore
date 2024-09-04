local BaseTableViewProCell = require("BaseTableViewProCell")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local NumberFormatter = require("NumberFormatter")
local HeroUIUtilities = require('HeroUIUtilities')
local I18N = require("I18N")

---@class MapBuildingTroopUICellParameter
---@field EntityID number
---@field ArmyMemberInfo wds.ArmyMemberInfo
---@field TroopConfigId number
---@field IsMarching boolean
---@field IsStrengthen boolean
---@field playerId number
---@field troopId number

---@class MapBuildingTroopUICell : BaseTableViewProCell
---@field param MapBuildingTroopUICellParameter
---@field armyMemberInfo wds.ArmyMemberInfo
---@field troopConfig KmonsterDataConfigCell
---@field heroIds table<number>
---@field heroDataList table<HeroConfigCache>
---@field isStrengthen boolean
---@field headPlayer PlayerInfoComponent
---@field heroHeadList HeroInfoItemSmallComponent[]
---@field targetTroopId number
local MapBuildingTroopUICell = class("MapBuildingTroopUICell", BaseTableViewProCell)

function MapBuildingTroopUICell:OnCreate(param)
    self.headPlayer = self:LuaObject("child_ui_head_player")
    self.textNamePlayer = self:Text('p_text_name_player')
    self.textNameOneself = self:Text('p_text_name_oneself')
    ---@type HeroInfoItemSmallComponent
    self.head1 = self:LuaObject('p_hero_head_1')
    ---@type HeroInfoItemSmallComponent
    self.head2 = self:LuaObject('p_hero_head_2')
    ---@type HeroInfoItemSmallComponent
    self.head3 = self:LuaObject('p_hero_head_3')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnRemoveClicked))
    self.imgIconTroopType = self:Image('p_icon_troop_type')
    self.textQuantity = self:Text('p_text_quantity')

    if self.imgIconTroopType then
        self.imgIconTroopType:SetVisible(false)
    end
    if self.textQuantity then
        self.textQuantity:SetVisible(false)
    end

    ---@type HeroInfoItemSmallComponent[]
    self.heroHeadList = {}
    table.insert(self.heroHeadList, self.head1)
    table.insert(self.heroHeadList, self.head2)
    table.insert(self.heroHeadList, self.head3)
    
    self.heroIds = {}
    self.heroDataList = {}
end

---@param param MapBuildingTroopUICellParameter|KmonsterDataConfigCell
function MapBuildingTroopUICell:OnFeedData(param)
    self.param = param
    self.isStrengthen = param.IsStrengthen
    self.targetTroopId = nil
    if param.ArmyMemberInfo then
        self.armyMemberInfo = param.ArmyMemberInfo
        self.targetTroopId = self.armyMemberInfo.Id
        local isMyTroop = ModuleRefer.PlayerModule:IsMineById(self.armyMemberInfo.PlayerId)
        table.clear(self.heroDataList)
        local headHeroConfig
        for i = 1, #self.armyMemberInfo.HeroTId do
            local heroID = self.armyMemberInfo.HeroTId[i]
            local heroLevel = self.armyMemberInfo.HeroLevel[i]
            local heroStar = self.armyMemberInfo.StarLevel[i]
            local heroConfig = ConfigRefer.Heroes:Find(heroID)
            if not headHeroConfig then
                headHeroConfig = heroConfig
            end
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
        local fullName
        if self.armyMemberInfo.PlayerId == 0 then
            fullName = I18N.Get("village_info_Garrison_Defenders")
        else
            headHeroConfig = nil
            fullName = ModuleRefer.PlayerModule.FullName(self.armyMemberInfo.AllianceAbbr, self.armyMemberInfo.Name)
        end
        local spriteName = ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(headHeroConfig)
        self:RefreshIsMyTroop(isMyTroop, param.IsMarching, fullName, self.armyMemberInfo.PortraitInfo, spriteName)

        self:RefreshHeroes(self.heroDataList)
    elseif param.troopId and param.playerId then
        self.targetTroopId = param.troopId
        ---@type wds.Troop
        local troopData = g_Game.DatabaseManager:GetEntity(param.troopId, DBEntityType.Troop)
        if troopData then
            local isMyTroop = ModuleRefer.PlayerModule:IsMineById(troopData.Owner.PlayerID)
            local fullName = ModuleRefer.PlayerModule.FullName(troopData.Owner.AllianceAbbr.String, troopData.Owner.PlayerName.String)
            self:RefreshIsMyTroop(isMyTroop, param.IsMarching, fullName)
            table.clear(self.heroDataList)
            for i, v in pairs(troopData.Battle.Group.Heros) do
                local heroID = v.HeroID
                local heroLevel = v.HeroLevel
                local heroStar = v.StarLevel
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
            self:RefreshHeroes(self.heroDataList)
        end
    elseif param.TroopConfigId and param.TroopConfigId ~= 0 then
        self.troopConfig = ConfigRefer.KmonsterData:Find(param.TroopConfigId)
        table.clear(self.heroDataList)
        local headHeroConfig
        for i = 1, self.troopConfig:HeroLength() do
            local heroNpcId = self.troopConfig:Hero(i):HeroConf()
            local heroNpcConfig = ConfigRefer.HeroNpc:Find(heroNpcId)
            local heroConfig = ConfigRefer.Heroes:Find(heroNpcConfig:HeroConfigId())
            if not headHeroConfig then
                headHeroConfig = heroConfig
            end
            local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
            ---@type HeroConfigCache
            local heroData = {}
            heroData.id = heroNpcId
            heroData.configCell = heroConfig
            heroData.resCell = heroResConfig
            heroData.lv = heroNpcConfig:HeroLevel()
            heroData.star = heroNpcConfig:StarLevel()
            table.insert(self.heroDataList, heroData)
        end

        local spriteName = ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(headHeroConfig)
        self:RefreshIsMyTroop(false, false, I18N.Get("village_info_Garrison_Defenders"), spriteName)

        self:RefreshHeroes(self.heroDataList)
        -- self:RefreshUnit(self.troopConfig:SoldierID(), self.troopConfig:SoldierCount())
    end
end

---@param isMyTroop boolean
---@param fullName string
function MapBuildingTroopUICell:RefreshIsMyTroop(isMyTroop, isMarching, fullName, headInfo, npcIcon)
    if isMyTroop then
        self.btnDetail:SetVisible(not isMarching)
        self.textNamePlayer.gameObject:SetVisible(false)
        self.textNameOneself.gameObject:SetVisible(true)
        self.textNameOneself.text = fullName
    else
        self.btnDetail:SetVisible(false)
        self.textNamePlayer.gameObject:SetVisible(true)
        self.textNameOneself.gameObject:SetVisible(false)
        self.textNamePlayer.text = fullName
    end
    if not string.IsNullOrEmpty(npcIcon) then
        local headIcon = {}
        headIcon.iconName = npcIcon
        self.headPlayer:FeedData(headIcon)
    else
        self.headPlayer:FeedData(headInfo)
    end
end

---@param heroDataList table<HeroConfigCache>
function MapBuildingTroopUICell:RefreshHeroes(heroDataList)
    for i = 1, #self.heroHeadList do
        local heroHead = self.heroHeadList[i]
        if i <= #heroDataList then
            ---@type HeroInfoData
            local headInfo = {}
            headInfo.heroData = heroDataList[i]
            -- headInfo.hideExtraInfo = true
            heroHead:FeedData(headInfo)
            heroHead:SetVisible(true)
        else
            heroHead:SetVisible(false)
        end
    end
end

---@param soldierConfigId number
---@param count number
function MapBuildingTroopUICell:RefreshUnit(soldierConfigId, count)
    if self.imgIconTroopType then
        self.imgIconTroopType:SetVisible(true)
        local soldierConfig = ConfigRefer.Soldier:Find(soldierConfigId)
        self:LoadSprite(HeroUIUtilities.GetSoldierTypeTextureID(soldierConfig:Type()), self.imgIconTroopType)
    end
    if self.textQuantity then
        self.textQuantity:SetVisible(true)
        self.textQuantity.text = NumberFormatter.Normal(count)
    end
end

function MapBuildingTroopUICell:OnRemoveClicked()
    if self.targetTroopId then
        ModuleRefer.MapBuildingTroopModule:LeaveTroopFrom(self.param.EntityID, self.targetTroopId, self.isStrengthen)
    end
end

return MapBuildingTroopUICell