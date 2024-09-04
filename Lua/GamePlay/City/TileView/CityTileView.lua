---@class CityTileView
---@field new fun():CityTileView
---@field assets CityTileAsset[]
---@field tile CityCellTile|CityFurnitureTile|CitySafeAreaWallDoorTile|CityGeneratingResTile
---@field gameObjs table<CityTileAsset, CS.UnityEngine.GameObject>
---@field OnRoofStateChanged fun(self:CityTileView, flag:boolean)
---@field OnWallHideChanged fun(self:CityTileView, flag:boolean)
local CityTileView = class("CityTileView")
local Utils = require("Utils")
local Ease = CS.DG.Tweening.Ease
local Blackboard = require("Blackboard")

CityTileView.Key = {
    MainAssetBounds = "MainAssetBounds"
}

function CityTileView:ctor()
    self.assets = {}
    self.mainAssets = {}
    self.blackboard = Blackboard.new()
    self.blackboardListeners = {}
    self.gameObjs = {}
    self.noneUiAssetCount = 0
    self.uiAssetCount = 0
    ---@type CS.UnityEngine.GameObject
    self.root = nil
    ---@type CS.UnityEngine.GameObject
    self.rotRoot = nil
    ---@type CS.UnityEngine.GameObject
    self.noneRotRoot = nil
    self.rootVisible = true
end

function CityTileView:Show()
    self.showed = true
    if self.root == nil then
        self.noneUiAssetCount = 0
        self.uiAssetCount = 0
        for _, v in pairs(self.assets) do
            if v.isUI then
                self.uiAssetCount = self.uiAssetCount + 1
            else
                self.noneUiAssetCount = self.noneUiAssetCount + 1
            end
        end
        self.root, self.rotRoot, self.noneRotRoot = self:CreateRoot()
        self.root:SetVisible(self.rootVisible)
    end

    for _, asset in pairs(self.assets) do
        asset:Show()
    end
end

function CityTileView:Hide()
    for _, asset in pairs(self.assets) do
        asset:Hide()
    end

    if self.destroyRootWhenHide then
        self:DestroyRoot(self.root)
        self.root = nil
        self.rotRoot = nil
        self.noneRotRoot = nil
    end
    self.showed = false
end

function CityTileView:SetTile(tile)
    self.tile = tile
    self.priority = self.tile:GetPriority()
    for _, asset in pairs(self.assets) do
        asset.priority = asset.priorityInView + self.priority
        asset:OnTileViewInit()
    end
end

function CityTileView:Release(force)
    local fadeOut = 0
    if self.showed then
        fadeOut = force and 0 or self:GetAssetsMaxFadeOutDuration()
        self:Hide()
    end
    if self.root then
        self:DestroyRoot(self.root, fadeOut)
        self.root = nil
    end
    for _, asset in pairs(self.assets) do
        asset:OnTileViewRelease()
        asset:SetView(nil)
    end
    self.priority = -100
    self.noneUiAssetCount = 0
    self.uiAssetCount = 0
    self.assets = nil
    self.blackboard = nil
    self.blackboardListeners = nil
end

---@param asset CityTileAsset
function CityTileView:AddAsset(asset)
    table.insert(self.assets, asset)
    asset:SetView(self)

    if self.tile then
        asset.priority = asset.priorityInView + self.priority
        asset:OnTileViewInit()
    end

    if self.showed then
        asset:Show()
    end

    return asset
end

---@param asset CityTileAsset
function CityTileView:AddMainAsset(asset)
    local ret = self:AddAsset(asset)
    if not self.mainAssets[asset] then
        self.mainAssets[asset] = asset
    end
    return ret
end

function CityTileView:RemoveAsset(asset)
    if asset == nil then return end
    table.removebyvalue(self.assets, asset)
    self.mainAssets[asset] = nil

    if self.showed then
        asset:Hide()
    end
    
    if self.tile then
        asset:OnTileViewRelease()
    end
    asset:SetView(nil)
end

function CityTileView:RemoveAllAssets()
    for i, asset in ipairs(self.assets) do
        self.mainAssets[asset] = nil

        if self.showed then
            asset:Hide()
        end
        
        if self.tile then
            asset:OnTileViewRelease()
        end
        asset:SetView(nil)
    end
    self.assets = {}
end

---@return table<CityTileAsset, CityTileAsset>
function CityTileView:GetMainAssets()
    return self.mainAssets
end

function CityTileView:Refresh(force)
    for _, asset in pairs(self.assets) do
        if force then
            asset:ForceRefresh()
        else
            if asset:IsLoaded() then
                asset:Refresh()
            end
        end
    end
end

---@param pos CS.UnityEngine.Vector3
function CityTileView:UpdatePosition(pos)
    if Utils.IsNotNull(self.root) then
        self.root.transform.position = pos
    end
    for _, asset in pairs(self.assets) do
        asset:UpdatePosition(pos)
    end
end

function CityTileView:SetPositionCenterAndRotation(pos, center, rot)
    self:UpdatePosition(pos)
    if Utils.IsNotNull(self.rotRoot) then
        self.rotRoot.transform:SetPositionAndRotation(center, rot)
    end
end

function CityTileView:MoveEase(offset)
    if Utils.IsNotNull(self.root) then
        local originScale = self.root.transform.localScale
        self.root.transform:DOScale(originScale * 0.8, 0.1):SetEase(Ease.OutQuad):OnComplete(function()
            self.root.transform:DOBlendableMoveBy(offset, 0.15, false):SetEase(Ease.OutQuad):OnUpdate(function()
                local pos = self.root.transform.position
                for _, asset in pairs(self.assets) do
                    asset:UpdatePosition(pos)
                end
            end)
            self.root.transform:DOScale(originScale, 0.1):SetEase(Ease.InQuad)
        end)
    end
end

function CityTileView:SetParent(trans)
    if self.root then
        self.root.transform:SetParent(trans)
    end
end

function CityTileView:ResetParent()
    if self.root then
        self.root.transform:SetParent(self.tile.gridView:GetRoot(self.tile))
    end
end

function CityTileView:CreateRoot()
    ---@type CS.UnityEngine.GameObject
    local root = CS.UnityEngine.GameObject(self:RootName())
    root.transform:SetParent(self.tile.gridView:GetRoot(self.tile))
    root.transform.position = self.tile:GetCity():GetWorldPositionFromCoord(self.tile.x, self.tile.y)-- {x = self.tile.x, 0, z = self.tile.y}
    root.transform.localScale = {x = 1, y = 1, z = 1}
    root:SetLayerRecursively("City")

    ---@type CS.UnityEngine.GameObject
    local rotRoot
    if self.noneUiAssetCount > 0 then
        rotRoot = CS.UnityEngine.GameObject("rot")
        rotRoot.transform:SetParent(root.transform)
        rotRoot.transform:SetPositionAndRotation(self.tile:GetCity():GetCenterWorldPositionFromCoord(self.tile.x, self.tile.y, self.tile:SizeX(), self.tile:SizeY()), self.tile:Quaternion())
        rotRoot.transform.localScale = CS.UnityEngine.Vector3.one
        rotRoot:SetLayerRecursively("City")
    end

    ---@type CS.UnityEngine.GameObject
    local noneRotRoot
    if self.uiAssetCount > 0 then
        noneRotRoot = CS.UnityEngine.GameObject("noneRot")
        noneRotRoot.transform:SetParent(root.transform)
        noneRotRoot.transform:SetPositionAndRotation(self.tile:GetCity():GetCenterWorldPositionFromCoord(self.tile.x, self.tile.y, self.tile:SizeX(), self.tile:SizeY()), CS.UnityEngine.Quaternion.identity)
        noneRotRoot.transform.localScale = CS.UnityEngine.Vector3.one
        noneRotRoot:SetLayerRecursively("City")
    end
    
    return root, rotRoot, noneRotRoot
end

function CityTileView:DestroyRoot(root, delay)
    CS.UnityEngine.Object.Destroy(root, delay)
end

function CityTileView:LocationToString()
    return ("X:%d Y:%d"):format(self.tile.x, self.tile.y)
end

function CityTileView:RootName()
    return ("%s%s"):format(self:ToString(), self:LocationToString())
end

function CityTileView:GetAssetAttachTrans(isUi)
    return isUi and self.noneRotRoot.transform or self.rotRoot.transform
end

function CityTileView:IsAllAssetsLoaded()
    for k, v in pairs(self.assets) do
        if not v:IsLoadedOrEmpty() then
            return false
        end
    end
    return true
end

function CityTileView:GetAllAssetsLoadCostTime()
    local ret = 0
    for k, v in pairs(self.assets) do
        if v:IsLoadedOrEmpty() then
            ret = ret + v.costTime
        end
    end
    return ret
end

function CityTileView:SetSelected(select)
    for k, v in pairs(self.assets) do
        v:SetSelected(select)
    end
end

function CityTileView:OnMoveBegin()
    for k, v in pairs(self.assets) do
        v:OnMoveBegin()
    end
end

function CityTileView:OnMoveEnd()
    for k, v in pairs(self.assets) do
        v:OnMoveEnd()
    end
end

function CityTileView:WriteBlackboard(key, value, force)
    if self.blackboard:Write(key, value, force) then
        local listeners = self.blackboardListeners[key]
        if listeners then
            for _, callback in pairs(listeners) do
                callback(key, value)
            end
        end
    end
end

function CityTileView:ReadBlackboard(key)
    local ret = self.blackboard:Read(key)
    return ret
end

function CityTileView:CleanBlackboard(key, fireEvent)
    local ret = self.blackboard:Read(key)
    if ret ~= nil then
        self.blackboard:Write(key, nil, true)
        if fireEvent then
            local listener = self.blackboardListeners[key]
            if listener then
                for _, callback in pairs(listener) do
                    callback(key, nil)
                end
            end
        end
    end
end

function CityTileView:AddBlackboardListener(key, callback)
    if not callback then return end
    if type(callback) ~= "function" then return end

    self.blackboardListeners[key] = self.blackboardListeners[key] or {}
    self.blackboardListeners[key][callback] = callback
end

function CityTileView:RemoveBlackboardListener(key, callback)
    if not callback then return end
    if type(callback) ~= "function" then return end

    if not self.blackboardListeners[key] then return end
    self.blackboardListeners[key][callback] = nil

    if next(self.blackboardListeners[key]) == nil then
        self.blackboardListeners[key] = nil
    end
end

function CityTileView:OnAssetLoaded(asset, go)
    self.gameObjs[asset] = go
    if asset and self.mainAssets[asset] then
        for _, v in pairs(self.assets) do
            if not self.mainAssets[v] then
                v:OnMainAssetLoaded(asset, go)
            end
        end
    end
end

function CityTileView:OnAssetUnload(asset)
    self.gameObjs[asset] = nil
    if asset and self.mainAssets[asset] then
        for _, v in pairs(self.assets) do
            if not self.mainAssets[v] then
                v:OnMainAssetUnloaded(asset)
            end
        end
    end
end

function CityTileView:GetAssetsMaxFadeOutDuration()
    local ret = 0
    for k, v in pairs(self.assets) do
        ret = math.max(v:GetFadeOutDuration(), ret)
    end
    return ret
end

function CityTileView:SetRootVisible(visible)
    self.rootVisible = visible
    if self.root then
        self.root:SetVisible(visible)
    end
end

function CityTileView:ToString()
    return ("[Showed:%s],[Root:%s],[Tile:%s]"):format(tostring(self.showed), tostring(self.root), tostring(self.tile))
end

return CityTileView