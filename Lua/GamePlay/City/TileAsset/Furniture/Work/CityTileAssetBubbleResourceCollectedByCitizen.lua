local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetBubbleResourceCollectedByCitizen:CityTileAssetBubble
---@field new fun():CityTileAssetBubbleResourceCollectedByCitizen
---@field _bubble City3DBubbleStandard
local CityTileAssetBubbleResourceCollectedByCitizen = class("CityTileAssetBubbleResourceCollectedByCitizen", CityTileAssetBubble)
local CityWorkType = require("CityWorkType")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local ConfigTimeUtility = require("ConfigTimeUtility")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

function CityTileAssetBubbleResourceCollectedByCitizen:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end
    return ManualResourceConst.ui3d_bubble_group
end

function CityTileAssetBubbleResourceCollectedByCitizen:CheckCanShow()
    return CityTileAssetBubble.CheckCanShow(self) and self:IsBeingGathering()
end

function CityTileAssetBubbleResourceCollectedByCitizen:IsBeingGathering()
    local cityWorkManager = self:GetCity().cityWorkManager
    local workId, _ = cityWorkManager:GetWorkDataByTargetIdAndWorkType(self.tileView.tile:GetCell().tileId, CityWorkType.ResourceCollect)
    self.workId = workId
    return self.workId ~= nil
end

function CityTileAssetBubbleResourceCollectedByCitizen:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_RESOURCE_UPDATE_COLLECTED_BUBBLE, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetBubbleResourceCollectedByCitizen:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_RESOURCE_UPDATE_COLLECTED_BUBBLE, Delegate.GetOrCreate(self, self.ForceRefresh))
    CityTileAssetBubble.OnTileViewRelease(self)
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetBubbleResourceCollectedByCitizen:OnAssetLoaded(go, userdata, handle)
    self._bubble = go:GetLuaBehaviour("City3DBubbleStandard").Instance
    self._bubble:Reset()

    local city = self:GetCity()
    local progress = self:GetProgress()
    local workData = city.cityWorkManager:GetWorkData(self.workId)
    local petId = next(workData.petIdMap)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    self._bubble:ShowProgress(progress, ArtResourceUtils.GetUIItem(petCfg:TinyIcon()))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetBubbleResourceCollectedByCitizen:OnAssetUnload()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    self._bubble = nil
end

function CityTileAssetBubbleResourceCollectedByCitizen:GetProgress()
    local elementId = self.tileView.tile:GetCell().tileId
    local city = self:GetCity()
    local progress = city.elementManager:GetResourceProcess(elementId)
    local element = city.elementManager:GetElementById(elementId)
    if element == nil then
        return 0
    end

    local resourceConfigCell = element.resourceConfigCell
    local singleTime = ConfigTimeUtility.NsToSeconds(resourceConfigCell:CollectTime())
    local fullTime = singleTime * resourceConfigCell:CollectCount()

    --- 资源完全没采过，还是满的
    if progress == nil then
        local workData = self:GetCity().cityWorkManager:GetWorkData(self.workId)
        local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        if now < workData.realStartTime then
            return 0
        else
            return math.clamp01((now - workData.realStartTime) / fullTime)
        end
    else
        local workData = self:GetCity().cityWorkManager:GetWorkData(self.workId)
        local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        if now < workData.realStartTime then
            return 0
        else
            local remainTime = (progress.LeftTimes - 1) * singleTime + math.max(0, (singleTime - progress.CurProgress))
            local gap = city:GetWorkTimeSyncGap(workData.realStartTime)
            local passTime = fullTime - remainTime + gap
            return math.clamp01(passTime / fullTime)
        end
    end
end

function CityTileAssetBubbleResourceCollectedByCitizen:OnTick()
    if self._bubble then 
        self._bubble:UpdateProgress(self:GetProgress())
    end
end

function CityTileAssetBubbleResourceCollectedByCitizen:ShowInSingleSeExplorerMode()
    return true
end

return CityTileAssetBubbleResourceCollectedByCitizen