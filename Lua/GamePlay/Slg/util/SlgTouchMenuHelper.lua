
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require('ArtResourceUtils')
local MonsterClassType = require('MonsterClassType')
local UIHelper = require('UIHelper')
local ItemTableMergeHelper = require('ItemTableMergeHelper')
 ---@class SlgTouchMenuHelper
local SlgTouchMenuHelper = class('SlgTouchMenuHelper')


---@param configId number
---@return string,string,number,{heroIcon:number}[],string,string @name,icon,level,heroesMiniHead,halfBodyPaint,bodyPaint
function SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfigId(configId)
    local mobConfig = ConfigRefer.KmonsterData:Find(configId)
    return SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(mobConfig)
end

---@param mobConfig KmonsterDataConfigCell
---@return string,string,number,{heroIcon:number}[],string,string @name,icon,level,heroesMiniHead,halfBodyPaint,bodyPaint
function SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(mobConfig)
    local name = string.Empty
    local icon = string.Empty
    local halfBodyPaint = string.Empty
    local bodyPaint = string.Empty
    local level = 0
    ---@type {heroIcon:number,halfBodyPaint:number,bodyPaint:number}[]
    local heroesMiniHead = {}
    if mobConfig then
        name = I18N.Get(mobConfig:Name())
        level = mobConfig:Level()
        local heroSet = {}
        for i = 1, mobConfig:HeroLength() do
            local heroData = mobConfig:Hero(i)
            if not heroData or heroSet[heroData:HeroConf()] then goto GetMobNameImageLevelHeadIconsFromConfigId_CONTINUE end
            local heroNpcInfo = ConfigRefer.HeroNpc:Find(heroData:HeroConf())
            if not heroNpcInfo then goto GetMobNameImageLevelHeadIconsFromConfigId_CONTINUE end
            local heroCfg = ConfigRefer.Heroes:Find(heroNpcInfo:HeroConfigId())
            if not heroCfg then goto GetMobNameImageLevelHeadIconsFromConfigId_CONTINUE end
            local heroClientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
            if not heroClientRes then goto GetMobNameImageLevelHeadIconsFromConfigId_CONTINUE end
            table.insert(heroesMiniHead, {
                heroIcon = heroClientRes:HeadMini(),
                halfBodyPaint = heroClientRes:HalfBodyPaint(),
                bodyPaint = heroClientRes:BodyPaint(),
            })
            heroSet[heroData:HeroConf()] = true
            ::GetMobNameImageLevelHeadIconsFromConfigId_CONTINUE::
        end
        if #heroesMiniHead > 0 then
            icon = ArtResourceUtils.GetUIItem(heroesMiniHead[1].heroIcon)
            halfBodyPaint = ArtResourceUtils.GetUIItem(heroesMiniHead[1].halfBodyPaint)
            bodyPaint = ArtResourceUtils.GetUIItem(heroesMiniHead[1].bodyPaint)
        end
    end
    return name,UIHelper.IconOrMissing(icon),level,heroesMiniHead,UIHelper.IconOrMissing(halfBodyPaint),UIHelper.IconOrMissing(bodyPaint)
end

---@param mapMob wds.MapMob
---@return string,string,number,{heroIcon:number}[],string @name,icon,level,heroesMiniHead,halfBodyPaint
function SlgTouchMenuHelper.GetMobNameImageLevelHeadIcons(mapMob)
    local mobConfig = ConfigRefer.KmonsterData:Find(mapMob.MobInfo.MobID)
    local name = string.Empty
    local icon = string.Empty
    local halfBodyPaint = string.Empty
    local level = 0
    ---@type {heroIcon:number,halfBodyPaint:number}[]
    local heroesMiniHead = {}
    if mobConfig then
        name = I18N.Get(mobConfig:Name())
        level = mapMob.MobInfo.Level
        local heroSet = {}
        for heroIndex, heroData in pairs(mapMob.Battle.Group.Heros) do
            if not heroData or heroSet[heroData.HeroID] then goto GetMobNameImageLevel_CONTINUE end
            local heroCfg = ConfigRefer.Heroes:Find(heroData.HeroID)
            if not heroCfg then goto GetMobNameImageLevel_CONTINUE end
            local heroClientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
            if not heroClientRes then goto GetMobNameImageLevel_CONTINUE end
            local tuple =
            {
                heroIcon = heroClientRes:HeadMini(),
                halfBodyPaint = heroClientRes:HalfBodyPaint(),
            }
            heroesMiniHead[heroIndex+1] = tuple
            heroSet[heroData.HeroID] = true
            ::GetMobNameImageLevel_CONTINUE::
        end
        if #heroesMiniHead > 0 then
            icon = ArtResourceUtils.GetUIItem(heroesMiniHead[1].heroIcon)
            halfBodyPaint = ArtResourceUtils.GetUIItem(heroesMiniHead[1].halfBodyPaint)
        end
    end
    return name,UIHelper.IconOrMissing(icon),level,heroesMiniHead,UIHelper.IconOrMissing(halfBodyPaint)
end

---@param monsterConfig KmonsterDataConfigCell
function SlgTouchMenuHelper.CheckMonsterCanAttack(monsterConfig, level)
    if monsterConfig:CanForceFight() then
        return true, string.Empty
    end

    local attackLv = SlgTouchMenuHelper.GetAttackLv(monsterConfig)
    --除了普通与精英，别的类型不判断搜索等级
    if attackLv > 0 and attackLv < level then
        local hintText = SlgTouchMenuHelper.GetHintText(monsterConfig)
        return false, hintText
    end
    return true, string.Empty
end

---@return number
function SlgTouchMenuHelper.GetAttackLv(mobConfig)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local attackLv = math.maxinteger
    if mobConfig:MonsterClass() == MonsterClassType.Normal then
        attackLv = player.PlayerWrapper2.SearchEntity.CanAtkNormalMobMaxLevel
    elseif mobConfig:MonsterClass() == MonsterClassType.Elite then
        attackLv = player.PlayerWrapper2.SearchEntity.CanAtkEliteMobMaxLevel
    elseif mobConfig:MonsterClass() == MonsterClassType.TeamElite then
        attackLv = player.PlayerWrapper2.SearchEntity.CanAtkEliteMobMaxLevel
    end
    return attackLv
end

---@param monsterCfg KmonsterDataConfigCell
function SlgTouchMenuHelper.GetHintText(monsterCfg)
    local attackLv = SlgTouchMenuHelper.GetAttackLv(monsterCfg)
    local hintText
    if monsterCfg:MonsterClass() == MonsterClassType.Normal then
        hintText = I18N.GetWithParams("searchentity_toast_lowlv_1", attackLv)
    elseif monsterCfg:MonsterClass() == MonsterClassType.Elite then
        hintText = I18N.GetWithParams("searchentity_toast_lowlv_2", attackLv)
    elseif monsterCfg:MonsterClass() == MonsterClassType.TeamElite then
        hintText = I18N.GetWithParams("searchentity_toast_lowlv_2", attackLv)
    end
    return hintText
end

---@param mobConfig KmonsterDataConfigCell
---@param mergeSameItem boolean
---@param splitRankReward boolean
---@return ItemIconData[],ItemIconData[],ItemIconData[] @rankRewards,dropRewards,observeRewards
function SlgTouchMenuHelper.GetMobPreviewRewards(mobConfig, mergeSameItem, splitRankReward)
    ---@type ItemIconData[]
    local rankRewards = {}
    ---@type ItemIconData[]
    local dropRewards = {}
    ---@type ItemIconData[]
    local observeRewards = {}
    local rankRewardCfg = ConfigRefer.MapInstanceReward:Find(mobConfig:InstanceRankReward())
    for i = 1, rankRewardCfg:RewardsLength() do
        local rewardRankInfo = rankRewardCfg:Rewards(i)
        local groupItem = ConfigRefer.ItemGroup:Find(rewardRankInfo:UnitRewardConf2())
        local singleRankReward = {}
        for j = 1, groupItem:ItemGroupInfoListLength() do
            local itemId = groupItem:ItemGroupInfoList(j):Items()
            local rewardItem = ConfigRefer.Item:Find(itemId)
            ---@type ItemIconData
            local rewardData = {}
            rewardData.configCell = rewardItem
            rewardData.showTips = true
            rewardData.count = groupItem:ItemGroupInfoList(j):Nums()
            if splitRankReward then
                table.insert(singleRankReward, rewardData)
            else
                table.insert(rankRewards, rewardData)
            end
        end
        if splitRankReward then
            if mergeSameItem then
                singleRankReward = ItemTableMergeHelper.MergeItemDataByItemCfgId(singleRankReward)
            end
            rankRewards[rankRewardCfg:Rewards(i):UnitRewardParam1()] = singleRankReward
        end
    end
    local defeatReward = mobConfig:DropShow()
    local itemGroup = ConfigRefer.ItemGroup:Find(defeatReward)
    if itemGroup then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemInfo:Items())
            iconData.count = itemInfo:Nums()
            iconData.useNoneMask = false
            table.insert(dropRewards, iconData)
        end
    end
    --- ID1168218【【巨兽巢穴】隐藏观战奖励，挑战巨兽只有击败奖励、排名奖励、升级奖励和这个版本不做需要隐藏的观战奖励】
    local obRewardCfg = nil--ConfigRefer.RandomBox:Find(mobConfig:InstanceWatchBox())
    if obRewardCfg then
        for i = 1, obRewardCfg:GroupInfoLength() do
            local itemDatas = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(obRewardCfg:GroupInfo(i):Groups())
            for _, itemData in ipairs(itemDatas) do
                table.insert(observeRewards, itemData)
            end
        end
    end
    if mergeSameItem then
        if not splitRankReward then
            rankRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(rankRewards)
        end
        dropRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(dropRewards)
        observeRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(observeRewards)
    end
    return rankRewards, dropRewards, observeRewards
end

return SlgTouchMenuHelper
