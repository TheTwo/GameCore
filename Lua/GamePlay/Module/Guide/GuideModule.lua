---@diagnostic disable: 512
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ClientDataKeys = require('ClientDataKeys')
local GuideType = require('GuideType')
local Utils = require('Utils')
local GuideUtils = require('GuideUtils')
local Delegate = require('Delegate')
local GuideConditionProcesser = require('GuideConditionProcesser')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local UIMediatorNames = require('UIMediatorNames')
local QueuedTask = require('QueuedTask')
local EventConst = require('EventConst')
local GuideTriggerWatcher = require('GuideTriggerWatcher')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
local KingdomMapUtils = require('KingdomMapUtils')
local I18N = require('I18N')
local CitizenBTDefine = require("CitizenBTDefine")
local GuideConst = require("GuideConst")
local GuideStepSimpleFactory = require("GuideStepSimpleFactory")

---@class GuideModule : BaseModule
local GuideModule = class('GuideModule',BaseModule)

GuideModule.PlayerPrefsKeys = 'GuideModule_BlockGuide'
GuideModule.PlayerPrefsKeys_Debug = 'GuideModule_Debug'
function GuideModule:ctor()
    self.savedStep = nil -- 断线重连时保存的引导信息
    self.finCallback = nil

    self.debugMode = g_Game.PlayerPrefsEx:GetInt(GuideModule.PlayerPrefsKeys_Debug,0) > 0.5
    self.blockGuide = g_Game.PlayerPrefsEx:GetInt(GuideModule.PlayerPrefsKeys,0)

    self.curStep = nil
end

function GuideModule:OnRegister()
    self:ReadFinishedGroup()
    self.conditionProcesser = GuideConditionProcesser.new(self)
    self.watcher = GuideTriggerWatcher.new()
    self.watcher:InitWatcher()
    g_Game.EventManager:AddListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))

    g_Game.EventManager:AddListener(EventConst.GUIDE_STEP_START, Delegate.GetOrCreate(self, self.OnGuideStepStart))
    g_Game.EventManager:AddListener(EventConst.GUIDE_STEP_END, Delegate.GetOrCreate(self, self.OnGuideStepEnd))
end

function GuideModule:OnRemove()
    if self.watcher then
        self.watcher:ReleaseWatcher()
    end
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))

    g_Game.EventManager:RemoveListener(EventConst.GUIDE_STEP_START, Delegate.GetOrCreate(self, self.OnGuideStepStart))
    g_Game.EventManager:RemoveListener(EventConst.GUIDE_STEP_END, Delegate.GetOrCreate(self, self.OnGuideStepEnd))
end

function GuideModule:OnReloginStart()
    if self.curStep then
        self.curStep:Stop()
        self.savedStep = self.curStep
    end
end

function GuideModule:OnReloginSuccess()
    if self.savedStep then
        local groupCfg = self.savedStep:GetGuideGroupCfg()
        local guideCall = self.savedStep:GetGuideCallCfg()
        local startStepId = groupCfg:First()
        local step = GuideStepSimpleFactory.CreateGuideStep(startStepId):SetGuideGroupCfg(groupCfg):SetGuideCallCfg(guideCall)
        local targetStep = self.savedStep
        while step do
            local zone = step:GetCfg():Zone()
            if step:IsForce() and (Utils.IsNullOrEmpty(zone:UIName()) or zone:UIName() == "HUDMediator") then
                targetStep = step
            elseif step:GetType() == GuideType.Dialog then
                targetStep = step
            end
            if step:GetCfgId() == self.savedStep:GetCfgId() then
                break
            end
            step = step:GetNextStep()
        end
        targetStep:Execute()
    end
end

---@private
---@param step BaseGuideStep
function GuideModule:OnGuideStepStart(step)
    local keyMap = FPXSDKBIDefine.ExtraKey.guide_step
    local extraDic = {}
    extraDic[keyMap.id] = step:GetCfgId()
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.guide_step, extraDic)
    self.curStep = step
end

---@private
---@param step BaseGuideStep
---@param success boolean
function GuideModule:OnGuideStepEnd(step, success)
    if not success then
        self.curStep = nil
        return
    end

    if step:ShouldUpload() then
        local groupCfg = step:GetGuideGroupCfg()
        if groupCfg then
            self:SaveFinishedGroup(groupCfg:Id())
        end
    end

    local nextStep = step:GetNextStep()
    if not nextStep then
        local groupCfg = step:GetGuideGroupCfg()
        if groupCfg then
            self:SaveFinishedGroup(groupCfg:Id())
        end

        if self.finCallback then
            self.finCallback()
            self.finCallback = nil
        end
    else
        nextStep:Execute()
    end
end

---@param id number @Id of GuideCallConfigCell
---@param callback fun()
function GuideModule:CallGuide(id, callback)
    local success = false
    while true do
        if not id then break end

        if self.blockGuide > 0 and id > 2 then break end

        local callConfig = ConfigRefer.GuideCall:Find(id)
        if not callConfig then break end

        local length = callConfig:GuideGroupsLength()
        local groupInfos = {}
        for i = 1, length do
            local groupId = callConfig:GuideGroups(i)
            local info = {cfg = ConfigRefer.GuideGroup:Find(groupId)}
            info.id = groupId
            info.priority = info.cfg:Priority()
            info.guideCall = callConfig
            table.insert(groupInfos, info)
        end
        if #groupInfos > 0 then
            table.sort(groupInfos, function(a, b)
                if a.priority ~= b.priority then
                    return a.priority < b.priority
                end
                return a.id < b.id
            end)
        end

        local cfg = nil
        local guideCall = nil
        for _, value in ipairs(groupInfos) do
            if self:CheckGuideGroupCondition(value.id, value.cfg, value.guideCall) then
                cfg = value.cfg
                guideCall = value.guideCall
                break
            end
        end

        if not cfg then break end

        if not guideCall then break end

        self.finCallback = callback
        self:ExeGuideGroup(cfg, guideCall)
        success = true
        break
    end

    if not success then
        if callback then
            callback()
        end
    end
    return success
end

---@private
---@param groupId number
---@param config GuideGroupConfigCell
---@param guideCall GuideCallConfigCell|nil
function GuideModule:CheckGuideGroupCondition(groupId, config, guideCall)
    if not self.debugMode and self:IsGuideGroupFinished(groupId, config) then
        g_Logger.LogChannel('GuideModule','[<color=red>%s</color>]GuideGroup[%d]跳过，已经执行过不重复执行',g_Logger.SpChar_Wrong,groupId)
       return false
    end

    if not config then
        config = ConfigRefer.GuideGroup:Find(groupId)
        if not config then
            g_Logger.ErrorChannel('GuideModule','[<color=red>%s</color>]GuideGroup[%d]错误，找不到配置数据',g_Logger.SpChar_Wrong,groupId)
            return false
        end
    end

    if config:Ban() then
        g_Logger.LogChannel('GuideModule','[<color=red>%s</color>]GuideGroup[%d]跳过，配置屏蔽',g_Logger.SpChar_Wrong,groupId)
        return false
    end

    local conditionRes = self:ExeConditionCmd(config:TriggerCmd(), guideCall)
    if not conditionRes then
        g_Logger.LogChannel('GuideModule','[<color=red>%s</color>]GuideGroup[%d]跳过，判定条件不满足',g_Logger.SpChar_Wrong,groupId)
    end
    return conditionRes
end

---@param groupConfig GuideGroupConfigCell
---@param guideCall GuideCallConfigCell
function GuideModule:ExeGuideGroup(groupConfig, guideCall)
    if not groupConfig then return end
    g_Logger.LogChannel('GuideModule', '[<color=green>%s</color>]GuideGroup[%d]开始执行(%d)', g_Logger.SpChar_Right, groupConfig:Id(), g_Game.Time.frameCount)

    local groupId = groupConfig:Id()
    ModuleRefer.FPXSDKModule:TrackTutorial(groupId)

    local stepId = groupConfig:First()
    local step = GuideStepSimpleFactory.CreateGuideStep(stepId):SetGuideCallCfg(guideCall):SetGuideGroupCfg(groupConfig)
    step:Execute()
end

function GuideModule:ExecuteGuideStepDirectly(stepId)
    local step = GuideStepSimpleFactory.CreateGuideStep(stepId)
    step:Execute()
end

function GuideModule:StopCurrentStep()
    if self.curStep then
        self.curStep:Stop()
        self.curStep = nil
    end
end

function GuideModule:IsExecuting()
    if not self.curStep then
        return false
    end
    return self.curStep:IsExecuting()
end

---@param groupId number @Id of GuideGroupConfigCell
---@param config GuideGroupConfigCell
function GuideModule:IsGuideGroupFinished(groupId, config)
    if config == nil then
        config = ConfigRefer.GuideGroup:Find(groupId)
    end
    if not self.finishGroup or config:Repeat() then
        return false
    end
    return table.ContainsValue(self.finishGroup,groupId)
end

---@param id number @Id of GuideCallConfigCell
function GuideModule:IsGuideFinished(id)
    local callConfig = ConfigRefer.GuideCall:Find(id)
    if not callConfig then return false end
    local groupLength = callConfig:GuideGroupsLength()
    if groupLength < 1 then return false end
    return self:IsGuideGroupFinished(callConfig:GuideGroups(1))
end

function GuideModule:ReadFinishedGroup()
    local saveCount = checknumber(ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.GuideFinishCount))
    self.finishGroup = {}
    if not saveCount or saveCount < 1 then return end
    saveCount = math.min(saveCount,ClientDataKeys.GameData.GuideFinishMax - ClientDataKeys.GameData.GuideFinishMin + 1)
    for i = 1, saveCount do
        local dataKey = ClientDataKeys.GameData.GuideFinishMin + i - 1
        local saveDataStr = ModuleRefer.ClientDataModule:GetData(dataKey)
        if not saveDataStr then
            break
        end
        local saveData =  CS.GuideUtil.Base64String2IntArray(saveDataStr)
        if saveData and saveData.Length > 0 then
            for j = 0, saveData.Length-1 do
                local id = checknumber(saveData[j])
                if id and id > 0 then
                    table.insert(self.finishGroup,id)
                end
            end
        end
    end
end

---@param groupId number @Id of GuideGroupConfigCell
function GuideModule:SaveFinishedGroup(groupId)
    if self.finishGroup and table.ContainsValue(self.finishGroup,groupId) then
        return
    end
    local groupCfg = ConfigRefer.GuideGroup:Find(groupId)
    if not groupCfg or groupCfg:Repeat() or groupCfg:Ban() then
        return
    end
    if not self.finishGroup then
        self.finishGroup = {}
    elseif table.ContainsValue(self.finishGroup, groupId) then
        return
    end

    table.insert(self.finishGroup,groupId)

    local subGroupIndex = math.floor((table.nums(self.finishGroup)-1) / 10)
    local subGroupLength = math.floor((table.nums(self.finishGroup)-1) % 10) + 1

    local subGroup
    if subGroupIndex < 1 then
        subGroup = self.finishGroup
    else
        subGroup = {}
        for i = 1, subGroupLength do
            table.insert(subGroup,self.finishGroup[subGroupIndex * 10 + i])
        end
    end

    local groupLength = #subGroup
    local dataArray = CS.System.Array.CreateInstance(typeof(CS.System.Int32),groupLength)
    for i = 1, groupLength do
        dataArray[i-1] = subGroup[i]
    end
    local saveDataStr = CS.GuideUtil.IntArray2Base64String(dataArray)
    ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.GuideFinishMin + subGroupIndex,saveDataStr)
    ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.GuideFinishCount,subGroupIndex+1)
end

function GuideModule:ClearGuideFinishSaveData()
    ModuleRefer.ClientDataModule:RemoveData(ClientDataKeys.GameData.GuideFinish)
end

---@param cmd string @Get from GuideGroupConfigCell:TriggerCmd()
---@param guideCall GuideCallConfigCell|nil
function GuideModule:ExeConditionCmd(cmdStr, guideCall)
    if string.IsNullOrEmpty(cmdStr) then return true end
    return self.conditionProcesser:ExeConditionCmd(cmdStr, guideCall);
end

function GuideModule:FirstClickGuide(clickType, pos, guideId)
    local isClicked = ModuleRefer.ClientDataModule:GetData(clickType)
    if not isClicked then
        ModuleRefer.ClientDataModule:SetData(clickType, 1)
        local callback = function()
            GuideUtils.GotoByGuide(guideId)
        end
        local size = ConfigRefer.ConstMain:ChooseCameraDistance()
        KingdomMapUtils.GetBasicCamera():ZoomToWithFocus(size, CS.UnityEngine.Vector3(0.5, 0.5), pos, 0.3, callback)
        return true
    end
    return false
end

-- 盟主开联盟界面 首次触发发布招募和科技， 之后联盟人数>=20且无乡镇时触发攻打乡镇指引
function GuideModule:CheckAllianceLeaderGuide()
    local leaderInfo = ModuleRefer.AllianceModule:GetAllianceLeaderInfo()
    if not leaderInfo then
        return
    end
    -- 与新加联盟的迁城引导互斥
    if self.JoinAllianceGuideOpen then
        return
    end
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    if selfFacebookId ~= leaderInfo.FacebookID then return end
    local leaderGuided = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.AllianceLeaderFirstGuide)
    if not leaderGuided then
        ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.AllianceLeaderFirstGuide, 1)
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.AllianceLeaderFirstGuide)
        return
    end
    local attackVillageGuide = g_Game.PlayerPrefsEx:GetIntByUid("alliance_leader_guide_attack_village", 0)
    if attackVillageGuide == 0 then
        if not ModuleRefer.VillageModule:AllianceHasAnyVillage() and ModuleRefer.AllianceModule:GetMyAllianceMemberCount() >= 20 then
            g_Game.PlayerPrefsEx:SetIntByUid("alliance_leader_guide_attack_village", 0)
            g_Game.PlayerPrefsEx:Save()
            ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.AllianceLeaderAttackVillage)
            return
        end
    end
end

-- 非盟主 入盟 迁城 到联盟中心或者盟主附近 有联盟中心优先联盟中心
function GuideModule:CheckFirstJoinAllianceRelocateGuide()
    local leaderInfo = ModuleRefer.AllianceModule:GetAllianceLeaderInfo()
    if not leaderInfo then
        return
    end
    -- 自己是盟主 不触发
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    if selfFacebookId == leaderInfo.FacebookID then
        return
    end

    local triggerGuide = false
    local allianceIdStr = nil
    local allianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillage()
    if allianceCenter then
        local lastAllianceCenter = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.AllianceCenterJumpGuide)
        allianceIdStr = tostring(ModuleRefer.AllianceModule:GetAllianceId())
        -- 玩家在这个联盟还没引导过迁城到联盟中心
        if not lastAllianceCenter or lastAllianceCenter ~= allianceIdStr then
            triggerGuide = true
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.AllianceCenterJumpGuide, allianceIdStr)
        else
            -- 在这个联盟已经触发过迁城联盟中心了 不用再检查迁城盟主附近了
            return
        end
    end

    if not triggerGuide then
        local isGuided = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.JoinAllianceGuide)
        -- 玩家还没触发过迁城到盟主附近
        if not isGuided then
            triggerGuide = true
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.JoinAllianceGuide, 1)
        end
    end
    --090，临时去掉入盟迁城引导
    -- triggerGuide = false
    if not triggerGuide then return end
    local dialogParam = {}
    local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("relocate_AllianceLeader_title")
    dialogParam.content = allianceCenter and I18N.Get("alliance_center_relocate1") or I18N.Get("relocate_AllianceLeader_des")
    dialogParam.confirmLabel = I18N.Get("relocate_AllianceLeader_goto")
    dialogParam.onConfirm = function()
        if KingdomMapUtils.IsCityState() then
            KingdomMapUtils.GetKingdomScene():LeaveCity(function()
                self:FocusAroundAllianceAndShowRelocate(allianceCenter)
            end)
        else
            self:FocusAroundAllianceAndShowRelocate(allianceCenter)
        end
        self.JoinAllianceGuideOpen = false
        return true
    end
    dialogParam.onCancel = function()
        self.JoinAllianceGuideOpen = false
        return true
    end
    self.JoinAllianceGuideOpen = true
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

---@param allianceCenter wds.MapBuildingBrief|nil
function GuideModule:FocusAroundAllianceAndShowRelocate(allianceCenter)
    local allianceMainMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.AllianceMainMediator)
    if allianceMainMediator then
        allianceMainMediator:CloseSelf()
    end
    local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    local callback = function()
        local leaderInfo = ModuleRefer.AllianceModule:GetAllianceLeaderInfo()
        if not leaderInfo then
            return
        end
        local tempx, tempz  = KingdomMapUtils.ParseBuildingPos(leaderInfo.BigWorldPosition)
        if allianceCenter then
            tempx, tempz = KingdomMapUtils.ParseBuildingPos(allianceCenter.Pos)
        end
        -- local coord = {X = tempx + self.offsetX, Y = tempz + self.offsetY}
        local coord = {X = tempx, Y = tempz}
        local castleBrief = ModuleRefer.PlayerModule:GetCastle()
        if not castleBrief then
            return
        end
        local relocateCallBack = function()
            local relocateOffset = ConfigRefer.AllianceConsts:RelocateOffset()
            local layoutConfigId = castleBrief.MapBasics.LayoutCfgId
            local sizeX, sizeY = KingdomMapUtils.GetLayoutSize(layoutConfigId)
            ModuleRefer.KingdomPlacingModule:SearchForAvailableRect(coord.X, coord.Y, 100, relocateOffset, sizeX, sizeY, function(ret, x, y)
                if ret then
                    local position = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
                    KingdomMapUtils.GetBasicCamera():LookAt(position)
                end
            end)
        end
        ModuleRefer.KingdomPlacingModule:StartRelocate(castleBrief.MapBasics.ConfID, ModuleRefer.RelocateModule.CanRelocate, coord, relocateCallBack)

    end
    local leaderInfo = ModuleRefer.AllianceModule:GetAllianceLeaderInfo()
    if not leaderInfo then
        return
    end
    local tempx, tempz  = KingdomMapUtils.ParseBuildingPos(leaderInfo.BigWorldPosition)
    if allianceCenter then
        tempx, tempz = KingdomMapUtils.ParseBuildingPos(allianceCenter.Pos)
    end
    self.offsetX = math.random(-25, 25)
    self.offsetY = math.random(-25, 25)
    local worldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(tempx, tempz, KingdomMapUtils.GetMapSystem())
    if worldPos == CS.UnityEngine.Vector3.zero then
        return
    end
    KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    KingdomMapUtils.GetBasicCamera():ZoomToWithFocus(size, CS.UnityEngine.Vector3(0.5, 0.5), worldPos, 1, callback)
end

return GuideModule