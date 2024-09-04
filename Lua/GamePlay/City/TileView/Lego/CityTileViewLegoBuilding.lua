local CityTileView = require("CityTileView")
---@class CityTileViewLegoBuilding:CityTileView
---@field new fun():CityTileViewLegoBuilding
local CityTileViewLegoBuilding = class("CityTileViewLegoBuilding", CityTileView)

function CityTileViewLegoBuilding:ctor(id)
    CityTileView.ctor(self)
    self.id = id
end

function CityTileViewLegoBuilding:CreateRoot()
    ---@type CS.UnityEngine.GameObject
    local root = CS.UnityEngine.GameObject(self:RootName())
    root.transform:SetParent(self.tile.gridView:GetRoot(self.tile))
    root.transform.position = self.tile:GetCity():GetWorldPositionFromCoord(self.tile.x, self.tile.y)-- {x = self.tile.x, 0, z = self.tile.y}
    root.transform.localScale = {x = 1, y = 1, z = 1}
    root:SetLayerRecursively("City")

    ---@type CS.UnityEngine.GameObject
    local rotRoot
    rotRoot = CS.UnityEngine.GameObject("rot")
    rotRoot.transform:SetParent(root.transform)
    rotRoot.transform:SetPositionAndRotation(self.tile:GetCity():GetCenterWorldPositionFromCoord(self.tile.x, self.tile.y, self.tile:SizeX(), self.tile:SizeY()), self.tile:Quaternion())
    rotRoot.transform.localScale = CS.UnityEngine.Vector3.one
    rotRoot:SetLayerRecursively("City")

    ---@type CS.UnityEngine.GameObject
    local noneRotRoot
    noneRotRoot = CS.UnityEngine.GameObject("noneRot")
    noneRotRoot.transform:SetParent(root.transform)
    noneRotRoot.transform:SetPositionAndRotation(self.tile:GetCity():GetCenterWorldPositionFromCoord(self.tile.x, self.tile.y, self.tile:SizeX(), self.tile:SizeY()), CS.UnityEngine.Quaternion.identity)
    noneRotRoot.transform.localScale = CS.UnityEngine.Vector3.one
    noneRotRoot:SetLayerRecursively("City")
    
    return root, rotRoot, noneRotRoot
end

function CityTileViewLegoBuilding:GetAssetAttachTrans(isUi)
    return isUi and self.noneRotRoot.transform or self.root.transform
end

function CityTileViewLegoBuilding:OnRoofStateChanged(hideRoof)
    for _, asset in ipairs(self.assets) do
        if asset.OnRoofStateChanged then
            asset:OnRoofStateChanged(hideRoof)
        end
    end
end

function CityTileViewLegoBuilding:OnWallHideChanged(hideWall)
    for _, asset in ipairs(self.assets) do
        if asset.OnWallHideChanged then
            asset:OnWallHideChanged(hideWall)
        end
    end
end

function CityTileViewLegoBuilding:ToString()
    return ("[LegoBuilding: id:%d]"):format(self.id)
end

return CityTileViewLegoBuilding