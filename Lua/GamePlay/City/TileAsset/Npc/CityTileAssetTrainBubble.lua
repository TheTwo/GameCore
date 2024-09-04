local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityTileAssetBubble = require("CityTileAssetBubble")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local FurniturePageDefine = require("FurniturePageDefine")
local CityWorkType = require("CityWorkType")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")

---@class CityTileAssetTrainBubble:CityTileAssetBubble
---@field new fun():CityTileAssetTrainBubble
---@field super CityTileAssetTrainBubble
local CityTileAssetTrainBubble = class('CityTileAssetTrainBubble', CityTileAssetBubble)

function CityTileAssetTrainBubble:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self._go = nil
    ---@type City3DBubbleTrain
    self._bubble = nil
end

function CityTileAssetTrainBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local cell = self.tileView.tile:GetCell()
    self.furnitureId = cell:UniqueId()
    self.configId = cell:ConfigId()
    self.workId = ModuleRefer.TrainingSoldierModule:GetWorkId(self.configId)
    self.itemArrays = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_SELECTED_CHANGED, Delegate.GetOrCreate(self, self.OnCityFurnitureSelectionChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.RefreshState))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.DoRefreshBubble))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.DoRefreshBubble))

    for i = 1, #self.itemArrays do
        ModuleRefer.InventoryModule:AddCountChangeListener(self.itemArrays[i].id, Delegate.GetOrCreate(self, self.DoRefreshBubble))
    end
end

function CityTileAssetTrainBubble:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    if self.trainTTrigger then
        self.trainTTrigger:SetOnTrigger(nil, nil, false)
    end
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_SELECTED_CHANGED, Delegate.GetOrCreate(self, self.OnCityFurnitureSelectionChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.RefreshState))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.DoRefreshBubble))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.DoRefreshBubble))

	if self.itemArrays then
		for i = 1, #self.itemArrays do
			ModuleRefer.InventoryModule:RemoveCountChangeListener(self.itemArrays[i].id, Delegate.GetOrCreate(self, self.DoRefreshBubble))
		end
	end
end

function CityTileAssetBubble:RefreshState(LvUpChangeMap)
    if LvUpChangeMap and LvUpChangeMap[self.furnitureId] then
        self:ForceRefresh()
    end
end

function CityTileAssetTrainBubble:OnCityFurnitureSelectionChanged(_, furnitureId)
    local hide = self.furnitureId == furnitureId
    if self.handle and hide then
        self:Hide()
    elseif not (self.handle or hide) then
        self:Show()
    end
end

function CityTileAssetTrainBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if self:ShouldShow() then
        return ManualResourceConst.ui3d_bubble_training
    end
    return string.Empty
end

function CityTileAssetTrainBubble:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end

    if not self:TrySetPosToMainAssetAnchor(go.transform, "holder_mid") then
        self:SetPosToTileWorldCenter(go)
    end

    local behaviour = go:GetLuaBehaviour("City3DBubbleTrain")
    if not behaviour or not behaviour.Instance then
        return
    end
    self._bubble = behaviour.Instance
    if not self._bubble then
        return
    end
    self.trainTTrigger = self._bubble.p_frame.gameObject:GetLuaBehaviour("CityTrigger").Instance
    local callback = function()
        return self:OnClick()
    end
    self.trainTTrigger:SetOnTrigger(callback, nil, true)
    self._go = go
    self:DoRefreshBubble()
end

function CityTileAssetTrainBubble:OnAssetUnload(go, fade)
    if self._bubble then
        self._bubble:ClearTimer()
        self._bubble = nil
    end
    CityTileAssetBubble.OnAssetUnload(self, go, fade)
end

function CityTileAssetTrainBubble:Refresh()
    local canShow = self:CheckCanShow()
    if not canShow then
        self:Hide()
        return
    end
    local shouldShow = self:ShouldShow()
    if not shouldShow then
        self:Hide()
    end
    if not self.handle then
        self:Show()
    elseif self._bubble then
        self:DoRefreshBubble()
    end
end

function CityTileAssetTrainBubble:ShouldShow()
    local castle = self.tileView.tile:GetCastleFurniture()
    local city = self.tileView.tile:GetCity()
    local workId = castle.WorkId
    if workId and workId > 0 then
        local workData = city.cityWorkManager:GetWorkData(workId)
        return ConfigRefer.CityWork:Find(workData.ConfigId):Type() ~= CityWorkType.FurnitureLevelUp
    end
    return true
end

function CityTileAssetTrainBubble:OnClick()
    -- local param = CityLegoBuildingUIParameter.new(self.tileView.tile:GetCity(), nil, self.furnitureId)
    -- g_Game.UIManager:Open('CityLegoBuildingUIMediator', param)
    return true
end


function CityTileAssetTrainBubble:DoRefreshBubble()
    if not self._bubble then
        return
    end
    self._bubble:RefreshState(self.furnitureId, self.configId)
end


return CityTileAssetTrainBubble
