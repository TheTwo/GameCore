local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local UIMediatorNames = require('UIMediatorNames')
local BehaviourManager = require('BehaviourManager')
local Delegate = require('Delegate')
local Utils = require('Utils')
local CloudUtils = require('CloudUtils')

local VECTOR3_ZERO = CS.UnityEngine.Vector3.zero
local VECTOR3_ONE = CS.UnityEngine.Vector3.one
local PET_TIMELINE_COUNT = 14

local SetPetWildIsLockParameter = require('SetPetWildIsLockParameter')

---@class PetCaptureModule : BaseModule
---@field super BaseModule
local PetCaptureModule = class('PetCaptureModule', BaseModule)

function PetCaptureModule:ctor()
    ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
    self.createHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()

	---@type table<number, CS.CG.Plot.plotDirector>
	self.plotDirectorTable = {}
	self.petTimelineLoadComplete = false
	self.petTimelineLoadCount = 0

	---@type CS.UnityEngine.GameObject
	self.petTimelineNode = nil
	
	---@type CS.UnityEngine.GameObject
	self.petTimelineThrowLeft = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineThrowMiddle = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineThrowRight = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineCapture = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineShake1 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineShake2 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineShake3 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineSuccess = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail1 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail2 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail3 = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail1Vfx = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail2Vfx = nil
	---@type CS.UnityEngine.GameObject
	self.petTimelineFail3Vfx = nil

	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineThrowLeftDirector = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineThrowMiddleDirector = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineThrowRightDirector = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineCaptureDirector = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineShake1Director = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineShake2Director = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineShake3Director = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineSuccessDirector = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineFailDirector1 = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineFailDirector2 = nil
	---@type CS.UnityEngine.Playables.PlayableDirector
	self.petTimelineFailDirector3 = nil

	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineThrowLeftWrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineThrowMiddleWrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineThrowRightWrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineCaptureWrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineShake1Wrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineShake2Wrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineShake3Wrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineSuccessWrapper = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineFailWrapper1 = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineFailWrapper2 = nil
	---@type CS.PlayableDirectorListenerWrapper
	self.petTimelineFailWrapper3 = nil
end

function PetCaptureModule:OnRegister()
end

function PetCaptureModule:OnRemove()
    self:CleanTimelines()

    if not Utils.IsNull(self.createHelper) then
        self.createHelper:CancelAllCreate()
    end
end

function PetCaptureModule:CleanTimelines()
	-- 清理Timeline
	for _, plotDirector in ipairs(self.plotDirectorTable) do
		plotDirector:ClearOnBehaviourCGLuaCallbacks()
	end

	-- Pet Timeline
	if (self.petTimelineCaptureWrapper) then
		self.petTimelineCaptureWrapper.stoppedCallback = nil
	end
	if (self.petTimelineFailWrapper1) then
		self.petTimelineFailWrapper1.stoppedCallback = nil
	end
	if (self.petTimelineFailWrapper2) then
		self.petTimelineFailWrapper2.stoppedCallback = nil
	end
	if (self.petTimelineFailWrapper3) then
		self.petTimelineFailWrapper3.stoppedCallback = nil
	end
	if (self.petTimelineThrowLeftWrapper) then
		self.petTimelineThrowLeftWrapper.stoppedCallback = nil
	end
	if (self.petTimelineThrowMiddleWrapper) then
		self.petTimelineThrowMiddleWrapper.stoppedCallback = nil
	end
	if (self.petTimelineThrowRightWrapper) then
		self.petTimelineThrowRightWrapper.stoppedCallback = nil
	end
	if (self.petTimelineShake1Wrapper) then
		self.petTimelineShake1Wrapper.stoppedCallback = nil
	end
	if (self.petTimelineShake2Wrapper) then
		self.petTimelineShake2Wrapper.stoppedCallback = nil
	end
	if (self.petTimelineShake3Wrapper) then
		self.petTimelineShake3Wrapper.stoppedCallback = nil
	end
	if (self.petTimelineSuccessWrapper) then
		self.petTimelineSuccessWrapper.stoppedCallback = nil
	end

    if not Utils.IsNull(self.petTimelineNode) then
        CS.UnityEngine.GameObject.Destroy(self.petTimelineNode)
        self.petTimelineNode = nil
    end
end

---City抓宠
---@param npcServiceCfgId number
---@param elementId number
function PetCaptureModule:OpenPetCaptureFromCity(npcServiceCfgId, elementId)
    CloudUtils.Cover(true, function() 
        local npcServiceCfgCell = ConfigRefer.NpcService:Find(npcServiceCfgId)
        local petWildCfgId = npcServiceCfgCell:ServiceParam()

        ---@type PetCaptureMediatorParameter
        local param = {}
        param.isCity = true
        param.petWildCfgId = petWildCfgId
        param.npcServiceCfgId = npcServiceCfgId
        param.elementId = elementId
        param.landCfgId = ModuleRefer.LandformModule:GetMyLandCfgId()
        g_Game.UIManager:Open(UIMediatorNames.PetCaptureMediator, param)

        -- CloudUtils.Uncover()
    end)
end

---野外抓宠
---@param petWildCfgId number @PetWildConfigCell ID
---@param petCompId number 宠物组件ID
---@param villageId number 村庄ID
---@param landCfgId number @LandConfigCell ID
function PetCaptureModule:OpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local catchingVillageEid =  player.PlayerWrapper2.PlayerPet.CatchVillageEid
    local catchingPetCompId = player.PlayerWrapper2.PlayerPet.CatchPetWildCompId
    -- 继续上一次的抓宠
    if catchingVillageEid == villageId and catchingPetCompId == petCompId then
        self:DoOpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
        return
    end

    -- 先解锁
    if catchingVillageEid > 0 and catchingPetCompId > 0 then
        self:UnlockWildPet(catchingPetCompId, catchingVillageEid, function(cmd, isSuccess, reply)
            if not isSuccess then return end

            self:LockWildPet(petCompId, villageId, function(cmd2, isSuccess2, reply2)
                if not isSuccess2 then return end

                self:DoOpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
            end)
        end)
    else
        self:LockWildPet(petCompId, villageId, function(cmd, isSuccess, reply)
            if not isSuccess then return end
            
            self:DoOpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
        end)
    end    
end

---@param petWildCfgId number @PetWildConfigCell ID
---@param petCompId number 宠物组件ID
---@param villageId number 村庄ID
function PetCaptureModule:UnlockWildPet(petCompId, villageId, callback)
    local lockPet = SetPetWildIsLockParameter.new()
    lockPet.args.VillageEid = villageId
    lockPet.args.PetWildCompId = petCompId
    lockPet.args.Value = false
    lockPet:SendOnceCallback(nil, nil, nil, callback)
end

---@param petWildCfgId number @PetWildConfigCell ID
---@param petCompId number 宠物组件ID
---@param villageId number 村庄ID
function PetCaptureModule:LockWildPet(petCompId, villageId, callback)
    local lockPet = SetPetWildIsLockParameter.new()
    lockPet.args.VillageEid = villageId
    lockPet.args.PetWildCompId = petCompId
    lockPet.args.Value = true
    lockPet:SendOnceCallback(nil, nil, nil, callback)
end

---@param petWildCfgId number @PetWildConfigCell ID
---@param petCompId number 宠物组件ID
---@param villageId number 村庄ID
---@param landCfgId number @LandConfigCell ID
function PetCaptureModule:DoOpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
    CloudUtils.Cover(true, function() 
        ---@type PetCaptureMediatorParameter
        local param = {}
        param.isCity = false
        param.petWildCfgId = petWildCfgId
        param.petCompId = petCompId
        param.villageId = villageId
        param.landCfgId = landCfgId
        g_Game.UIManager:Open(UIMediatorNames.PetCaptureMediator, param)

        CloudUtils.Uncover()
    end)
end

function PetCaptureModule:LoadTimelines()
	local behaviourManager = BehaviourManager.Instance()
    self.petTimelineNode = CS.UnityEngine.GameObject("PetTimelineRoot")
    local trans = self.petTimelineNode.transform
    trans.localScale = VECTOR3_ONE
    trans.localPosition = VECTOR3_ZERO
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetThrowleft()), trans, function(go)
        if (go) then
            self.petTimelineThrowLeft = go
            go:SetActive(false)
            self.petTimelineThrowLeftDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineThrowLeftWrapper = self.petTimelineThrowLeftDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineThrowLeftWrapper.targetDirector = self.petTimelineThrowLeftDirector
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetThrowup()), trans, function(go)
        if (go) then
            self.petTimelineThrowMiddle = go
            go:SetActive(false)
            self.petTimelineThrowMiddleDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineThrowMiddleWrapper = self.petTimelineThrowMiddleDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineThrowMiddleWrapper.targetDirector = self.petTimelineThrowMiddleDirector
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetThrowright()), trans, function(go)
        if (go) then
            self.petTimelineThrowRight = go
            go:SetActive(false)
            self.petTimelineThrowRightDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineThrowRightWrapper = self.petTimelineThrowRightDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineThrowRightWrapper.targetDirector = self.petTimelineThrowRightDirector
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetCapture()), trans, function(go)
        if (go) then
            self.petTimelineCapture = go
            go:SetActive(false)
            self.petTimelineCaptureDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineCaptureWrapper = self.petTimelineCaptureDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineCaptureWrapper.targetDirector = self.petTimelineCaptureDirector
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetShake1()), trans, function(go)
        if (go) then
            self.petTimelineShake1 = go
            go:SetActive(false)
            self.petTimelineShake1Director = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineShake1Wrapper = self.petTimelineShake1Director.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineShake1Wrapper.targetDirector = self.petTimelineShake1Director
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetShake2()), trans, function(go)
        if (go) then
            self.petTimelineShake2 = go
            go:SetActive(false)
            self.petTimelineShake2Director = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineShake2Wrapper = self.petTimelineShake2Director.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineShake2Wrapper.targetDirector = self.petTimelineShake2Director
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetShake3()), trans, function(go)
        if (go) then
            self.petTimelineShake3 = go
            go:SetActive(false)
            self.petTimelineShake3Director = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineShake3Wrapper = self.petTimelineShake3Director.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineShake3Wrapper.targetDirector = self.petTimelineShake3Director
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetSuccess()), trans, function(go)
        if (go) then
            self.petTimelineSuccess = go
            go:SetActive(false)
            self.petTimelineSuccessDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineSuccessWrapper = self.petTimelineSuccessDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineSuccessWrapper.targetDirector = self.petTimelineSuccessDirector
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLose1()), trans, function(go)
        if (go) then
            self.petTimelineFail1 = go
            go:SetActive(false)
            self.petTimelineFailDirector1 = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineFailWrapper1 = self.petTimelineFailDirector1.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineFailWrapper1.targetDirector = self.petTimelineFailDirector1
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLose2()), trans, function(go)
        if (go) then
            self.petTimelineFail2 = go
            go:SetActive(false)
            self.petTimelineFailDirector2 = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineFailWrapper2 = self.petTimelineFailDirector2.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineFailWrapper2.targetDirector = self.petTimelineFailDirector2
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLose3()), trans, function(go)
        if (go) then
            self.petTimelineFail3 = go
            go:SetActive(false)
            self.petTimelineFailDirector3 = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.petTimelineFailWrapper3 = self.petTimelineFailDirector3.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.petTimelineFailWrapper3.targetDirector = self.petTimelineFailDirector3
            local plotDirector = go:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector))
            plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            table.insert(self.plotDirectorTable, plotDirector)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLoseVFX1()), trans, function(go)
        if (go) then
            self.petTimelineFail1Vfx = go
            go:SetActive(false)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLoseVFX2()), trans, function(go)
        if (go) then
            self.petTimelineFail2Vfx = go
            go:SetActive(false)
            self:CheckPetTimelineLoadComplete()
        end
    end)
    self.createHelper:Create(ArtResourceUtils.GetItem(ConfigRefer.PetConsts:TimelineCatchpetLoseVFX3()), trans, function(go)
        if (go) then
            self.petTimelineFail3Vfx = go
            go:SetActive(false)
            self:CheckPetTimelineLoadComplete()
        end
    end)
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineThrowLeft()
	return self.petTimelineThrowLeft, self.petTimelineThrowLeftDirector, self.petTimelineThrowLeftWrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineThrowMiddle()
	return self.petTimelineThrowMiddle, self.petTimelineThrowMiddleDirector, self.petTimelineThrowMiddleWrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineThrowRight()
	return self.petTimelineThrowRight, self.petTimelineThrowRightDirector, self.petTimelineThrowRightWrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineCapture()
	return self.petTimelineCapture, self.petTimelineCaptureDirector, self.petTimelineCaptureWrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineShake1()
	return self.petTimelineShake1, self.petTimelineShake1Director, self.petTimelineShake1Wrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineShake2()
	return self.petTimelineShake2, self.petTimelineShake2Director, self.petTimelineShake2Wrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineShake3()
	return self.petTimelineShake3, self.petTimelineShake3Director, self.petTimelineShake3Wrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPettimelineSuccess()
	return self.petTimelineSuccess, self.petTimelineSuccessDirector, self.petTimelineSuccessWrapper
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.UnityEngine.GameObject, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineFail1()
	return self.petTimelineFail1, self.petTimelineFailDirector1, self.petTimelineFail1Vfx, self.petTimelineFailWrapper1
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.UnityEngine.GameObject, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineFail2()
	return self.petTimelineFail2, self.petTimelineFailDirector2, self.petTimelineFail2Vfx, self.petTimelineFailWrapper2
end

---@return CS.UnityEngine.GameObject, CS.UnityEngine.Playables.PlayableDirector, CS.UnityEngine.GameObject, CS.PlayableDirectorListenerWrapper
function PetCaptureModule:GetPetTimelineFail3()
	return self.petTimelineFail3, self.petTimelineFailDirector3, self.petTimelineFail3Vfx, self.petTimelineFailWrapper3
end

function PetCaptureModule:IsPetTimelineLoadComplete()
	return self.petTimelineLoadComplete
end

function PetCaptureModule:CheckPetTimelineLoadComplete()
	self.petTimelineLoadCount = self.petTimelineLoadCount + 1
	g_Logger.Log("Pet timeline load count: %s", self.petTimelineLoadCount)
	self.petTimelineLoadComplete = (self.petTimelineLoadCount >= PET_TIMELINE_COUNT)
end

function PetCaptureModule:Test()
    ---@type CatchPetResultMediatorParameter
    local param = {}
    param.result = wrpc.AutoCatchPetReward.New()
    local reward = wrpc.RewardPet.New()
    reward.PetCompId = 346
    reward.PetId = 1013
    reward.CostItemId = 70041
    param.result.RewardPets:Add(reward)

    reward = wrpc.RewardPet.New()
    reward.PetCompId = 339
    reward.PetId = 3001
    reward.CostItemId = 70041
    param.result.RewardPets:Add(reward)

    reward = wrpc.RewardPet.New()
    reward.PetCompId = 279
    reward.PetId = 3010
    reward.CostItemId = 70041
    param.result.RewardPets:Add(reward)

    reward = wrpc.RewardPet.New()
    reward.PetCompId = 275
    reward.PetId = 2018
    reward.CostItemId = 70041
    param.result.RewardPets:Add(reward)

    reward = wrpc.RewardPet.New()
    reward.PetCompId = 308
    reward.PetId = 1015
    reward.CostItemId = 70041
    param.result.RewardPets:Add(reward)

    g_Game.UIManager:Open(UIMediatorNames.CatchPetResultMediator, param)
end

return PetCaptureModule
