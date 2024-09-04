local CityManagerBase = require("CityManagerBase")
---@class CityElementResourceVfxPlayManager:CityManagerBase
---@field new fun():CityElementResourceVfxPlayManager
---@field playingVfx table<CityElementResourceVfxDatum, boolean>
---@field go2Leaf table<CS.UnityEngine.GameObject, QuadTreeLeaf>
local CityElementResourceVfxPlayManager = class("CityElementResourceVfxPlayManager", CityManagerBase)
local Utils = require("Utils")
local CityElementResourceVfxDatum = require("CityElementResourceVfxDatum")
local QuadTreeNode = require("QuadTreeNode")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local Rect = require("Rect")
local ManualResourceConst = require("ManualResourceConst")

function CityElementResourceVfxPlayManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self.nextPlayTime = nil
end

---@param city MyCity
function CityElementResourceVfxPlayManager:DoViewLoad()
    self.quadTree = QuadTreeNode.new(0, 0, self.city.gridConfig.cellsX, self.city.gridConfig.cellsY)
    self.go2Leaf = {}
    self.playingVfx = {}

    local cfgLength = ConfigRefer.CityConfig:CityRandGatherFxLength()
    self.min, self.max = 15, 30
    if cfgLength == 2 then
        self.min = ConfigRefer.CityConfig:CityRandGatherFx(1)
        self.max = ConfigRefer.CityConfig:CityRandGatherFx(2)
    end
    self.playTimes = math.max(1, ConfigRefer.CityConfig:CityRandGatherFxMaxPlayNum())
    self.nextPlayTimes = {}
    self:GenerateNextPlayTimes(self.playTimes)
    self.attachPoint = ConfigRefer.CityConfig:CityRandGatherFxGatherPoint()
    self.lifeTime = 3
    self.vfxName = ManualResourceConst.vfx_w_cai_ji_wu
    self.city.createHelper:WarmUp(self.vfxName, self.playTimes)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    return self:ViewLoadFinish()
end

function CityElementResourceVfxPlayManager:DoViewUnload()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    for handle, _ in pairs(self.playingVfx) do
        handle:Delete()
    end
    self.playingVfx = nil
    self.go2Leaf = nil
    self.quadTree = nil
    self.nextPlayTimes = nil
end

function CityElementResourceVfxPlayManager:GenerateNextPlayTimes(times)
    local i = times or 1
    while i > 0 do
        table.insert(self.nextPlayTimes, g_Game.Time.time + math.random(self.min, self.max))
        i = i - 1
    end
    table.sort(self.nextPlayTimes)
end

---@param go CS.UnityEngine.GameObject
---@param tile CityCellTile
function CityElementResourceVfxPlayManager:RegisterGameObj(go, tile)
    if Utils.IsNull(go) then return end

    local datum = CityElementResourceVfxDatum.new(self, go, tile)
    local leaf = datum:ToQuadLeaf()
    self.quadTree:Insert(leaf)
    self.go2Leaf[go] = leaf
end

function CityElementResourceVfxPlayManager:UnregisterGameObj(go)
    if Utils.IsNull(go) then return end

    if not self.go2Leaf then return end

    local leaf = self.go2Leaf[go]
    leaf.value:StopVfx()
    self.quadTree:Remove(leaf)
    self.go2Leaf[go] = nil
end

function CityElementResourceVfxPlayManager:OnSecondTick()
    local curTime = g_Game.Time.time
    if #self.nextPlayTimes == 0 then
        self:GenerateNextPlayTimes(self.playTimes)
        return
    end

    if curTime >= self.nextPlayTimes[1] then
        table.remove(self.nextPlayTimes, 1)
        self:GenerateNextPlayTimes()
        self:PlayVfx()
    end
end

function CityElementResourceVfxPlayManager:OnCameraLoaded(camera)
    self.camera = camera
end

function CityElementResourceVfxPlayManager:OnCameraUnload()
    self.camera = nil
end

function CityElementResourceVfxPlayManager:PlayVfx()
    local basicCamera = self.camera
    if not basicCamera then return end

    local camera = basicCamera.mainCamera
    local projection = CS.Grid.CameraUtils.CalculateFrustumProjectionOnPlane(camera, camera.nearClipPlane,
                camera.farClipPlane, basicCamera:GetBasePlane());
    local cameraBox = CS.Grid.CameraUtils.CalculateFrustumProjectionAABB(projection);
    local min, max = cameraBox.min, cameraBox.max
    local minX, minY = self.city:GetCoordFromPosition(min)
    local maxX, maxY = self.city:GetCoordFromPosition(max)

    local rect = Rect.new(minX, minY, maxX - minX + 1, maxY - minY + 1)
    local leafs = self.quadTree:Query(rect)
    for i = #leafs, 1, -1 do
        local leaf = leafs[i]
        if not leaf.value:InScreen() then
            table.remove(leafs, i)
        elseif leaf.value:IsFogMask() then
            table.remove(leafs, i)
        end
    end

    if #leafs == 0 then return end
    local idx = math.random(1, #leafs)
    local leaf = table.remove(leafs, idx)
    leaf.value:PlayVfx()
end

---@param handle CS.DragonReborn.VisualEffect.VisualEffectHandle
function CityElementResourceVfxPlayManager:MarkPlay(handle, flag)
    if flag then
        self.playingVfx[handle] = true
    else
        self.playingVfx[handle] = nil
    end
end

function CityElementResourceVfxPlayManager:NeedLoadView()
    return true
end

return CityElementResourceVfxPlayManager