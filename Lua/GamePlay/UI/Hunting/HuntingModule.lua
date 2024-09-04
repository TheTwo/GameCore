local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local I18N = require("I18N")
local HuntingSectionType = require("HuntingSectionType")
local KingdomMapUtils = require("KingdomMapUtils")
local GuideFingerUtil = require("GuideFingerUtil")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local TimerUtility = require("TimerUtility")
local NotificationType = require("NotificationType")
---@class HuntingModule:BaseModule
local HuntingModule = class('HuntingModule', BaseModule)

---@class HuntingChapterInfo
---@field chapterId number
---@field sectionIds table<number, number>
---@field isUnlocked boolean

---@class HuntingSectionInfo
---@field sectionId number
---@field sectionName string
---@field sectionType number
---@field headPic string
---@field monsterPic string
---@field monsterName string
---@field monsterType number
---@field monsterDesc string
---@field rewards table<number, ItemIconData>
---@field power number
---@field isFinished boolean
---@field cityElementDataId number
---@field mineId number
---@field mapInstanceId number

function HuntingModule:OnRegister()
    ---@type table<number, HuntingChapterInfo>
    self.huntingChapterInfos = {}
    self:UpdateHuntingChapterInfos()
    self:SetupRedDot()
    self:UpdateRedDot()
    self.isRedDotDirty = false
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerHunting.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerHuntingDataChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_BOTTOM_RIGHT_SUB_BUTTON_CLICK, Delegate.GetOrCreate(self, self.OnHuntingButtonClick))
    --g_Game.EventManager:AddListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
end

function HuntingModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerHunting.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerHuntingDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_BOTTOM_RIGHT_SUB_BUTTON_CLICK, Delegate.GetOrCreate(self, self.OnHuntingButtonClick))
    --g_Game.EventManager:RemoveListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
end

function HuntingModule:OpenHuntingMediator(delay)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.everyThing, false)
    TimerUtility.DelayExecuteInFrame(function()
        g_Game.UIManager:Open(UIMediatorNames.HuntingMainMediator)
    end, delay or 1)
end

function HuntingModule:OnPlayerHuntingDataChanged()
    self:UpdateHuntingChapterInfos()
    self:UpdateRedDot()
end

function HuntingModule:OnHuntingButtonClick(param)
    if param == "HuntingMainMediator_hud" then
        self:OpenHuntingMediator()
    end
end

function HuntingModule:OnEnterCity(flag)
    if flag then
        local mediatorName = g_Game.StateMachine:ReadBlackboard("NEED_REOPEN_MEDIATOR_NAME", true)
        if mediatorName then
            local UIAsyncDataProvider = require("UIAsyncDataProvider")
            local provider = UIAsyncDataProvider.new()
            local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator |
                            UIAsyncDataProvider.CheckTypes.DoNotShowInSE
            local failStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
            provider:Init(mediatorName, nil, check, failStrategy)
            provider:SetOpenFunc(function()
                self:OpenHuntingMediator(20)
            end)
            g_Game.UIAsyncManager:AddAsyncMediator(provider)
        end
    end
end

function HuntingModule:OnEnterSeJumpScene(flag)
    if not flag then return false end
    local mediatorName = g_Game.StateMachine:ReadBlackboard("NEED_REOPEN_MEDIATOR_NAME", true)
    if mediatorName and mediatorName == UIMediatorNames.HuntingMainMediator then
        self:OpenHuntingMediator(0)
        return true
    end
    return false
end

function HuntingModule:SetupRedDot()
    self.hudNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("HUNTING_HUD", NotificationType.HUNTING_HUD)
    self.starRewardNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("HUNTING_STAR_REWARD", NotificationType.HUNTING_STAR_REWARD)
    self.dailyRewardNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("HUNTING_DAILY_REWARD", NotificationType.HUNTING_DAILY_REWARD)

    ModuleRefer.NotificationModule:AddToParent(self.starRewardNode, self.hudNode)
    ModuleRefer.NotificationModule:AddToParent(self.dailyRewardNode, self.hudNode)
end

function HuntingModule:SetRedDotDirty()
    self.isRedDotDirty = true
end

function HuntingModule:UpdateRedDot()
    for _, cfg in ConfigRefer.HuntingStarReward:ipairs() do
        local starRewardId = cfg:Id()
        local isClaimed = self:IsStarRewardClaimed(starRewardId)
        local starNum = cfg:StarNum()
        local isAvailable = self:GetCurStarNum() >= starNum
        local shouldShow = isAvailable and not isClaimed
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.starRewardNode, shouldShow and 1 or 0)
        if shouldShow then
            break
        end
    end

    local sysId = ConfigRefer.HuntingConst:DailyRewardSystemID()
    local isDailyRewardUnlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)
    local isDailyRewardCanClaim = not self:IsDailyRewardClaimed()
    local shouldShow = isDailyRewardUnlocked and isDailyRewardCanClaim
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.dailyRewardNode, shouldShow and 1 or 0)
end

function HuntingModule:UpdateHuntingChapterInfos()
    self.huntingChapterInfos = {}
    for _, chapterCfg in ConfigRefer.HuntingChapter:ipairs() do
        local chapterId = chapterCfg:Id()
        self.huntingChapterInfos[chapterId] = {
            chapterId = chapterId,
            sectionIds = {},
            isUnlocked = self:IsChapterUnlocked(chapterId)
        }
    end
    for _, sectionCfg in ConfigRefer.HuntingSection:ipairs() do
        local chapterId = sectionCfg:ChapterId()
        table.insert(self.huntingChapterInfos[chapterId].sectionIds, sectionCfg:Id())
    end
end

---@param chapterId number @ HuntingChapter configId
function HuntingModule:IsChapterUnlocked(chapterId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local chapterOpenStatus = player.PlayerWrapper3.PlayerHunting.ChapterOpen
    return chapterOpenStatus[chapterId]
end

---@param sectionId number
function HuntingModule:IsSectionFinished(secId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curSecId = player.PlayerWrapper3.PlayerHunting.SectionCfgId
    return secId <= curSecId
end

function HuntingModule:GetNextSectionId()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curSecId = player.PlayerWrapper3.PlayerHunting.SectionCfgId
    return curSecId + 1
end

function HuntingModule:GetLastSectionId()
    local lastSecId = ConfigRefer.HuntingSection.lastIid
    return lastSecId
end

function HuntingModule:GetNextImportantRewardSectionId()
    local curSecId = self:GetNextSectionId()
    local nextSecId = curSecId
    for _, cfg in ConfigRefer.HuntingSection:ipairs() do
        if cfg:Id() <= curSecId then
            goto continue
        end
        if cfg:ImportantRewardLength() > 0 then
            nextSecId = cfg:Id()
            break
        end
        ::continue::
    end
    return nextSecId
end

function HuntingModule:GetChapterInfos()
    return self.huntingChapterInfos
end

---@param sectionId number
---@return HuntingSectionInfo
function HuntingModule:GetSectionInfo(sectionId)
    ---@type HuntingSectionInfo
    local ret = {}
    ret.sectionId = sectionId
    ret.sectionName = ''
    ret.sectionType = 0
    ret.importantRewardId = {}
    ret.headPic = ''
    ret.monsterPic = ''
    ret.monsterName = ''
    ret.monsterType = 0
    ret.monsterDesc = ''
    ret.rewards = {}
    ret.power = 0
    ret.isFinished = false
    ret.mapInstanceId = 0
    local cfg = ConfigRefer.HuntingSection:Find(sectionId)
    local sectionName = I18N.Get(cfg:Name())
    local sectionType = cfg:Typo()
    local mapInstanceId = cfg:MapInstanceId()
    local mapCfg = ConfigRefer.MapInstance:Find(mapInstanceId)
    if not mapCfg then return ret end

    local monsterId = mapCfg:SeNpcConf(1)
    local monsterCfg = ConfigRefer.SeNpc:Find(monsterId)
    local monsterPic = mapCfg:FullPic()
    local headPic = monsterCfg:MonsterInfoIcon()
    local monsterName = monsterCfg:Name()
    local monsterType = monsterCfg:Category()
    local monsterDesc = monsterCfg:Des()

    ---@type table<number, ItemIconData>
    local rewards = {}
    local rewardCfg = ConfigRefer.MapInstanceReward:Find(mapCfg:Rewards())
    for i = 1, rewardCfg:RewardsLength() do
        for j = 1, rewardCfg:Rewards(i):UnitRewardConfLength() do
            ---@type ItemIconData
            local reward = {}
            local itemId = rewardCfg:Rewards(i):UnitRewardConf(j)
            local itemConfigCell = ConfigRefer.Item:Find(itemId)
            reward.configCell = itemConfigCell
            reward.showCount = false
            reward.showTips = true
            table.insert(rewards, reward)
        end
    end

    local power = mapCfg:Power()
    local isFinished = self:IsSectionFinished(sectionId)

    for i = 1, cfg:ImportantRewardLength() do
        table.insert(ret.importantRewardId, cfg:ImportantReward(i))
    end

    ret.sectionId = sectionId
    ret.sectionName = sectionName
    ret.sectionType = sectionType
    ret.headPic = headPic
    ret.monsterPic = monsterPic
    ret.monsterName = monsterName
    ret.monsterType = monsterType
    ret.monsterDesc = monsterDesc
    ret.rewards = rewards
    ret.power = power
    ret.isFinished = isFinished
    ret.mapInstanceId = mapInstanceId
    return ret
end

function HuntingModule:GetCurStarNum()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper3.PlayerHunting.AllStarNum
end

function HuntingModule:GetSeEnter(sectionId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local seEnterId = player.PlayerWrapper3.PlayerHunting.SeEnters[sectionId]
    local seEnter = player.PlayerWrapper3.PlayerSeEnter.SeEnters[seEnterId]
    return seEnter
end

function HuntingModule:IsStarRewardClaimed(starRewardId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local starRewardClaimed = player.PlayerWrapper3.PlayerHunting.StarRewards
    return starRewardClaimed[starRewardId]
end

function HuntingModule:IsDailyRewardClaimed()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local dailyRewardClaimed = player.PlayerWrapper3.PlayerHunting.IsRewardDaily
    return dailyRewardClaimed
end

function HuntingModule:IsUnlocked()
    local sysId = ConfigRefer.HuntingConst:FuncSwitch()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)
end

function HuntingModule:GetCurDailyRewardGroupId()
    local curFinishedSectionId = self:GetNextSectionId() - 1
    local sectionCfg = ConfigRefer.HuntingSection:Find(curFinishedSectionId)
    local dailyRewardGroupId = sectionCfg:DailyReward()
    return dailyRewardGroupId
end

function HuntingModule:GotoCityElementData(eleDataCfgId, failedCallback)
    local city = ModuleRefer.CityModule:GetMyCity()
    if city == nil then
        if failedCallback then failedCallback("CityNotExisted") end
        return
    end

    local element = city.elementManager:GetElementById(eleDataCfgId)
    if element == nil then
        if failedCallback then failedCallback("ElementNotExisted") end
        return
    end

    local CityUtils = require("CityUtils")
    local x, y = element.x, element.y
    local callback = function()
        city:LookAtCoord(x, y, 0, true)
    end
    CityUtils.TryLookAtToCityCoord(city, x, y, 0.5, callback, true)
end

function HuntingModule:GotoWorldSEByMineID(mineId, callback, failedCallback)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local seEnterDatas = player.PlayerWrapper3.PlayerSeEnter.SeEnters
    ---@type wds.SeEnter
    local seEnterData = nil
    for _, data in pairs(seEnterDatas) do
        if data.MineCfgId == mineId then
            seEnterData = data
            break
        end
    end
    if not seEnterData then
        if failedCallback then failedCallback() end
        return
    end

    --g_Logger.Error("%s, %s", seEnterData.ID, require("ObjectType").SeEnter)

    local parameter = require("RelocatePersonalEntityParameter").new()
    parameter.args.Id = seEnterData.ID
    parameter.args.ObjectType = require("ObjectType").SeEnter
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, success, response)
        ---@type wrpc.RelocatePersonalEntityResult
        local result = response.Result
        local seEnterDatas = player.PlayerWrapper3.PlayerSeEnter.SeEnters
        ---@type wds.SeEnter
        local seEnterData = nil
        for _, data in pairs(seEnterDatas) do
            if data.ID == result.Id then
                seEnterData = data
                break
            end
        end
        AllianceWarTabHelper.GoToCoord(seEnterData.Position.X, seEnterData.Position.Y, true)
    end)
end

---@param position wds.Vector3F
function HuntingModule:GotoWorldByPos(position, callback)
    local x, z  = KingdomMapUtils.ParseBuildingPos(position)
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x,z, KingdomMapUtils.GetMapSystem())
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    local callBackFun = function()
        GuideFingerUtil.ShowGuideFingerByWorldPos(pos)
        if callback then callback() end
    end
    basicCamera:ForceGiveUpTween()
    basicCamera:ZoomTo(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
    basicCamera:LookAt(pos, 2, callBackFun)
end

function HuntingModule:GetHuntingSectionId(elementCfgId)
    for id, cell in ConfigRefer.HuntingSection:ipairs() do
        if cell:Typo() == HuntingSectionType.TypeNpcService and cell:CityElementDataId() == elementCfgId then
            return id
        end
    end

    return nil
end

function HuntingModule:GetHuntingSectionIdByCompId(compId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local seEnterDatas = player.PlayerWrapper3.PlayerSeEnter.SeEnters
    if not table.ContainsKey(seEnterDatas, compId) then
        return nil
    end

    local seEnterData = seEnterDatas[compId]
    if seEnterData.HuntingSectionId and seEnterData.HuntingSectionId > 0 then
        return seEnterData.HuntingSectionId
    end

    return nil
end

return HuntingModule