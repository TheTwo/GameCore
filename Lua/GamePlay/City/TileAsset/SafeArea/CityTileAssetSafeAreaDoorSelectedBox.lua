local Utils = require("Utils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetSafeAreaDoorSelectedBox:CityTileAsset
---@field new fun():CityTileAssetSafeAreaDoorSelectedBox
---@field super CityTileAsset
local CityTileAssetSafeAreaDoorSelectedBox = class('CityTileAssetSafeAreaDoorSelectedBox', CityTileAsset)

function CityTileAssetSafeAreaDoorSelectedBox:ctor()
    CityTileAsset.ctor(self)
    self.allowSelected = true
    self._inShow = false
    ---@type CS.UnityEngine.GameObject
    self._selectedBoxDummy = nil
    ---@type MyCity
    self._city = nil
    ---@type RectDyadicMap
    self._containGris = nil
    self._dir = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle[]
    self._indicatorsYellow = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle[]
    self._indicatorsGreen = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goHelper = nil
    self._isTileFilled = false
end

function CityTileAssetSafeAreaDoorSelectedBox:OnTileViewInit()
    local tile = self.tileView.tile
    local city = tile:GetCity()
    if not city:IsMyCity() then
        return
    end
    self._city = city
    self._goHelper = city.createHelper
    local mgr = city.safeAreaWallMgr
    self._wallId = tile:GetCell():UniqueId()
    ---@type CitySafeAreaWallDoor
    local wallDoor = mgr.wallHashMap[self._wallId]
    self._containGris = wallDoor.gridMap
    self._dir = wallDoor.dir
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_SELECT_FILLED, Delegate.GetOrCreate(self, self.OnRangeIndicatorFill))
end

function CityTileAssetSafeAreaDoorSelectedBox:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_SELECT_FILLED, Delegate.GetOrCreate(self, self.OnRangeIndicatorFill))
    self:DestroyDummy()
end

function CityTileAssetSafeAreaDoorSelectedBox:SetSelected(select)
    CityTileAsset.SetSelected(self, select)
    if not self._city then
        return
    end
    self:SyncDummy()
end

function CityTileAssetSafeAreaDoorSelectedBox:Show()
    CityTileAsset.Show(self)
    self._inShow = true
    self:SyncDummy()
end

function CityTileAssetSafeAreaDoorSelectedBox:Hide()
    self._inShow = false
    self:SyncDummy()
    CityTileAsset.Hide(self)
end

function CityTileAssetSafeAreaDoorSelectedBox:SyncDummy()
    if not self._city then
        return
    end
    if self._inShow then
        if self.selected then
            self:CreateDummy()
        else
            self:DestroyDummy()
        end
    else
        self:DestroyDummy()
    end
end

function CityTileAssetSafeAreaDoorSelectedBox:CreateDummy()
    if Utils.IsNull(self._selectedBoxDummy) and self._containGris and self._containGris.count > 0 then
        if UNITY_EDITOR then
            self._selectedBoxDummy = CS.UnityEngine.GameObject("SafeAreaWallSelectedDummy")
        else
            self._selectedBoxDummy = CS.UnityEngine.GameObject()
        end
        local dummyTrans = self._selectedBoxDummy.transform
        local assetRoot = self.tileView:GetAssetAttachTrans(false)
        dummyTrans:SetParent(assetRoot, false)
        local prefabLoopYellow = ArtResourceUtils.GetItem(ArtResourceConsts.vfx_w_common_wall_loop_yellow)
        local prefabLoopGreen = ArtResourceUtils.GetItem(ArtResourceConsts.vfx_w_common_wall_loop_green)
        local showInFill = function() return self._isTileFilled end
        local showNotInFill = function() return not self._isTileFilled end
        local indicatorDir
        if self._dir == 12 then
            indicatorDir = CS.UnityEngine.Vector3(0,90,0)
        else
            indicatorDir = CS.UnityEngine.Vector3(0,0,0)
        end
        ---@type {x:number,y:number}
        local edgeGrid0
        ---@type {x:number,y:number}
        local edgeGrid1
        for x, y, _ in self._containGris:pairs() do
            if not edgeGrid0 then
                edgeGrid0 = {x=x, y = y}
            elseif self._dir == 12 then
                if y < edgeGrid0.y then
                    edgeGrid0.x = x
                    edgeGrid0.y = y
                end
            else
                if x < edgeGrid0.x then
                    edgeGrid0.x = x
                    edgeGrid0.y = y
                end
            end
            if not edgeGrid1 then
                edgeGrid1 = {x=x, y = y}
            elseif self._dir == 12 then
                if y > edgeGrid1.y then
                    edgeGrid1.x = x
                    edgeGrid1.y = y
                end
            else
                if x > edgeGrid1.x then
                    edgeGrid1.x = x
                    edgeGrid1.y = y
                end
            end
            local pos = self._city:GetCenterWorldPositionFromCoord(x, y, 1, 1)
            local go
            if UNITY_EDITOR then
                go = CS.UnityEngine.GameObject(string.format("x:%s,y:%s", x, y))
            else
                go = CS.UnityEngine.GameObject()
            end
            local goTrans = go.transform
            goTrans:SetParent(dummyTrans, false)
            goTrans.position = pos
            ---@type CS.UnityEngine.BoxCollider
            local collider = go:AddComponent(typeof(CS.UnityEngine.BoxCollider))
            collider.size = CS.UnityEngine.Vector3(1,2.8,1)
            collider.center = CS.UnityEngine.Vector3(0,1.4,0)
            self:DoCreateRangeIndicator(prefabLoopYellow, pos, dummyTrans, indicatorDir, showNotInFill, self._indicatorsYellow)
            self:DoCreateRangeIndicator(prefabLoopGreen, pos, dummyTrans, indicatorDir, showInFill, self._indicatorsGreen)
        end
        self:CreateRangeIndicatorEdgeYellow(edgeGrid0, edgeGrid1, dummyTrans, indicatorDir)
        self:CreateRangeIndicatorEdgeGreed(edgeGrid0, edgeGrid1, dummyTrans, indicatorDir)
        self:RefreshGoLayer(self._selectedBoxDummy, false)
    end
end

function CityTileAssetSafeAreaDoorSelectedBox:DestroyDummy()
    for i, v in pairs(self._indicatorsGreen) do
        v:Delete()
    end
    table.clear(self._indicatorsGreen)
    for i, v in pairs(self._indicatorsYellow) do
        v:Delete()
    end
    table.clear(self._indicatorsYellow)
    if Utils.IsNotNull(self._selectedBoxDummy) then
        CS.UnityEngine.Object.Destroy(self._selectedBoxDummy)
    end
    self._selectedBoxDummy = nil
end

function CityTileAssetSafeAreaDoorSelectedBox:OnRangeIndicatorFill(cityUid, wallId, isFill)
    if cityUid ~= self._city.uid or wallId ~= self._wallId then
        return
    end
    if self._isTileFilled == isFill then
        return
    end
    self._isTileFilled = isFill
    for _, v in pairs(self._indicatorsYellow) do
        local go = v.Asset
        if Utils.IsNotNull(go) then
            go:SetVisible(not isFill)
            if not isFill then
                go:SetLayerRecursively("City", false)
            end
        end
    end
    for _, v in pairs(self._indicatorsGreen) do
        local go = v.Asset
        if Utils.IsNotNull(go) then
            go:SetVisible(isFill)
            if isFill then
                go:SetLayerRecursively("City", false)
            end
        end
    end
end

function CityTileAssetSafeAreaDoorSelectedBox:DoCreateRangeIndicator(prefab, pos, parent ,dir, visibleFunc, handleArray)
    local handle = self._goHelper:Create(prefab, parent, function(go, _, _)
        if Utils.IsNotNull(go) then
            ---@type CS.UnityEngine.Transform
            local trans = go.transform
            trans.position = pos
            trans.localEulerAngles = dir
            go:SetVisible(visibleFunc())
            go:SetLayerRecursively("City", false)
        end
    end)
    table.insert(handleArray, handle)
end

function CityTileAssetSafeAreaDoorSelectedBox:CreateRangeIndicatorEdgeYellow(grid0, grid1, parent, dir)
    local prefab = ArtResourceUtils.GetItem(ArtResourceConsts.vfx_w_common_wall_top_yellow)
    local inShow = function() return not self._isTileFilled end
    local pos0,pos1
    if self._dir == 12 then
        pos0 = self._city:GetWorldPositionFromCoord(grid0.x + 0.5, grid0.y)
        pos1 = self._city:GetWorldPositionFromCoord(grid1.x + 0.5, grid1.y + 1)
    else
        pos0 = self._city:GetWorldPositionFromCoord(grid0.x, grid0.y + 0.5)
        pos1 = self._city:GetWorldPositionFromCoord(grid1.x + 1, grid1.y + 0.5)
    end
    self:DoCreateRangeIndicator(prefab, pos0, parent, dir, inShow, self._indicatorsYellow)
    self:DoCreateRangeIndicator(prefab, pos1, parent, dir, inShow, self._indicatorsYellow)
end

function CityTileAssetSafeAreaDoorSelectedBox:CreateRangeIndicatorEdgeGreed(grid0, grid1, parent, dir)
    local prefab = ArtResourceUtils.GetItem(ArtResourceConsts.vfx_w_common_wall_top_green)
    local inShow = function() return self._isTileFilled end
    local pos0,pos1
    if self._dir == 12 then
        pos0 = self._city:GetWorldPositionFromCoord(grid0.x + 0.5, grid0.y)
        pos1 = self._city:GetWorldPositionFromCoord(grid1.x + 0.5, grid1.y + 1)
    else
        pos0 = self._city:GetWorldPositionFromCoord(grid0.x, grid0.y + 0.5)
        pos1 = self._city:GetWorldPositionFromCoord(grid1.x + 1, grid1.y + 0.5)
    end
    self:DoCreateRangeIndicator(prefab, pos0, parent, dir, inShow, self._indicatorsGreen)
    self:DoCreateRangeIndicator(prefab, pos1, parent, dir, inShow, self._indicatorsGreen)
end

return CityTileAssetSafeAreaDoorSelectedBox