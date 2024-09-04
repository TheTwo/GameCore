---@class CityStaticObjectTile 静态物只需简单的剪裁系统干预, 因此将CityTileBase/TileView/TileAsset三个类的主要功能集于一体
---@field new fun(gridView, x, y, sizeX, sizeY, prefabName, cameraSize):CityStaticObjectTile
local CityStaticObjectTile = class("CityStaticObjectTile")
local Utils = require("Utils")
local CityTileAsset = require("CityTileAsset")
local Rect = require("Rect")

---@param gridView CityGridView
function CityStaticObjectTile:ctor(gridView, x, y, sizeX, sizeY, prefabName, cameraSize)
    self.gridView = gridView
    self.x = x
    self.y = y
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.prefabName = prefabName
    self.cameraSize = cameraSize or 50
    self.priority = 0

    self.tileView = self
    self.tile = self
    self.syncLoaded = false
    self.showed = false
end

function CityStaticObjectTile:SizeX()
    return self.sizeX
end

function CityStaticObjectTile:SizeY()
    return self.sizeY
end

function CityStaticObjectTile:Show()
    if self.showed then return end
    self.showed = true
    self.need, self.loaded = 1, 0
    self.gridView:EnqueueLoad(self)
end

function CityStaticObjectTile:Hide()
    if not self.showed then return end
    self.showed = false
    if self.handle then
        if self.handle.Loaded and self.loaded > 0 then
            self.gridView:MarkUnload(self)
        end
        self.handle:Delete()
        self.handle = nil
    else
        self.gridView:DequeueLoad(self)
    end
    self.need, self.loaded = 0, 0
end

function CityStaticObjectTile:Release(force)
    self:Hide()
end

function CityStaticObjectTile:GetAssetAttachTrans()
    return self.gridView:GetRoot(self)
end

function CityStaticObjectTile:GetCell()
    return self
end

function CityStaticObjectTile:IsLoadedOrEmpty()
    return self.need == self.loaded
end

function CityStaticObjectTile:OnAssetLoadedProcess(go, userdata)
    if Utils.IsNull(go) then
        self.need = 0
        g_Logger.ErrorChannel("CityStaticObjectTile", ("load %s failed, this asset is %s"):format(self.prefabName, self.__cname))
        self.gridView:MarkFailed(self)
        return
    end

    self.loaded = 1
    -- self.costTime = g_Game.Time.realtimeSinceStartup - self.startTime
    CityTileAsset.RefreshGoLayer(self, go, true)
    self.gridView:MarkLoaded(self)
    local position = self.gridView.city:GetCenterWorldPositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
    go.transform.position = position
    self:OnAssetLoaded(go, userdata)
end

function CityStaticObjectTile:OnAssetLoaded(go, userdata)
    ---override this
end

function CityStaticObjectTile:OnAssetUnload()
    ---override this
end

function CityStaticObjectTile:LoadNecessary()
    return 0
end

function CityStaticObjectTile:GetPriority()
    return 0
end

function CityStaticObjectTile:IsPolluted()
    return false
end

function CityStaticObjectTile:BlockTriggerExecute()
    return false
end

function CityStaticObjectTile:GetRect()
    return Rect.new(self.x, self.y, 1, 1)
end

return CityStaticObjectTile