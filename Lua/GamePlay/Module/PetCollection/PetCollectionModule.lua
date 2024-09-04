local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local KingdomMapUtils = require("KingdomMapUtils")
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local Utils = require("Utils")
local EventConst = require("EventConst")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require("UIMediatorNames")
local NotificationType = require("NotificationType")
---@class PetCollectionModule
local PetCollectionModule = class('PetCollectionModule', BaseModule)
local PetCollectionEnum = require("PetCollectionEnum")
local GetPetHandbookRewardParameter = require('GetPetHandbookRewardParameter')
local SetPetHandbookRedPointParameter = require('SetPetHandbookRedPointParameter')
local PetHandbookSignNameParameter = require('PetHandbookSignNameParameter')
local PetUnlockStoryParameter = require('PetUnlockStoryParameter')
local PetResearchTopicType = require('PetResearchTopicType')
local ProtocolId = require("ProtocolId")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local UIManager = require("UIManager")
local BattleLabel = require('BattleLabel')
local PetQuality = require('PetQuality')

function PetCollectionModule:ctor()
    self.PopUpTable = {}
end

function PetCollectionModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetHandbook.PetResearchs.MsgPath, Delegate.GetOrCreate(self, self.CheckStoryRedDot))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncPetResearchProcess, Delegate.GetOrCreate(self, self.ResearchComplete))
    -- g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncPetResearchProcessAllOK, Delegate.GetOrCreate(self, self.ResearchAllComplete))
end

function PetCollectionModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetHandbook.PetResearchs.MsgPath, Delegate.GetOrCreate(self, self.CheckStoryRedDot))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncPetResearchProcess, Delegate.GetOrCreate(self, self.ResearchComplete))
    -- g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncPetResearchProcessAllOK, Delegate.GetOrCreate(self, self.ResearchAllComplete))

    self.petsInAreas = {}
end

function PetCollectionModule:IsPetUnlock(type)
    return self:GetResearchData(type) ~= nil
end

function PetCollectionModule:GetAreaList()
    local res = {}

    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook
    for _, cell in ConfigRefer.PetHandbook:ipairs() do
        local param = cell

        param.areaIndex = cell:Id()
        param.maxProgress = self:GetPetNumByArea(cell:Id())
        param.curProgress = self:GetCurPetNumByArea(cell:Id())

        local systemEntry = param:OpenSwitch()

        param.passSys = true
        if systemEntry > 0 then
            param.passSys = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntry)
        end

        -- 天下大势阶段
        local pass = true
        local curStage = ModuleRefer.WorldTrendModule:GetCurStage().Stage
        for i = 1, param:SkipWorldStageLength() do
            if curStage < param:SkipWorldStage(i) then
                pass = false
            end
        end
        param.passWorldStage = pass

        table.insert(res, param)
    end
    return res
end

function PetCollectionModule:GetAreaName(id)
    local res = ConfigRefer.PetHandbook:Find(id):Name()
    return I18N.Get(res)
end

-- 奖励
function PetCollectionModule:GetCollectionRewardList()
    local res = {}
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook

    for i = 1, ConfigRefer.PetHandbookProcessReward.length do
        local param = ConfigRefer.PetHandbookProcessReward:Find(i)
        param.isClaim = data.RewardHistorys and data.RewardHistorys[i] or false
        table.insert(res, param)
    end

    return res
end

-- 当前奖励进度
function PetCollectionModule:GetCollectionRewardCurrentProgress()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook.ResearchPoint or 0
end

-- 领奖历史
function PetCollectionModule:GetCollectionRewardHistorys()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook.RewardHistorys
end

-- 照片
function PetCollectionModule:GetPetsByArea(areaIndex)
    if self.petsInAreas == nil then
        self.petsInAreas = {}
    end

    if self.petsInAreas[areaIndex] then
        return self.petsInAreas[areaIndex]
    end

    local typeCfgList = ModuleRefer.PetModule:GetTypeCfgList()
    local res = {}

    for k, cfg in pairs(typeCfgList) do
        local isSelect = false
        for i = 1, cfg:HandbooksLength() do
            if areaIndex == cfg:Handbooks(i) then
                isSelect = true
            end
        end
        if isSelect then
            table.insert(res, cfg)
        end
    end

    table.sort(res, function(a, b)
        return tonumber(a:PetBookId()) < tonumber(b:PetBookId())
    end)

    self.petsInAreas[areaIndex] = res
    return self.petsInAreas[areaIndex]
end

--- @param cfg PetType.csv
function PetCollectionModule:GetPetStatus(cfg)
    local res = PetCollectionEnum.PetStatus.NotOwn
    local isOwn = self:IsPetUnlock(cfg:Id())
    local level = ConfigRefer.PetResearch:Find(cfg:PetResearchId()):UnlockCondMainCityLevel()
    local castleLevel = ModuleRefer.PlayerModule:StrongholdLevel()
    local isLock = castleLevel < level

    if isOwn then
        res = PetCollectionEnum.PetStatus.Own
    else
        if isLock then
            res = PetCollectionEnum.PetStatus.Lock
        else
            res = PetCollectionEnum.PetStatus.NotOwn
        end
    end
    return res
end

-- 详情
function PetCollectionModule:GetDetailInfo(pageIndex, areaIndex)
    local data = PetCollectionModule:GetPetsByArea(areaIndex)
    return data[pageIndex]
end

-- 同一地区最大宠物数量
function PetCollectionModule:GetPetNumByArea(areaIndex)
    return #PetCollectionModule:GetPetsByArea(areaIndex)
end

-- 同一地区当前宠物数量
function PetCollectionModule:GetCurPetNumByArea(areaIndex)
    local res = 0

    if self.petsInAreas and self.petsInAreas[areaIndex] then
        local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook

        for k, v in pairs(self.petsInAreas[areaIndex]) do
            for k2, v2 in pairs(data.CategoryPetOKNum) do
                if v:Id() == k2 then
                    res = res + 1
                    break
                end
            end
        end
    end

    return res
end

-- 研究
function PetCollectionModule:GetResearchConfig(petIndex)
    local petType = ConfigRefer.PetType:Find(petIndex)
    local cfg = ConfigRefer.PetResearch:Find(petType:PetResearchId())
    return cfg
end

-- 研究经验
function PetCollectionModule:GetMaxExp(cfg, level)
    if (not cfg) then
        return 0, 0, 0
    end
    local expTemp = ModuleRefer.PetModule:GetExpTemplateCfg(cfg:Exp())
    if (not expTemp) then
        return 0, 0, 0
    end
    level = (level and level > 0) and level or 1
    level = math.min(level, expTemp:ExpLvLength(), expTemp:MaxLv())
    local maxExp = expTemp:ExpLv(level)
    return maxExp
end

-- 计算所有小传红点
function PetCollectionModule:CheckStoryRedDot(entity, changedData)
    self.petCollectionRedPoint = false
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook

    if data.PetResearchs then
        local storyNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory", NotificationType.PET_STORY)
        -- TODO:单刷
        -- if changedData and changedData.Add then
        --     for k, v in pairs(changedData.Add) do
        --         local petStoryNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory_" .. k, NotificationType.PET_STORY)
        --         local storyUnlockCount = petStoryNode.NotificationCount
        --         local cfg = ConfigRefer.PetStory:Find(k)
        --         if cfg and v.StoryUnlock and v.StoryUnlock.Add then
        --             if v.StoryUnlock.Add then
        --                 for k2, v2 in pairs(v.StoryUnlock.Add) do
        --                     if v2 then
        --                         storyUnlockCount = storyUnlockCount - 1
        --                     end
        --                 end
        --             end
        --         end
        --         ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(petStoryNode, storyUnlockCount)
        --     end
        --     return
        -- end

        -- 全刷
        for k, v in pairs(data.PetResearchs) do
            local petType = ConfigRefer.PetType:Find(v.CfgId)
            local cfg = ConfigRefer.PetStory:Find(petType:PetStoryId())
            local petStoryNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory_" .. v.CfgId, NotificationType.PET_STORY)
            ModuleRefer.NotificationModule:AddToParent(petStoryNode, storyNode)
            local storyUnlockCount = 0
            if cfg then
                local unlock = v.StoryUnlock or {}
                for i = 2, cfg:UnlockInfoLength() do
                    if unlock[i-1] == nil and v.Level > cfg:UnlockInfo(i-1):NeedLevel() then
                        self.petCollectionRedPoint = true
                        storyUnlockCount = storyUnlockCount + 1
                    end
                end
            end
            ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(petStoryNode, storyUnlockCount)
        end
        g_Game.EventManager:TriggerEvent(EventConst.PET_COLLECTION_STORY_RED_POINT)
    end
end

function PetCollectionModule:ResetStoryRedPoint(areaId, petId, storyId)
    local petType = ConfigRefer.PetType:Find(petId)
end

-- 图鉴故事红点初始化
function PetCollectionModule:InitStoryRedPoint()
    local unlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.PetConsts:PetHandbookUnlock())
    if unlock then
        local redNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory", NotificationType.PET_STORY)
        ModuleRefer.NotificationModule:AddToParent(redNode, ModuleRefer.PetModule:GetRedDotMain())
        self:CheckStoryRedDot()
        return self.petCollectionRedPoint
    else
        return false
    end
end

-- 图鉴入口小传红点
function PetCollectionModule:GetStoryRedPoint()
    local unlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.PetConsts:PetHandbookUnlock())
    if unlock then
        return self.petCollectionRedPoint
    else
        return false
    end
end

-- wrpc部分
function PetCollectionModule:GetResearchData(petIndex)
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook

    if data.PetResearchs == nil then
        return nil
    end
    for k, v in pairs(data.PetResearchs) do
        if k == petIndex then
            return v
        end
    end
    return nil
end

-- 主动领奖
function PetCollectionModule:ClaimReward(IDs, callback)
    if IDs == {} then
        return
    end

    local msg = GetPetHandbookRewardParameter.new()
    msg.args.PetHandbookProcessRewardCfgIds:AddRange(IDs)
    msg:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
        end
    end)

end

function PetCollectionModule:GetRedDotStatus(petType)
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook
    if data.RedPoints then
        for k, v in pairs(data.RedPoints) do
            if k == petType then
                return false
            end
        end
    end
    return true
end

function PetCollectionModule:GetStoryNewRedDotStatus()
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetHandbook
    if data.RedPoints then
        for k, v in pairs(data.RedPoints) do
            if v == true then
                return false
            end
        end
    end

end

-- 设置红点
function PetCollectionModule:SetRedpoint(Ids)
    local msg = SetPetHandbookRedPointParameter.new()
    msg.args.PetTypeCfgIds:AddRange(Ids)
    msg:Send()
end

function PetCollectionModule:GetNewRedpoint(id)

end

-- 签名
function PetCollectionModule:Sign(IDs, callback)
    local msg = PetHandbookSignNameParameter.new()
    msg.args.PetTypeCfgIds:AddRange(IDs)
    msg:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
        end
    end)
end

-- 解锁小传
function PetCollectionModule:UnlockStory(id, index, callback)
    local msg = PetUnlockStoryParameter.new()
    msg.args.PetTypeCfgId = id
    msg.args.Index = index
    -- msg:Send()

    msg:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
        end
    end)
end

-- 弹窗部分
-- 播放下个弹窗
-- function PetCollectionModule:ShowNextPopUpWindow()
--     local unlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(ConfigRefer.PetConsts:PetHandbookUnlock())
--     if not unlock then
--         return
--     end

--     -- 屏蔽捉宠界面
--     if g_Game.UIManager:IsOpenedByName(UIMediatorNames.PetCaptureMediator) then
--         return
--     end

--     if self.PopUpTable and #self.PopUpTable > 0 then
--         -- local isPass = self.PopUpTable[1]:Check()
--         -- if isPass == 0 then
--         local data = table.remove(self.PopUpTable, 1)

--         g_Game.UIManager:Open(data.uiMediatorName, data)
--         -- end
--     end
-- end

-- 某项课题达成
---@param isSuccess boolean
---@param data wrpc.SyncPetResearchProcessRequest
function PetCollectionModule:ResearchComplete(isSuccess, data)
    if isSuccess then
        local provider = UIAsyncDataProvider.new()
        local checkTypes = UIAsyncDataProvider.CheckTypes.DoNotShowInSE | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
        data.provider = provider
        provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
        data.uiMediatorName = UIMediatorNames.PetCollectionResearchCompleteMediator
        provider:Init(UIMediatorNames.PetCollectionResearchCompleteMediator, nil, checkTypes, nil, nil, data)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end
end

-- 课题全部完成
---@param isSuccess boolean
---@param data wrpc.SyncPetResearchProcessAllOKRequest
function PetCollectionModule:ResearchAllComplete(isSuccess, data)
    if isSuccess then
        local provider = UIAsyncDataProvider.new()
        local checkTypes = UIAsyncDataProvider.CheckTypes.DoNotShowInSE | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
        data.provider = provider
        provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
        data.uiMediatorName = UIMediatorNames.PetCollectionResearchCompleteFullMediator
        provider:Init(UIMediatorNames.PetCollectionResearchCompleteFullMediator, nil, checkTypes, nil, nil, data)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end
end

function PetCollectionModule:IsPetCollectComplete(petType)
    local researchData = self:GetResearchData(petType)
    return (researchData and researchData.IsFullLevel) and researchData.IsFullLevel or false

    -- local cfg = self:GetResearchConfig(petType)
    -- for i = 1, cfg:TopicsLength() do
    --     -- 所有研究课题是否有进度
    --     local researchProcess = researchData.ResearchProcess[i - 1]
    --     if (not researchProcess) then
    --         return false
    --     end

    --     local topicLength = ConfigRefer.PetResearchTopic:Find(i):ItemsLength()
    --     if #researchProcess.TopicProcess < topicLength then
    --         return false
    --     end
    --     -- 每项课题进度是否为满
    --     for k, v in pairs(researchProcess.TopicProcess) do
    --         if v == false then
    --             return false
    --         end
    --     end
    -- end

    -- return true
end

function PetCollectionModule:GetPetBookId(petCfgId)
    return I18N.GetWithParams("petguide_number", string.format("%03s", petCfgId))
end

function PetCollectionModule:GetFrameByQuality(quality)
    if quality == PetQuality.LV1 then
        return "sp_pet_book_base_frame_0"
    elseif quality == PetQuality.LV2 then
        return "sp_pet_book_base_frame_1"
    elseif quality == PetQuality.LV3 then
        return "sp_pet_book_base_frame_2"
    elseif quality == PetQuality.LV4 then
        return "sp_pet_book_base_frame_3"
    end
end

return PetCollectionModule
