local Delegate = require("Delegate")
local EventConst = require("EventConst")
local I18N = require("I18N")
local Utils = require("Utils")
local CityFurnitureBuildingEntryBubble = require("CityFurnitureBuildingEntryBubble")
local CityFurnitureDecorationBubble = require("CityFurnitureDecorationBubble")
local ConfigRefer = require("ConfigRefer")
local CityCitizenDefine = require("CityCitizenDefine")
local CityConst = require("CityConst")
local CityFurnitureFunctionCollection = require("CityFurnitureFunctionCollection")
local TimerUtility = require("TimerUtility")
local ManualResourceConst = require("ManualResourceConst")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetFurnitureBuildingEntry:CityTileAsset
---@field new fun():CityTileAssetFurnitureBuildingEntry
---@field super CityTileAsset
local CityTileAssetFurnitureBuildingEntry = class('CityTileAssetFurnitureBuildingEntry', CityTileAsset)

function CityTileAssetFurnitureBuildingEntry:ctor()
    CityTileAsset.ctor(self)
    self.isUI = true
    ---@type CityFurnitureBuildingEntryBubble|CityFurnitureDecorationBubble
    self._bubble = nil
    self._furnitureConfig = nil
    self._furnitureTypeConfig = nil
end

function CityTileAssetFurnitureBuildingEntry:OnTileViewInit()
    self._furnitureConfig = nil
    self._furnitureTypeConfig = nil
    local cell = self.tileView.tile:GetCell()
    self._furnitureId = cell:UniqueId()
    self._city = self.tileView.tile:GetCity()
    self._cityUid = self._city.uid
    local furniture =  self.tileView.tile:GetCastleFurniture()
    if furniture then
        self._furnitureConfig = ConfigRefer.CityFurnitureLevel:Find(furniture.ConfigId)
        self._furnitureTypeConfig = self._furnitureConfig and ConfigRefer.CityFurnitureTypes:Find(self._furnitureConfig:Type())
    end
    self._allowShow = self:ShouldShow()
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_SELECTED_CHANGED, Delegate.GetOrCreate(self, self.OnCityFurnitureSelectionChanged))
end

function CityTileAssetFurnitureBuildingEntry:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_SELECTED_CHANGED, Delegate.GetOrCreate(self, self.OnCityFurnitureSelectionChanged))
end

function CityTileAssetFurnitureBuildingEntry:OnRoofStateChanged(roofHide)
    if not self.tileView then return end
    if not self.tileView.tile then return end
    if not self.tileView.tile:IsInner() then return end
    if not roofHide then
        self:Hide()
    else
        self:Show()
    end
end

function CityTileAssetFurnitureBuildingEntry:ShouldShow()
    return false
end

function CityTileAssetFurnitureBuildingEntry:GetPrefabName()
    if not self._allowShow then
        return string.Empty
    end
    if self._city.stateMachine:IsCurrentState(CityConst.STATE_FURNITURE_SELECT) then
        ---@type CityStateFurnitureSelect
        local state = self._city.stateMachine:GetCurrentState()
        if not state.cellTile or state.cellTile:GetCell():UniqueId() ~= self._furnitureId then
            return string.Empty
        end
    else
        return string.Empty
    end
    if self.tileView.tile:IsInner() and not self:GetCity().roofHide then
        return string.Empty
    end
    local typ = self._furnitureConfig:Type()
    if CityCitizenDefine.IsSpecialFunctionFurniture(typ) or CityCitizenDefine.IsMilitaryFurniture(typ) then
        return ManualResourceConst.ui3d_bubble_entrance_building
    end
    if CityCitizenDefine.IsDecorationFurniture(typ) or CityCitizenDefine.IsFurnitureWallOrDoor(typ) then
        if string.IsNullOrEmpty(self._furnitureTypeConfig:Description()) or string.IsNullOrEmpty(self._furnitureTypeConfig:Name()) then
            return string.Empty
        end
        return ManualResourceConst.ui3d_tips_building
    end
    return string.Empty
end

function CityTileAssetFurnitureBuildingEntry:OnAssetLoaded(go, userdata)
    CityTileAsset.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end

    if not self:TrySetPosToMainAssetAnchor(go.transform) then
        self:SetPosToTileWorldCenter(go)
    end

    local type = self._furnitureConfig:Type()
    if CityCitizenDefine.IsSpecialFunctionFurniture(type) then
        local b = go:GetLuaBehaviour("CityFurnitureBuildingEntryBubble")
        self._bubble = b and b.Instance and b.Instance:is(CityFurnitureBuildingEntryBubble) and b.Instance
        if self._bubble then
            self._bubble:ChangeStatusToBuilding()
                    :SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCellBubble), self.tileView.tile)
                    :SetLv(self._furnitureConfig:Level())
                    :SetName(self._furnitureTypeConfig and I18N.Get(self._furnitureTypeConfig:Name()) or '')
                    :SetBuildingBtnText(I18N.Get("goto"))
        end
    end
    if CityCitizenDefine.IsMilitaryFurniture(type) then
        local b = go:GetLuaBehaviour("CityFurnitureBuildingEntryBubble")
        self._bubble = b and b.Instance and b.Instance:is(CityFurnitureBuildingEntryBubble) and b.Instance
        if self._bubble then
            self._bubble:ChangeStatusToMilitary()
                :SetOnTrigger(nil, nil)
                :SetLv(self._furnitureConfig:Level())
                :SetName(self._furnitureTypeConfig and I18N.Get(self._furnitureTypeConfig:Name()) or '')
        end
    end
    if CityCitizenDefine.IsDecorationFurniture(type) or CityCitizenDefine.IsFurnitureWallOrDoor(type) then
        local b = go:GetLuaBehaviour("CityFurnitureDecorationBubble")
        self._bubble = b and b.Instance and b.Instance:is(CityFurnitureDecorationBubble) and b.Instance
        if self._bubble then
            self._bubble:SetOnTrigger(nil, nil)
            self._bubble:SetupFurniture(self._furnitureTypeConfig)
        end
    end
    
    local tile = self.tileView.tile
    TimerUtility.DelayExecuteInFrame(function()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_ENTRY_BUBBLE_LOADED, tile)
    end, 2)
end

function CityTileAssetFurnitureBuildingEntry:OnAssetUnload(go, fade)
    if self._bubble then
        self._bubble:Clear()
        self._bubble:SetOnTrigger(nil, nil)
    end
end

function CityTileAssetFurnitureBuildingEntry:OnCityFurnitureSelectionChanged(city, furnitureId)
    if self._cityUid ~= city.uid or not self._allowShow then
        return
    end
    local canShow = self._furnitureId == furnitureId
    if self.handle and not canShow then
        self:Hide()
    elseif not self.handle and canShow then
        self:Show()
    end
end

function CityTileAssetFurnitureBuildingEntry:OnClickCellBubble()
    local itemGenerator = CityFurnitureFunctionCollection[self._furnitureConfig:Type()]
    if not itemGenerator then
        return false
    end
    local item = itemGenerator(self.tileView.tile, self._furnitureTypeConfig, self._furnitureConfig, self.tileView.tile:GetCastleFurniture())
    if item and item.onClick then
        item:onClick()
        return true
    end
end

function CityTileAssetFurnitureBuildingEntry:OnMainAssetLoaded(asset, go)
    if self.tileView.gameObjs[self] then
        self:OnAssetLoaded(self.tileView.gameObjs[self], nil)
    end
end

return CityTileAssetFurnitureBuildingEntry