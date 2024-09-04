---@class CityTileAsset
---@field new fun():CityTileAsset
---@field createHelper CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@field asset CS.UnityEngine.GameObject
---@field handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
---@field need number 需要加载的资源数量
---@field loaded number 已加载的资源数量
---@field isUI boolean 是否是3DUI
local CityTileAsset = class("CityTileAsset")
local Utils = require("Utils")
local Delegate = require("Delegate")
local CityUtils = require("CityUtils")

function CityTileAsset:ctor()
    self.need = 0
    self.loaded = 0
    self.startTime = 0
    self.costTime = 0
    self.allowSelected = false
    self.selected = false
    self.isUI = false
    self.syncLoaded = false
    self.priorityInView = self:GetPriorityInView()
    self.priority = self.priorityInView
end

---@param view CityTileView
function CityTileAsset:SetView(view)
    self.tileView = view
end

function CityTileAsset:GetCreateHelper()
    return self.tileView.tile.gridView.createHelper
end

---@return boolean 返回是否发起了异步加载
function CityTileAsset:Show()
    local prefabName = self:GetPrefabName()
    if string.IsNullOrEmpty(prefabName) then
        self.need = 0
        return
    end

    if self.handle then
        return
    end

    self.need, self.loaded = 1, 0
    self.startTime = g_Game.Time.realtimeSinceStartup
    self.prefabName = prefabName
    self.tileView.tile.gridView:EnqueueLoad(self)
end

function CityTileAsset:Hide()
    if self.handle then
        local fadeOut = math.max(0, self:GetFadeOutDuration())
        if self.handle.Loaded and self.loaded > 0 then
            self.tileView.tile.gridView:MarkUnload(self)
            self:OnAssetUnload(self.handle.Asset, fadeOut)
            self.tileView:OnAssetUnload(self)
        end
        local createHelper = self:GetCreateHelper()
        if fadeOut > 0 then
            createHelper:Delete(self.handle, fadeOut)
        else
            createHelper:Delete(self.handle)
        end
        self.handle = nil
    else
        self.tileView.tile.gridView:DequeueLoad(self)
    end
    self.need, self.loaded = 0, 0
    self.startTime, self.costTime = 0, 0
    self.prefabName = nil
end

function CityTileAsset:IsLoadedOrEmpty()
    return self.need == self.loaded
end

function CityTileAsset:IsLoaded()
    return self.need == self.loaded and self.loaded > 0
end

function CityTileAsset:OnAssetLoadedProcess(go, userdata, handle)
    if Utils.IsNull(go) then
        self.need = 0
        g_Logger.ErrorChannel("CityTileAsset", ("load %s failed, this asset is %s"):format(self.prefabName, self.__cname))
        self.tileView.tile.gridView:MarkFailed(self)
        return
    end

    self.loaded = 1
    -- self.costTime = g_Game.Time.realtimeSinceStartup - self.startTime
    -- g_Logger.LogChannel("City", ("load %s succeed, cost %.2f ms"):format(name, self.costTime * 1000))
    self:RefreshGoLayer(go, true)
    self:ResizeModel(go)
    self.tileView.tile.gridView:MarkLoaded(self)
    self:OnAssetLoaded(go, userdata, handle)
    self.tileView:OnAssetLoaded(self, go)
end

function CityTileAsset:SetSelected(select)
    if not self.allowSelected then
        return
    end

    self.selected = select
    if self.handle and self.handle.Asset and Utils.IsNotNull(self.handle.Asset) then
        self:RefreshGoLayer(self.handle.Asset, false)
    end
end

function CityTileAsset:RefreshGoLayer(go, ignoreLayerKeeper)
    if self.selected then
        go:SetLayerRecursively("Selected", ignoreLayerKeeper)
    elseif self.isUI then
        go:SetLayerRecursively("Scene3DUI", ignoreLayerKeeper)
    else
        go:SetLayerRecursively("City", ignoreLayerKeeper)
    end
end

function CityTileAsset:ResizeModel(go)
    local scale = self:GetScale()
    if scale == 1 or scale <= 0 then return end

    go.transform.localScale = CS.UnityEngine.Vector3.one * scale
end

---@param trigger CityTrigger
function CityTileAsset:OnClickCellTile(trigger)
    if self.tileView and self.tileView.tile then
        local city = self:GetCity()
        if city then
            if city.stateMachine.currentState.OnClickCellTile then
                city.stateMachine.currentState:OnClickCellTile(self.tileView.tile)
                return true
            end
        end
    end
    return false
end

---@param cell CityGridCell
---@param go CS.UnityEngine.GameObject
---@return CS.UnityEngine.Vector3 @localPosition
function CityTileAsset.SuggestBubblePosition(cell, go)
    local up = go.transform.up
    local offset = math.max(cell.sizeX, cell.sizeY)
    return up * offset
end

---@param city City
---@param cell CityGridCell
---@param useCenterGridEdge boolean
---@return CS.UnityEngine.Vector3 @wordPosition
function CityTileAsset.SuggestCellCenterPositionWithHeight(city, cell, height, useCenterGridEdge)
    return CityUtils.SuggestCellCenterPositionWithHeight(city, cell, height, useCenterGridEdge)
end

function CityTileAsset:ForceRefresh()
    local prefabName = self:GetPrefabName()
    if prefabName == (self.prefabName or "") then
        if self:IsLoaded() then
            self:Refresh()
        end
    else
        self:Hide()
        self:Show()
    end
end

---@return City|MyCity
function CityTileAsset:GetCity()
    return self.tileView.tile:GetCity()
end

---@param trans CS.UnityEngine.Transform
function CityTileAsset:TrySetPosToMainAssetAnchor(trans, attachPoint)
    if string.IsNullOrEmpty(attachPoint) then
        attachPoint = 'holder_3dui'
    end
    local mainAssets = self.tileView:GetMainAssets()
    for asset, _ in pairs(mainAssets) do
        local mainGo = self.tileView.gameObjs[asset]
        if Utils.IsNotNull(mainGo) then
            local comp = mainGo:GetComponent(typeof(CS.FXAttachPointHolder))
            if Utils.IsNotNull(comp) then
                local anchorTrans = comp:GetAttachPoint(attachPoint)
                if Utils.IsNotNull(anchorTrans) then
                    trans.position = anchorTrans.position
                    return true
                end
            end
        end
    end
    return false
end

---@param go CS.UnityEngine.GameObject
function CityTileAsset:SetPosToTileWorldCenter(go)
    local cell = self.tileView.tile:GetCell()
    local position = self:GetCity():GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    go.transform.position = position
end

function CityTileAsset:TryGetAnchorPos(anchorName)
    anchorName = anchorName or 'holder_3dui'
    local mainAssets = self.tileView:GetMainAssets()
    for asset, _ in pairs(mainAssets) do
        local mainGo = self.tileView.gameObjs[asset]
        if Utils.IsNotNull(mainGo) then
            local comp = mainGo:GetComponent(typeof(CS.FXAttachPointHolder))
            if Utils.IsNotNull(comp) then
                local anchorTrans = comp:GetAttachPoint(anchorName)
                if Utils.IsNotNull(anchorTrans) then
                    return true, anchorTrans.position, anchorTrans
                end
            end
        end
    end
    local cell = self.tileView.tile:GetCell()
    local position = self:GetCity():GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    return false, position
end

function CityTileAsset:Refresh()
    --- override this function
end

---@return string
function CityTileAsset:GetPrefabName()
    --- override this function
end

---@return number
function CityTileAsset:GetScale()
    --- override this function
    return 1
end

function CityTileAsset:OnTileViewInit()
    ---override this function
end

function CityTileAsset:OnTileViewRelease()
    ---override this function
end

---@return number
function CityTileAsset:GetPriorityInView()
    ---override this function
    return 0
end

---@return number
function CityTileAsset:GetFadeOutDuration()
    ---override this function
    return 0
end

---@param go CS.UnityEngine.GameObject
function CityTileAsset:OnAssetLoaded(go, userdata, handle)
    ---override this function
end

---@param go CS.UnityEngine.GameObject
---@param fade number
function CityTileAsset:OnAssetUnload(go, fade)
    ---override this function
end

---@param pos CS.UnityEngine.Vector3
function CityTileAsset:UpdatePosition(pos)
    ---override this function
end

function CityTileAsset:OnMoveBegin()

end

function CityTileAsset:OnMoveEnd()

end

function CityTileAsset:MustLoad()
    --- override this to skip wait
    return true
end

function CityTileAsset:LoadNecessary()
    return self:MustLoad() and 1 or 0
end

---@param mainAsset CityTileAsset
---@param go CS.UnityEngine.GameObject
function CityTileAsset:OnMainAssetLoaded(mainAsset, go)
    ---override this
end

---@param mainAsset CityTileAsset
function CityTileAsset:OnMainAssetUnloaded(mainAsset)
    ---override this
end

function CityTileAsset:ToString()
    return GetClassName(self)
end

return CityTileAsset