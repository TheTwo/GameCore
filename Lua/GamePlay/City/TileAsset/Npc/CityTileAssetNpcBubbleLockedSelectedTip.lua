local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityConst = require("CityConst")
local ManualResourceConst = require("ManualResourceConst")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")
local CityFurnitureBuildingEntryBubble = require("CityFurnitureBuildingEntryBubble")
local UIMediatorNames = require("UIMediatorNames")
local NpcServiceObjectType = require("NpcServiceObjectType")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcBubbleLockedSelectedTip:CityTileAsset
---@field new fun():CityTileAssetNpcBubbleLockedSelectedTip
---@field super CityTileAsset
local CityTileAssetNpcBubbleLockedSelectedTip = class('CityTileAssetNpcBubbleLockedSelectedTip', CityTileAsset)

function CityTileAssetNpcBubbleLockedSelectedTip:ctor()
    CityTileAsset:ctor(self)
    self.isUI = true
    self._allowShow = false
    ---@type MyCity
    self._city = nil
    ---@type number|nil
    self._elementId = nil
    ---@type number|nil
    self._playerId = nil
    ---@type CityFurnitureBuildingEntryBubble
    self._bubble = nil
    ---@type CityElementNpcConfigCell
    self._npcConfig = nil
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnTileViewInit()
    self._city = self.tileView.tile:GetCity()
    self._elementId = self.tileView.tile:GetCell():ConfigId()
    self._playerId = self._city:IsMyCity() and ModuleRefer.PlayerModule:GetPlayerId() or 0
    self._allowShow = self:ShouldShow()
    if self._allowShow then
        self._npcConfig = ConfigRefer.CityElementNpc:Find(ConfigRefer.CityElementData:Find(self._elementId):ElementId())
    end
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECTED, Delegate.GetOrCreate(self, self.OnNpcSelected))
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECTED, Delegate.GetOrCreate(self, self.OnNpcSelected))
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
end

function CityTileAssetNpcBubbleLockedSelectedTip:GetPrefabName()
    if not self._allowShow then
        return string.Empty
    end
    if not self._city.stateMachine:IsCurrentState(CityConst.STATE_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECT) then
        return string.Empty
    end
    ---@type CityStateLockedNpcSelected
    local state = self._city.stateMachine:GetCurrentState()
    if not state.cellTile or state.cellTile:GetCell():ConfigId() ~= self._elementId then
        return string.Empty
    end
    -- return string.Empty
    return ManualResourceConst.ui3d_bubble_entrance_building
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnAssetLoaded(go, userdata)
    CityTileAsset.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end

    if not self:TrySetPosToMainAssetAnchor(go.transform) then
        self:SetPosToTileWorldCenter(go)
    end
    local b = go:GetLuaBehaviour("CityFurnitureBuildingEntryBubble")
    self._bubble = b and b.Instance and b.Instance:is(CityFurnitureBuildingEntryBubble) and b.Instance
    if self._bubble then
        self._bubble:ChangeStatusToNPC()
            :SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCellBubble), self.tileView.tile)
            :SetName(self._npcConfig and I18N.Get(self._npcConfig:Name()) or '')
    end

    local tile = self.tileView.tile
    TimerUtility.DelayExecuteInFrame(function()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LOCKED_NONE_SHOWN_NPC_ENTRY_BUBBLE_LOADED, tile)
    end, 2)
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnAssetUnload(go, fade)
    if self._bubble then
        self._bubble:Clear()
        self._bubble:SetOnTrigger(nil, nil)
    end
    self._bubble = nil
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnClickCellBubble()
    g_Game.UIManager:Open(UIMediatorNames.UIRaisePowerPopupMediator, self._city.cityExplorerManager:BuildNpcLockedTaskGotoParam(self._elementId))
    return true
end

---@param entity wds.Player
function CityTileAssetNpcBubbleLockedSelectedTip:OnNpcServiceChanged(entity, changedData)
    if entity.ID ~= self._playerId or not changedData then
        return
    end
    for npcId, _ in pairs(changedData) do
        if npcId == self._elementId then
            local allowShow = self:ShouldShow()
            if self._allowShow ~= allowShow then
                self._allowShow = allowShow
                self:Refresh()
            end
            return
        end
    end
end

function CityTileAssetNpcBubbleLockedSelectedTip:OnNpcSelected(city, elementId)
    if not self._allowShow or self._city ~= city then
        return
    end
    local canShow = self._elementId == elementId
    if self.handle and not canShow then
        self:Hide()
    elseif not self.handle and canShow then
        self:Show()
    end
end

function CityTileAssetNpcBubbleLockedSelectedTip:ShouldShow()
    if not self._city:IsMyCity() then
        return false
    end
    local npcServiceList = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[self._elementId]
    if not npcServiceList or table.isNilOrZeroNums(npcServiceList.Services) then
        return false
    end
    local NpcService = ConfigRefer.NpcService
    for serviceId, vStruct in pairs(npcServiceList.Services) do
        local v = vStruct.State
        if wds.NpcServiceState.NpcServiceStateFinished == v then
            goto continue
        end
        if v ~= wds.NpcServiceState.NpcServiceStateBeLocked then
            return false
        end
        local cfg = NpcService:Find(serviceId)
        if not cfg or cfg:IsShowLockService() then
            return false
        end
        ::continue::
    end
    return true
end

function CityTileAssetNpcBubbleLockedSelectedTip:IsNpcBubble()
    return true
end

return CityTileAssetNpcBubbleLockedSelectedTip