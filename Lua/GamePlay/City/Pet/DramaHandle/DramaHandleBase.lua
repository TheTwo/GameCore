---@class DramaHandleBase
---@field new fun():DramaHandleBase
local DramaHandleBase = class("DramaHandleBase")
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityWorkType = require("CityWorkType")
local PetWorkType = require("PetWorkType")
local ManualResourceConst = require("ManualResourceConst")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

---@param petUnit CityUnitPet
function DramaHandleBase:ctor(petUnit, furnitureId)
    self.petUnit = petUnit
    self.furnitureId = furnitureId
    self.ignoreStrictMovingSpeedUp = false
end

function DramaHandleBase:Start()
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_MAIN_ASSET_LOADED, Delegate.GetOrCreate(self, self.OnAssetLoadedImp))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_MAIN_ASSET_UNLOAD, Delegate.GetOrCreate(self, self.OnAssetUnloadImp))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnMovingFurnitureEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnBatchMovingFurnitureImpl))
end

function DramaHandleBase:Tick(dt)
    ---override this
end

function DramaHandleBase:End()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_MAIN_ASSET_LOADED, Delegate.GetOrCreate(self, self.OnAssetLoadedImp))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_MAIN_ASSET_UNLOAD, Delegate.GetOrCreate(self, self.OnAssetUnloadImp))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnMovingFurnitureEnd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnBatchMovingFurnitureImpl))
end

function DramaHandleBase:OnAssetLoadedImp(furnitureId, go)
    if furnitureId ~= self.furnitureId then return end
    self:OnAssetLoaded(go)
end

function DramaHandleBase:OnAssetUnloadImp(furnitureId)
    if furnitureId ~= self.furnitureId then return end
    self:OnAssetUnload()
end

---@param city City
---@param idMap table<number, CityFurniture>
function DramaHandleBase:OnMovingFurnitureEnd(city, _,_,_,_,furnitureId,_,_)
    if not city or not city:IsMyCity() then return end
    if self.furnitureId ~= furnitureId then return end
    self:OnFurnitureMoved()
end

---@param city City
---@param idMap table<number, CityFurniture>
function DramaHandleBase:OnBatchMovingFurnitureImpl(city, map , idMap)
    if not city or not city:IsMyCity() then return end
    if not idMap[self.furnitureId] then return end
    self:OnFurnitureMoved()
end

---@param go CS.UnityEngine.GameObject
function DramaHandleBase:OnAssetLoaded(go)
    ---override this
end

function DramaHandleBase:OnAssetUnload()
    ---override this
end

function DramaHandleBase:OnFurnitureMoved()
    if not self.petUnit then return end
    self.petUnit:SyncFromServer()
end

---@param go CS.UnityEngine.GameObject
function DramaHandleBase:PrepareAsset(go)
    ---override this
end

function DramaHandleBase:GetTargetPosition()
    return CS.UnityEngine.Vector3.zero, CS.UnityEngine.Quaternion.identity
end

function DramaHandleBase:GetTargetPositionWithPetCenterFix()
    local workPos, dir = self:GetTargetPosition()
    local p = self.petUnit:GetWorkPosWithCenterOffsetFix(workPos, dir) or workPos
    return p, dir
end

function DramaHandleBase:Initialize()
    local city = self.petUnit:GetManager().city
    local furniture = city.furnitureManager:GetFurnitureById(self.furnitureId)
    local furnitureTile = city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local tileView = furnitureTile.tileView
    if tileView then
        for asset, _ in pairs(tileView:GetMainAssets()) do
            local go = tileView.gameObjs[asset]
            if Utils.IsNotNull(go) then
                self:PrepareAsset(go)
                break
            end
        end
    end
end

function DramaHandleBase:GetWorkCfgAnimName()
    local workData = self.petUnit:GetManager().city.cityWorkManager:GetWorkData(self.petUnit.petData.workId)
    if workData == nil then
        return CityPetAnimStateDefine.Idle
    end

    local workAnim = workData.workCfg:PetWorkAnim()
    if string.IsNullOrEmpty(workAnim) then
        return CityPetAnimStateDefine.Idle
    end
    return workAnim
end

function DramaHandleBase:GetResModleAttachUnit()
    local city = self.petUnit:GetManager().city
    local workData = city.cityWorkManager:GetWorkData(self.petUnit.petData.workId)
    if workData == nil then
        return string.Empty,1
    end
    local resGen = ConfigRefer.CityWorkProduceResource:Find(workData.workCfg:ResProduceCfg())
    if not resGen then
        return string.Empty,1
    end
    local ret,scale = ArtResourceUtils.GetItemAndScale(resGen:ResOutputModle())
    if string.IsNullOrEmpty(ret) then
        return string.Empty,1
    end
    if scale <= 0 then scale = 1 end
    return ret,scale
end

function DramaHandleBase:CheckAndAddPoint(arrayTable, ...)
    local args = { ... }
    for i = 1, #args do
        if Utils.IsNotNull(args[i]) then
            table.insert(arrayTable, args[i])
        end
    end
end

function DramaHandleBase:SetIgnoreStrictMovingSpeedUp(value)
    self.ignoreStrictMovingSpeedUp = value
end

---@param targetPos CS.UnityEngine.Vector3
function DramaHandleBase:HasSuggestMoveRemainTime(runTime, walkTime, targetPos, runSpeed, walkSpeed)
    if not self.ignoreStrictMovingSpeedUp then return false, runTime end
    return true, walkTime
end

return DramaHandleBase