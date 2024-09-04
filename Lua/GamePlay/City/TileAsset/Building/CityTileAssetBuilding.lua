local CityTileAssetPolluted = require("CityTileAssetPolluted")
---@class CityTileAssetBuilding:CityTileAssetPolluted
---@field new fun():CityTileAssetBuilding
---@field tileView CityTileViewBuildingBase
---@field cityTrigger CityTrigger
---@field super CityTileAssetPolluted
local CityTileAssetBuilding = class("CityTileAssetBuilding", CityTileAssetPolluted)
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local CityTilePriority = require("CityTilePriority")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")

function CityTileAssetBuilding:ctor()
    CityTileAssetPolluted.ctor(self)
    self.allowSelected = true
    self.syncLoaded = true
end

function CityTileAssetBuilding:GetPrefabName()
    if self:SkipForSLGAsset() then
        return string.Empty
    end

    local cell = self.tileView.tile:GetCell()
    local levelCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if levelCell == nil then
        g_Logger.Error(("找不到BuildingLevel表中Id为%d的行"):format(cell.configId))
        return string.Empty
    end

    local buildingInfo = self.tileView.tile:GetCastleBuildingInfo()
    if CityUtils.IsRepairing(buildingInfo.Status) then
        --- 如果当前处于待修复阶段，则显示上一级的资源，没有上一级就不显示
        levelCell = ModuleRefer.CityConstructionModule:GetPreLevelCell(levelCell)
    elseif CityUtils.IsStatusUpgrade(buildingInfo.Status) then
        --- 如果下一级没有要修复的东西，就直接显示下一级的资源
        local nextLvCell = ConfigRefer.BuildingLevel:Find(levelCell:NextLevel())
        if nextLvCell:UnlockBlocksLength() == 0 then
            levelCell = nextLvCell
        end
    end

    if levelCell == nil then
        return string.Empty
    end

    self.levelCell = levelCell
    local mdlId = levelCell:ModelArtRes()
    self.mdlId = mdlId
    return ArtResourceUtils.GetItem(mdlId)
end

function CityTileAssetBuilding:Hide()
    self.mdlId = nil
    self.levelCell = nil
    CityTileAssetPolluted.Hide(self)
end

function CityTileAssetBuilding:SkipForSLGAsset()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        local building = self:GetCity().buildingManager:GetBuilding(cell.tileId)
        return building.battleState
    end
    return false
end

function CityTileAssetBuilding:GetScale()
    return ArtResourceUtils.GetItem(self.mdlId, "ModelScale")
end

function CityTileAssetBuilding:Refresh()
    self:OnRoofStateChanged()
end

function CityTileAssetBuilding:OnAssetLoaded(go, userdata)
    if Utils.IsNotNull(go) then
        self:OnRoofStateChangedImp(self.tileView.tile:IsRoofHide(), go)
        self:OnWallHideChangedImp(self:GetCity().wallHide, go)

        local cell = self.tileView.tile:GetCell()
        local city = self:GetCity()
        local pos = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, self.levelCell:SizeX(), self.levelCell:SizeY())
        go.transform.position = pos

        local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
        if Utils.IsNotNull(collider) then
            local trigger = go:AddMissingLuaBehaviour("CityTrigger")
            self.cityTrigger = trigger.Instance
            self.cityTrigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self.tileView.tile, false)
            self.cityTrigger:SetOnPress(Delegate.GetOrCreate(self, self.OnPressDown), Delegate.GetOrCreate(self, self.OnPress), Delegate.GetOrCreate(self, self.OnPressUp))
        end
    end
    CityTileAssetPolluted.OnAssetLoaded(self, go, userdata)
end

function CityTileAssetBuilding:OnAssetUnload()
    if self.cityTrigger then
        self.cityTrigger:SetOnTrigger(nil, nil)
        self.cityTrigger:SetOnPress(nil, nil, nil)
        self.cityTrigger = nil
    end

    CityTileAssetPolluted.OnAssetUnload(self)
end

function CityTileAssetBuilding:OnClick()
    if self.tileView and self.tileView.tile then
        local city = self:GetCity()
        if city then
            if city.stateMachine.currentState.OnClickCellTile then
                city.stateMachine.currentState:OnClickCellTile(self.tileView.tile)
                return true
            end
        end
    end
end

function CityTileAssetBuilding:OnPressDown()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressDownCellTile then
        city.stateMachine.currentState:OnPressDownCellTile(self.tileView.tile)
    end
end

function CityTileAssetBuilding:OnPress()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressCellTile then
        city.stateMachine.currentState:OnPressCellTile(self.tileView.tile)
    end
end

function CityTileAssetBuilding:OnPressUp()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressUpCellTile then
        city.stateMachine.currentState:OnPressUpCellTile(self.tileView.tile)
    end
end

---@param flag boolean
---@param go CS.UnityEngine.GameObject
function CityTileAssetBuilding:OnRoofStateChanged(flag)
    if self.handle and self.handle.Asset then
        self:OnRoofStateChangedImp(self.tileView.tile:IsRoofHide(), self.handle.Asset)
    end
end

---@param flag boolean
---@param go CS.UnityEngine.GameObject
function CityTileAssetBuilding:OnRoofStateChangedImp(flag, go)
    go:SendMessage("RoofStateChange", flag, CS.UnityEngine.SendMessageOptions.DontRequireReceiver)
end

function CityTileAssetBuilding:GetPriorityInView()
    return CityTilePriority.BUILDING
end

function CityTileAssetBuilding:OnTileViewInit()
    CityTileAssetBuilding.super.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
end

function CityTileAssetBuilding:OnTileViewRelease()
    CityTileAssetBuilding.super.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
end

function CityTileAssetBuilding:OnSlgAssetUpdate(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeBuilding then return end

    local cell = self.tileView.tile:GetCell()
    if cell ~= nil and cell.tileId == id then
        self:ForceRefresh()
    end
end

function CityTileAssetBuilding:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    local building = self:GetCity().buildingManager:GetBuilding(cell.tileId)
    return building:IsPolluted()
end

function CityTileAssetBuilding:IsMine(buildingId)
    local cell = self.tileView.tile:GetCell()
    return cell.tileId == buildingId
end

function CityTileAssetBuilding:OnWallHideChanged(flag)
    if self.handle and self.handle.Asset then
        self:OnWallHideChangedImp(flag, self.handle.Asset)
    end
end

function CityTileAssetBuilding:OnWallHideChangedImp(flag, go)
    local comps = go:GetComponentsInChildren(typeof(CS.CityHideableWall), true)
    for i = 0, comps.Length - 1 do
        comps[i]:EditStateChange(flag)
    end
end

return CityTileAssetBuilding
