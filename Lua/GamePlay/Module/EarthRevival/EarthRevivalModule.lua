local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EarthRevivalModule_Task = require('EarthRevivalModule_Task')
local EarthRevivalDefine = require('EarthRevivalDefine')
local WorldStageNewsType = require('WorldStageNewsType')
local ServiceDynamicDescHelper = require('ServiceDynamicDescHelper')
local CommonDailyGiftState = require('CommonDailyGiftState')
local NotificationType = require('NotificationType')
local AttrComputeType = require('AttrComputeType')
local AttrValueType = require('AttrValueType')
local NewFunctionUnlockIdDefine = require('NewFunctionUnlockIdDefine')
local WorldStageNewsContentType = require('WorldStageNewsContentType')
local UIMediatorNames = require('UIMediatorNames')
local ShopType = require('ShopType')
local ActivityRewardType = require('ActivityRewardType')

---@class EarthRevivalModule : BaseModule
local EarthRevivalModule = class('EarthRevivalModule', BaseModule)

function EarthRevivalModule:ctor()
    ---@type EarthRevivalModule_Task
    self.taskModule = EarthRevivalModule_Task.new(self)
end

function EarthRevivalModule:OnRegister()
    self.taskModule:OnRegister()
    self:InitRedDot()
end

function EarthRevivalModule:OnRemove()
    self.taskModule:OnRemove()
end

---@param data EarthRevivalUIParameter
function EarthRevivalModule:OpenEarthRevivalMediator(data)
    if not ModuleRefer.KingdomModule:IsServerTimeExist() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("worldstage_systementry_unlock"))
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.EarthRevivalMediator, data)
end

--region CommonFunc
function EarthRevivalModule:GetOpenTabIndex()

    if not self:NewsDailyRewardClaimed() then
        return EarthRevivalDefine.EarthRevivalTabType.News
    end
    if self.taskModule:IsAnyTaskCanClaim() then
        return EarthRevivalDefine.EarthRevivalTabType.Task
    end
    return EarthRevivalDefine.EarthRevivalTabType.News
end

---@return wds.Kingdom
function EarthRevivalModule:GetKingdomEnitty()
    return ModuleRefer.KingdomModule:GetKingdomEntity()
end

function EarthRevivalModule:RefreshRedDot()
    local newsRedDot = self:RefreshNewsRedDot()

    local hasReward = ModuleRefer.WorldTrendModule:IsHasReward()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.timelineRedDot, hasReward and 1 or 0)
    -- ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.btnRedDot, newsRedDot and 1 or 0)
end

function EarthRevivalModule:InitRedDot()
    self:InitNewsRedDot()
    self.btnRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalBtnNode", NotificationType.EARTHREVIVAL_BTN)
    ModuleRefer.NotificationModule:AddToParent(self.tabNewsRedDot, self.btnRedDot)
    ModuleRefer.NotificationModule:AddToParent(self.groupNewsRedDot, self.btnRedDot)

    self.timelineRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalTimelineNode", NotificationType.EARTHREVIVAL_TAB_TIMELINE)
    ModuleRefer.NotificationModule:AddToParent(self.timelineRedDot, self.btnRedDot)
end

function EarthRevivalModule:CheckIsUnlock()
    local sysIndex = NewFunctionUnlockIdDefine.EarthRevival
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
end

function EarthRevivalModule:GetWorldTrendFurnitureId()
    return EarthRevivalDefine.WorldTrendFurnitureId
end

function EarthRevivalModule:GetCurOpenEarthRevivalShopId()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local storeInfos = player.PlayerWrapper.Store.Stores or {}
    for id, store in pairs(storeInfos) do
        local storeCfg = ConfigRefer.Shop:Find(id)
        if storeCfg:Type() == ShopType.WorldStage then
            if store.Open then
                return id
            end
        end
    end
    return 0
end


--endregion

--region News
---@return EarthRevivalNewsParam
function EarthRevivalModule:GetNewsData()
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return nil
    end
    local newsData = kingdom.WorldStage.WorldStageNews
    if not newsData then
        return nil
    end
    local news = newsData.News
    local param = {}
    param.pageNewsList = {}
    param.latestNewsList = {}
    local pageCount = 0
    for k, v in pairs(news) do
        local newsConfig = ConfigRefer.WorldStageNews:Find(v.ConfigId)
        if not newsConfig then
            goto continue
        end
        if newsConfig:Type() == WorldStageNewsType.WSTFrontPage then
            pageCount = pageCount + 1
            local content = ServiceDynamicDescHelper.ParseWithI18N(newsConfig:Content(), newsConfig:ContentDescLength(), newsConfig,
            newsConfig.ContentDesc, v.StringParams, v.IntParams, {}, v.ConfigParams)
            table.insert(param.pageNewsList, {
                newsId = v.Id,
                newsConfigId = v.ConfigId,
                newsContent = content,
                newsIcon = newsConfig:Picture(),
                extraInfo = v.ExtraInfo,
            })
        elseif newsConfig:Type() == WorldStageNewsType.WSTSecondPage then
            local content = ServiceDynamicDescHelper.ParseWithI18N(newsConfig:Content(), newsConfig:ContentDescLength(), newsConfig,
            newsConfig.ContentDesc, v.StringParams, v.IntParams, {}, v.ConfigParams)
            table.insert(param.latestNewsList, {
                newsId = v.Id,
                newsConfigId = v.ConfigId,
                newsContent = content,
                newsIcon = newsConfig:Picture(),
                likeNum = v.Likes,
                isLiked = self:GetNewsLiked(v.Id),
                extraInfo = v.ExtraInfo,
            })
        end
        ::continue::
    end
    param.pageCount = pageCount
    self.newsData = param
    return param
end

---@return WorldStageNewsPageContentType, WorldStageNewsContentType
function EarthRevivalModule:GetNewsSubType(newsID)
    local configInfo = ConfigRefer.WorldStageNews:Find(newsID)
    if not configInfo then
        return -1, -1
    end
    if configInfo:Type() == WorldStageNewsType.WSTFrontPage then
        return configInfo:PageContentType(), configInfo:ContentType()
    end
    return -1, configInfo:ContentType()
end

---@return WorldStageSpineConfigCell
function EarthRevivalModule:GetNewsSpineConfig(newsList)
    ---@type wds.Kingdom
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return nil
    end
    if #newsList <= 0 then
        return nil
    end
    local cacheList = {}
    local tempList = {}
    local isHasTriggerNews = false
    for k, v in ConfigRefer.WorldStageSpine:ipairs() do
        table.insert(cacheList, v)
    end
    local curStageID = kingdom.WorldStage.CurStage.Stage
    for i = 1, #cacheList do
        if cacheList[i]:Stage() ~= 0 and cacheList[i]:Stage() ~= curStageID then
            goto continue
        end
        if cacheList[i]:TriggerNewsLength() > 0 then
            for m = 1, cacheList[i]:TriggerNewsLength() do
                for n = 1, #newsList do
                    if cacheList[i]:TriggerNews(m) == newsList[n] then
                        isHasTriggerNews = true
                    end
                end
            end
            if not isHasTriggerNews then
                goto continue
            end
        end

        table.insert(tempList, cacheList[i])
        ::continue::
    end
    if #tempList == 0 then
        return nil
    end
    local randomID = math.random(1, #tempList)
    return tempList[randomID]
end

function EarthRevivalModule:GetRandomWeatherIndex()
    ---@type wds.Kingdom
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return 1
    end
    local length = #EarthRevivalDefine.EarthRevivalNews_WeatherIcon
    local news = kingdom.WorldStage.WorldStageNews
    return news.NextRefreshTime.Seconds % length + 1
end

function EarthRevivalModule:GetSecondNewsList()
    if not self.newsData then
        self.newsData = self:GetNewsData()
    end
    local list = {}
    for i = 1, #self.newsData.latestNewsList do
        table.insert(list, self.newsData.latestNewsList[i].newsContent)
    end
    return list
end

function EarthRevivalModule:GetFunnyNewsList()
    local curStage = ModuleRefer.WorldTrendModule:GetCurStage()
    local list = {}
    for k, v in ConfigRefer.WorldStageNews:ipairs() do
        if v:Type() == WorldStageNewsType.WSTFunny and v:Stage() == curStage.Stage then
            table.insert(list, v:Content())
        end
    end
    return list
end

function EarthRevivalModule:GetRunNewsList()
    local secondList = self:GetSecondNewsList()
    local funnyList = self:GetFunnyNewsList()
    local list = {}
    for i = 1, #secondList do
        table.insert(list, secondList[i])
    end
    for i = 1, #funnyList do
        table.insert(list, funnyList[i])
    end
    return list
end

---@return wds.WorldStageNews
function EarthRevivalModule:GetCurNewsInfo()
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return nil
    end
    return kingdom.WorldStage.WorldStageNews
end

function EarthRevivalModule:GetNewsLiked(id)
    --玩家数据是旧的则默认没点过赞
    if self:CheckPLayerNewsInfoIsOld() then
        return false
    end
    local playerNewsInfo = self:GetPlayerNewsInfo()
    if not playerNewsInfo then
        return false
    end
    local likedNews = playerNewsInfo.LikedNews
    if not likedNews then
        return false
    end
    for k, v in pairs(likedNews) do
        if k == id then
            return true
        end
    end
    return false
end

---@return wds.PlayerWorldStageNewsInfo
function EarthRevivalModule:GetPlayerNewsInfo()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper3.WorldStageInfo.PlayerNewsInfo or {}
end

function EarthRevivalModule:CheckPLayerNewsInfoIsOld()
    local playerNewsInfo = self:GetPlayerNewsInfo()
    if not playerNewsInfo then
        return true
    end
    local worldStageNews = self:GetCurNewsInfo()
    if not worldStageNews then
        return true
    end
    return playerNewsInfo.NewsRefreshTime.Seconds ~= worldStageNews.NextRefreshTime.Seconds
end

---@return CommonDailyGiftState
function EarthRevivalModule:GetDailyRewardState()
     --玩家数据是旧的则默认没领过奖
    if self:CheckPLayerNewsInfoIsOld() then
        return CommonDailyGiftState.CanCliam
    end
    local playerNewsInfo = self:GetPlayerNewsInfo()
    if not playerNewsInfo then
        return CommonDailyGiftState.CanCliam
    end
    return playerNewsInfo.ReceivedNewsReward and CommonDailyGiftState.HasCliamed or CommonDailyGiftState.CanCliam
end

function EarthRevivalModule:NewsDailyRewardClaimed()
    return self:GetDailyRewardState() == CommonDailyGiftState.HasCliamed
end

function EarthRevivalModule:RefreshNewsRedDot()
    local claimed = self:NewsDailyRewardClaimed()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.groupNewsRedDot, claimed and 0 or 1)
    local hasNotify, _ = ModuleRefer.ActivityCenterModule:HasNotify()
    local isShow = not claimed or hasNotify
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.tabNewsRedDot, isShow and 1 or 0)
    return isShow
end

function EarthRevivalModule:InitNewsRedDot()
    if not self.groupNewsRedDot then
        self.groupNewsRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalGroupNewsNode", NotificationType.EARTHREVIVAL_GROUP_NEWS)
    end
    if not self.tabNewsRedDot then
        self.tabNewsRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalTabNewsNode", NotificationType.EARTHREVIVAL_TAB_NEWS)
    end
    -- ModuleRefer.NotificationModule:AddToParent(self.groupNewsRedDot, self.tabNewsRedDot)
end

function EarthRevivalModule:AttachToGroupNewsRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self.groupNewsRedDot, go)
end

function EarthRevivalModule:AttachToTabNewsRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self.tabNewsRedDot, go)
end

--endregion

--region Map

function EarthRevivalModule:RefreshMapRedDot()
    local claimed = self:NewsDailyRewardClaimed()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.groupMapRedDot, claimed and 0 or 1)
    return false
end

function EarthRevivalModule:InitMapRedDot()
    if not self.groupMapRedDot then
        self.groupMapRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalGroupMapNode", NotificationType.EARTHREVIVAL_GROUP_MAP)
    end
    if not self.tabMapRedDot then
        self.tabMapRedDot = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("EarthRevivalTabMapNode", NotificationType.EARTHREVIVAL_TAB_MAP)
    end
    ModuleRefer.NotificationModule:AddToParent(self.groupMapRedDot, self.tabMapRedDot)
end

function EarthRevivalModule:AttachToGroupMapRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self.groupMapRedDot, go)
end

function EarthRevivalModule:AttachToTabMapRedDot(go)
    ModuleRefer.NotificationModule:AttachToGameObject(self.tabMapRedDot, go)
end

function EarthRevivalModule:SetGroupMapRedDot(claimed)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.groupNewsRedDot, claimed and 0 or 1)
end

---@return WorldStageSandboxConfigCell
function EarthRevivalModule:GetSandBoxConfigByRingIndex(ringIndex)
    for k, v in ConfigRefer.WorldStageSandbox:ipairs() do
        if v:RingSort() == ringIndex then
            return v
        end
    end
    return nil
end

function EarthRevivalModule:CheckSandBoxMapUnlock()
    local curStageInfo = ModuleRefer.WorldTrendModule:GetCurStage()
    local curStage = curStageInfo.Stage
    local curStageConfig = ConfigRefer.WorldStage:Find(curStage)
    if not curStageConfig then
        return false
    end
    return curStageConfig:Stage() >= ConfigRefer.ConstMain:EarthRevivalMapUnlockStage()
end

function EarthRevivalModule:GetMapRingID(districtId)
    local baseID = require("KingdomMapUtils").GetStaticMapData():GetBaseId()
    districtId = districtId - baseID
    local count = ConfigRefer.MapDistrict.length
    for i = 1, count do
        local configInfo = ConfigRefer.MapDistrict:Find(i)
        if not configInfo then
            goto continue
        end
        for j = 1, configInfo:DistrictListLength() do
            if districtId == configInfo:DistrictList(j) then
                return configInfo:Id()
            end
        end
        ::continue::
    end
    return 0
end

function EarthRevivalModule:GetTerritoryTotalCount()
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return 0
    end
    return kingdom.WorldStage.TotalTerritoryNum
end

--占领领地数量
function EarthRevivalModule:GetTerritoryOccupyCount()
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return 0
    end
    return table.nums(kingdom.WorldStage.TerritoryOccupyCache)
end

function EarthRevivalModule:GetTerritoryOccupyMap()
    local kingdom = self:GetKingdomEnitty()
    if not kingdom then
        return {}
    end
    return kingdom.WorldStage.TerritoryOccupyCache
end

function EarthRevivalModule:GetAttrStr(attrGroupID)
    local attrGroupConfig = ConfigRefer.AttrGroup:Find(attrGroupID)
    if not attrGroupConfig then
        return string.Empty
    end

    local attrTypeAndValue = nil
    local attrElement = nil
    local str = string.Empty
    for i = 1, attrGroupConfig:AttrListLength() do
        attrTypeAndValue = attrGroupConfig:AttrList(i)
        attrElement = ConfigRefer.AttrElement:Find(attrTypeAndValue:TypeId())
        if attrElement then
            str = string.format("%s%s+%s", str, I18N.Get(attrElement:Name()), self:GetAttrValueStr(attrElement, attrTypeAndValue:Value()))
        end
    end
    return str
end

---@param attrElement AttrElementConfig
---@return string
function EarthRevivalModule:GetAttrValueStr(attrElement, value)
    if not attrElement then
        return string.Empty
    end
    local baseValue = 0
    local multiValue = 0
    local pointValue = 0
    if (attrElement:ComputeType() == AttrComputeType.Base) then
        baseValue = value
    elseif (attrElement:ComputeType() == AttrComputeType.Multi) then
        if attrElement:ValueType() == AttrValueType.OneTenThousand then
            multiValue = value / 100
        elseif attrElement:ValueType() == AttrValueType.Percentages then
            multiValue = value / 100
        elseif attrElement:ValueType() == AttrValueType.Fix then
            multiValue = value
        end
    elseif (attrElement:ComputeType() == AttrComputeType.Point) then
        pointValue = value
    end
    if baseValue > 0 then
        return string.format("+%d", baseValue)
    elseif multiValue > 0 then
        return string.format("+%0.1f%%", multiValue)
    elseif pointValue > 0 then
        return string.format("+%d", pointValue)
    end

end

---todo: 预留接口
---@param landformCfgId number
---@return number
function EarthRevivalModule:GetStageForUnlockingLandform(landformCfgId)
    local landformCfg = ConfigRefer.Land:Find(landformCfgId)
    local systemEntryId = landformCfg:SystemEntryId()
    ---@type number, WorldStageConfigCell
    for _, stageCfg in ConfigRefer.WorldStage:ipairs() do
        for i = 1, stageCfg:UnlockSystemsLength() do
            if stageCfg:UnlockSystems(i) == systemEntryId then
                return stageCfg:Id()
            end
        end
    end
    return 0
end

--endregion

--region Task

--endregion

function EarthRevivalModule:GetCurOpeningLeaderboardId()
    local firePlanARId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.FirePlan)
    local firePlanARCfg = ConfigRefer.ActivityRewardTable:Find(firePlanARId)
    local firePlanCfg = ConfigRefer.FirePlan:Find(firePlanARCfg:RefConfig())
    local playerLeaderboardId = firePlanCfg:PlayerLeaderboardReward()
    local allianceLeaderboardId = firePlanCfg:AllianceLeaderboardReward()
    return playerLeaderboardId, allianceLeaderboardId
end


return EarthRevivalModule