local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EarthRevivalDefine = require('EarthRevivalDefine')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')
local WorldStageNewsContentType = require('WorldStageNewsContentType')
local WorldStageNewsPageContentType = require('WorldStageNewsPageContentType')

---@class EarthRevivalNewsPageComponent : BaseUIComponent
local EarthRevivalNewsPageComponent = class('EarthRevivalNewsPageComponent', BaseUIComponent)

function EarthRevivalNewsPageComponent:OnCreate()
    self.imgPage = self:Image('p_img_base')
    self.statusPage = self:StatusRecordParent('')
    
    self.goGroupVS = self:GameObject('group_vs')
    self.luagoEnemyAllianceLogo = self:LuaObject('child_league_logo_r')
    self.goCombatInfoBase = self:GameObject('combat_info_base')
    self.luagoLeaderGroup = self:LuaObject('group_league_leader')
    self.luagoMaxharmGroup = self:LuaObject('group_league_harm')
    self.luagoMaxScoreGroup = self:LuaObject('group_league_score')

    self.goGroupVillage = self:GameObject('group_village')
    self.textVillageNum = self:Text('p_text_village_number')

    self.luagoMyAllianceLogo = self:LuaObject('child_league_logo')
    self.imgBuilding = self:Image('p_icon_building')
    self.imgResearch = self:Image('p_icon_league_research')
    self.imgBoss = self:Image('p_icon_boss')
    self.luagoPortrait = self:LuaObject('child_ui_head_player')

    self.imgEvent = self:Image('p_icon_event')
    
    self.textAllianceName_1 = self:Text('p_text_name_league_1')
    self.textPlayerName_1 = self:Text('p_text_name_player_1')

    self.luagoPortrait_2 = self:LuaObject('child_ui_head_player_1')
    self.textAllianceName_2 = self:Text('p_text_name_league_2')
    self.textPlayerName_2 = self:Text('p_text_name_player_2')

    self.luagoPortrait_3 = self:LuaObject('child_ui_head_player_2')
    self.textAllianceName_3 = self:Text('p_text_name_league_3')
    self.textPlayerName_3 = self:Text('p_text_name_player_3')
end

---@param param EarthRevivalNewsData
function EarthRevivalNewsPageComponent:OnFeedData(param)
    if not param then
        return
    end
    if not string.IsNullOrEmpty(param.newsIcon) then
        g_Game.SpriteManager:LoadSprite(param.newsIcon, self.imgPage)
    end
    self.type, self.contentType = ModuleRefer.EarthRevivalModule:GetNewsSubType(param.newsConfigId)
    if self.type == -1 then
        return
    end
    self.statusPage:ApplyStatusRecord(self.type - 1)
    self:RefreshPageInfoByType(param.extraInfo)
end

---@param extraInfo wds.WorldStageNewsExtraInfo
function EarthRevivalNewsPageComponent:RefreshPageInfoByType(extraInfo)
    if self.type == WorldStageNewsPageContentType.AllianceVS then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        if extraInfo.OldAllianceFlag then
            self.luagoEnemyAllianceLogo:FeedData(extraInfo.OldAllianceFlag)
        end

        --关卡直接读配置的背景图，不需要额外处理
        if self.contentType ~= WorldStageNewsContentType.WSANewsOccupyPass then
            --地貌图
            local landConfig = ConfigRefer.Land:Find(extraInfo.LandTid)
            if landConfig then
                g_Game.SpriteManager:LoadSprite(landConfig:LandBackgroud(), self.imgPage)
            end

            --乡镇图
            local buildConfig = ConfigRefer.FixedMapBuilding:Find(extraInfo.ConfigId)
            if buildConfig then
                g_Game.SpriteManager:LoadSprite(buildConfig:BigImage(), self.imgBuilding)
            end
        end

        --战斗排行
        if extraInfo.AllianceLeader and self.luagoLeaderGroup then
            local param = {
                damageInfo = extraInfo.AllianceLeader,
                title = I18N.Get('worldstage_mz'),
            }
            self.luagoLeaderGroup:FeedData(param)
        end
        if extraInfo.SoldierDamage and self.luagoMaxharmGroup then
            local param = {
                damageInfo = extraInfo.SoldierDamage,
                title = I18N.Get('worldstage_zgsh'),
            }
            self.luagoMaxharmGroup:FeedData(param)
        end
        if extraInfo.ConstructDamage and self.luagoMaxScoreGroup then
            local param = {
                damageInfo = extraInfo.ConstructDamage,
                title = I18N.Get('worldstage_zgjf'),
            }
            self.luagoMaxScoreGroup:FeedData(param)
        end
    elseif self.type == WorldStageNewsPageContentType.Build then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        -- local buildConfig = ConfigRefer.FixedMapBuilding:Find(extraInfo.ConfigId)
        -- if buildConfig then
        --     g_Game.SpriteManager:LoadSprite(buildConfig:BigImage(), self.imgBuilding)
        -- end
    elseif self.type == WorldStageNewsPageContentType.Research then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
    elseif self.type == WorldStageNewsPageContentType.Boss then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        local fixMapBuildingConfig = ConfigRefer.FixedMapBuilding:Find(extraInfo.ConfigId)
        if not fixMapBuildingConfig then
            return
        end
        local behemothCageConfig = ConfigRefer.BehemothCage:Find(fixMapBuildingConfig:BehemothCageConfig())
        if not behemothCageConfig then
            return
        end
        local _,_,_,_,_,bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfigId(behemothCageConfig:Monster())
        g_Game.SpriteManager:LoadSprite(bodyPaint, self.imgBoss)
    elseif self.type == WorldStageNewsPageContentType.CreateAlliance then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        if extraInfo.PortraitInfo then
            self.luagoPortrait:FeedData(extraInfo.PortraitInfo)
        end
    elseif self.type == WorldStageNewsPageContentType.AllianceCombat then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        --关卡直接读配置的背景图，不需要额外处理
        if self.contentType ~= WorldStageNewsContentType.WSANewsOccupyPass then
            --地貌图
            local landConfig = ConfigRefer.Land:Find(extraInfo.LandTid)
            if landConfig then
                g_Game.SpriteManager:LoadSprite(landConfig:LandBackgroud(), self.imgPage)
            end

            --乡镇图
            local buildConfig = ConfigRefer.FixedMapBuilding:Find(extraInfo.ConfigId)
            if buildConfig then
                g_Game.SpriteManager:LoadSprite(buildConfig:BigImage(), self.imgBuilding)
            end
        end

        --战斗排行
        if extraInfo.AllianceLeader and self.luagoLeaderGroup then
            local param = {
                damageInfo = extraInfo.AllianceLeader,
                title = I18N.Get('worldstage_mz'),
            }
            self.luagoLeaderGroup:FeedData(param)
        end
        if extraInfo.SoldierDamage and self.luagoMaxharmGroup then
            local param = {
                damageInfo = extraInfo.SoldierDamage,
                title = I18N.Get('worldstage_zgsh'),
            }
            self.luagoMaxharmGroup:FeedData(param)
        end
        if extraInfo.ConstructDamage and self.luagoMaxScoreGroup then
            local param = {
                damageInfo = extraInfo.ConstructDamage,
                title = I18N.Get('worldstage_zgjf'),
            }
            self.luagoMaxScoreGroup:FeedData(param)
        end
    elseif self.type == WorldStageNewsPageContentType.Normal then
        return
    elseif self.type == WorldStageNewsPageContentType.MultiCombat then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        self.textVillageNum.text = string.format("x%d", extraInfo.Count)
    elseif self.type == WorldStageNewsPageContentType.ArenaTop3 then
        if not extraInfo.Rank then
            return
        end
        if extraInfo.Rank[1] then
            self.luagoPortrait:FeedData(extraInfo.Rank[1].Player.PortraitInfo)
            self.textPlayerName_1.text = extraInfo.Rank[1].Player.PlayerName
            self.textAllianceName_1.text = extraInfo.Rank[1].Alliance.AllianceName
        end
        if extraInfo.Rank[2] then
            self.luagoPortrait_2:FeedData(extraInfo.Rank[2].Player.PortraitInfo)
            self.textPlayerName_2.text = extraInfo.Rank[2].Player.PlayerName
            self.textAllianceName_2.text = extraInfo.Rank[2].Alliance.AllianceName
        end
        if extraInfo.Rank[3] then
            self.luagoPortrait_3:FeedData(extraInfo.Rank[3].Player.PortraitInfo)
            self.textPlayerName_3.text = extraInfo.Rank[3].Player.PlayerName
            self.textAllianceName_3.text = extraInfo.Rank[3].Alliance.AllianceName
        end
    elseif self.type == WorldStageNewsPageContentType.WorldTrendTop3 then
        if not extraInfo.Rank then
            return
        end
        if extraInfo.Rank[1] then
            self.luagoPortrait:FeedData(extraInfo.Rank[1].Player.PortraitInfo)
            self.textPlayerName_1.text = extraInfo.Rank[1].Player.PlayerName
            self.textAllianceName_1.text = extraInfo.Rank[1].Alliance.AllianceName
        end
        if extraInfo.Rank[2] then
            self.luagoPortrait_2:FeedData(extraInfo.Rank[2].Player.PortraitInfo)
            self.textPlayerName_2.text = extraInfo.Rank[2].Player.PlayerName
            self.textAllianceName_2.text = extraInfo.Rank[2].Alliance.AllianceName
        end
        if extraInfo.Rank[3] then
            self.luagoPortrait_3:FeedData(extraInfo.Rank[3].Player.PortraitInfo)
            self.textPlayerName_3.text = extraInfo.Rank[3].Player.PlayerName
            self.textAllianceName_3.text = extraInfo.Rank[3].Alliance.AllianceName
        end
    elseif self.type == WorldStageNewsPageContentType.FinishAllianceEvent then
        if extraInfo.Flag then
            self.luagoMyAllianceLogo:FeedData(extraInfo.Flag)
        end
        local eventConfig = ConfigRefer.WorldExpeditionTemplate:Find(extraInfo.ConfigId)
        if not eventConfig then
            return
        end
        g_Game.SpriteManager:LoadSprite(eventConfig:WorldTaskIcon(), self.imgEvent)
    end
end

return EarthRevivalNewsPageComponent