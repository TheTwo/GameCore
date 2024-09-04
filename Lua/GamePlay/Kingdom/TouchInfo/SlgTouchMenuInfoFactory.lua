local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local DBEntityType = require('DBEntityType')
local TimeFormatter = require("TimeFormatter")
local MonsterClassType = require('MonsterClassType')

local TouchMenuHelper = require('TouchMenuHelper')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')

local SlgTouchMenuInfoMarkProvider = require("SlgTouchMenuInfoMarkProvider")
local SlgTouchMenuInfoProviderMonster = require("SlgTouchMenuInfoProviderMonster")
local SlgTouchMenuInfoProviderBehemoth = require("SlgTouchMenuInfoProviderBehemoth")
local TouchMenuCellPairDynamicDatum =require('TouchMenuCellPairDynamicDatum')
local TimerUtility = require("TimerUtility")
local TouchMenuCellLandformDatum = require("TouchMenuCellLandformDatum")
local I18N = require("I18N")

---@class SlgTouchMenuInfoFactory
local SlgTouchMenuInfoFactory = class("SlgTouchMenuInfoFactory")

---@param ctrl TroopCtrl
function SlgTouchMenuInfoFactory.CreateMobTouchMenuParam(ctrl,radius)
    local mobData = ctrl._data   
    local canAttack = true -- ModuleRefer.AllianceModule:IsInAlliance()
     
    local infoProvider = SlgTouchMenuInfoProviderMonster.new()
    infoProvider:Setup(mobData)
   
    local markProvider = SlgTouchMenuInfoMarkProvider.new()
    markProvider:Setup(mobData)

    local mainWindow = infoProvider:GetMainWindowDatum()
    mainWindow:SetMarkProvider(markProvider)
      
    local components = {}

    --世界事件特殊怪限时文本
    local worldEventEntity = false
    local uniqueId = ctrl._data.LevelEntityInfo.LevelEntityId
    if uniqueId then
        worldEventEntity = g_Game.DatabaseManager:GetEntity(uniqueId, DBEntityType.Expedition)
    end

    -- 怪出生圈层信息
    local kMonsterCfgCell = ConfigRefer.KmonsterData:Find(mobData.MobInfo.MobID)
    if kMonsterCfgCell:LandId() > 0 then
        local landformInfoPage = TouchMenuCellLandformDatum.new()
        landformInfoPage:SetTitle(I18N.Get("bw_info_land_mob"))
        local landCfgIds = {}
        table.insert(landCfgIds, kMonsterCfgCell:LandId())
        landformInfoPage:SetLandformIds(landCfgIds)
        table.insert(components, landformInfoPage)
    end

    -- 怪物列表        
    local monsterInfoDatum = infoProvider:GetMonsterDatum()
    if monsterInfoDatum then
        if worldEventEntity then
            --世界事件 怪物两个以上才显示列表
            if #monsterInfoDatum.monstersData > 1 then
                table.insert(components, monsterInfoDatum)
            end
        end
    end

    if infoProvider.mobConfig:MonsterClass() == MonsterClassType.Normal 
            and ModuleRefer.WorldSearchModule:IsFirstKillMonster(infoProvider.level) 
            and not infoProvider.mobConfig:NoFirstKillRewardAndLevelUp() then
        -- 首杀奖励列表
        local firstKillRewardInfoDatum = infoProvider:GetFirstKillRewardDatum(infoProvider.level)
        if firstKillRewardInfoDatum then
            table.insert(components, firstKillRewardInfoDatum)
        end
    end

    -- 可能奖励列表
    local additionalRewardInfoDatum = infoProvider:GetAdditionalRewardDatum()
    if additionalRewardInfoDatum then
        table.insert(components, additionalRewardInfoDatum)
    end

    -- 必定奖励列表
    local rewardInfoDatum = infoProvider:GetRewardDatum()
    if rewardInfoDatum then
        table.insert(components, rewardInfoDatum)
    end

    --世界事件特殊怪限时文本
    if worldEventEntity then
        local dynamic = function()
                            local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
                            local endT = worldEventEntity.ExpeditionInfo.ActivateEndTime and worldEventEntity.ExpeditionInfo.ActivateEndTime or 0
                            local timeStr = TimeFormatter.SimpleFormatTimeWithDay(endT-curTime)
                            return I18N.GetWithParams("alliance_activity_pet_19",timeStr)
                        end
        local textComp = TouchMenuCellPairDynamicDatum.new(nil, dynamic,nil,nil,nil,nil,true)
        table.insert(components,textComp)
    end

    local attackLv = SlgTouchMenuHelper.GetAttackLv(infoProvider.mobConfig)
    local canAttackMonster, _ = SlgTouchMenuHelper.CheckMonsterCanAttack(infoProvider.mobConfig, infoProvider.level)
    canAttack = canAttack and canAttackMonster
    
    --世界事件特殊怪只有本人能发起集结
    if worldEventEntity and not ModuleRefer.WorldEventModule:IsAllianceBoss(worldEventEntity) then
        canAttack = worldEventEntity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    end

    local troopTrans = ctrl:GetTransform()
    local buttonTip = nil
    local buttons = nil
    if canAttack then
        buttonTip = infoProvider:GetAttackableButtonTip()
        buttons = infoProvider:GetAttackableButtonDatum()
    elseif worldEventEntity or(attackLv < infoProvider.level) then
        infoProvider:SetupSearch(attackLv)
        buttonTip = worldEventEntity and infoProvider:GetWorldEventMonsterButtonTip() or infoProvider:GetSearchButtonTip()
        buttons = worldEventEntity and infoProvider:GetWorldEventCannotAttackButtonDatum() or infoProvider:GetSearchButtonDatum()
    else
        components = nil
    end

    return TouchMenuHelper.GetSinglePageUIDatum(
        mainWindow,
        components,
        TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons),
        buttonTip
    ):SetFollowTransform(troopTrans,radius)

end


function SlgTouchMenuInfoFactory.CreateBehemothTouchMenuParam(ctrl,radius)
    local mobData = ctrl._data   
    -- local canAttack = ModuleRefer.AllianceModule:IsInAlliance()
     
    local infoProvider = SlgTouchMenuInfoProviderMonster.new()
    infoProvider:Setup(mobData)
   
    local markProvider = SlgTouchMenuInfoMarkProvider.new()
    markProvider:Setup(mobData)

    local mainWindow = infoProvider:GetMainWindowDatum()
    mainWindow:SetMarkProvider(markProvider)

    local behProvider = SlgTouchMenuInfoProviderBehemoth.new(mobData)
    behProvider:AppendOperationOnBasicInfo(mainWindow)

    local components = {}

    local cageId = mobData.MobInfo.BehemothCageId
    local cageEntity = g_Game.DatabaseManager:GetEntity(cageId,DBEntityType.BehemothCage)
    local needScout = ModuleRefer.RadarModule:GetScout(cageEntity)
    --技能列表
    local skillDatum = behProvider:GetSkillDatum()
    if skillDatum and not needScout then
        table.insert(components, skillDatum)
    end
    --收益信息
    local rewardPairListDatum = behProvider:GetRewardDatum()
    if rewardPairListDatum and not needScout then
        table.insert(components, rewardPairListDatum)
    end
    --占领信息
    local rewardInfoDatum = behProvider:GetOccupiedDatum()
    if rewardInfoDatum and not needScout then
        table.insert(components, rewardInfoDatum)
    end

    
    local buttonTip
    local troopTrans = ctrl:GetTransform()

    if not needScout then
        buttonTip = behProvider:GetButtonTip()
    end

    local buttons = behProvider:GetButtonDatum()


    return TouchMenuHelper.GetSinglePageUIDatum(
        mainWindow,
        components,
        TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons),
        buttonTip
    ):SetFollowTransform(troopTrans,radius)
end

return SlgTouchMenuInfoFactory