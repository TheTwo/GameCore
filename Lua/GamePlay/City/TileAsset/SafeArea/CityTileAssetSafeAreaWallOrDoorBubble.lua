local Delegate = require("Delegate")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local I18N = require("I18N")
local CityBuildingRepairSafeAreaBlockDatum = require("CityBuildingRepairSafeAreaBlockDatum")

local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetSafeAreaWallOrDoorBubble:CityTileAssetBubble
---@field new fun():CityTileAssetSafeAreaWallOrDoorBubble
---@field super CityTileAssetBubble
local CityTileAssetSafeAreaWallOrDoorBubble = class('CityTileAssetSafeAreaWallOrDoorBubble', CityTileAssetBubble)

function CityTileAssetSafeAreaWallOrDoorBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    ---@type CityTileViewSafeAreaWall|CityTileViewSafeAreaDoor
    local tileView = self.tileView
    ---@type CitySafeAreaWallDoorTile
    local tile = tileView.tile
    self._city = tile:GetCity()
    self._castleBriefId = self._city.uid
    self._wallId = tile:GetCell():UniqueId()
    ---@type CityAbilityConfigCell
    self._requireAbilityConfig = nil
    self._requireAbilityType = nil
    self._requireAbilityLv = 0
    local config = ConfigRefer.CitySafeAreaWall:Find(tile:GetCell():ConfigId())
    if config and config:AbilityNeed() > 0 then
        local abilityConfig = ConfigRefer.CityAbility:Find(config:AbilityNeed())
        if abilityConfig then
            self._requireAbilityType = abilityConfig:Type()
            self._requireAbilityLv = abilityConfig:Level()
        end
    end
    self._isMyCity = self._city:IsMyCity()
    self._status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    self._isPolluted = ModuleRefer.CitySafeAreaModule:GetWallOrDoorIsPolluted(self._wallId)
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnCityAbilityChanged))
    self._abilityValid = self:DoCheckAbility()
end

function CityTileAssetSafeAreaWallOrDoorBubble:ShouldShow()
    return self._isMyCity and self._status == 1 and self._abilityValid
end

function CityTileAssetSafeAreaWallOrDoorBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_need)
end

function CityTileAssetSafeAreaWallOrDoorBubble:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnCityAbilityChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
end

function CityTileAssetSafeAreaWallOrDoorBubble:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end
    ---@type CitySafeAreaWallDoor
    local wallCell = self.tileView.tile:GetCell()
    local flag, coord = self:GetCity().safeAreaWallMgr:GetWallCenterGrid(wallCell.singleId)
    if flag then
        local pos = self:GetCity():GetCenterWorldPositionFromCoord(coord.x, coord.y, 1, 1)
        go.transform:SetPositionAndRotation(pos, CS.UnityEngine.Quaternion.identity)
    end
    self:OnBubbleLoaded(go)
end

function CityTileAssetSafeAreaWallOrDoorBubble:OnAssetUnload(go, fade)
    if self._bubble then
        self._bubble:SetOnTrigger(nil, nil, false)
    end
    self._bubble = nil
end

function CityTileAssetSafeAreaWallOrDoorBubble:OnBubbleLoaded(go)
    local luaBehaviour = go:GetLuaBehaviour("City3DBubbleNeed")
    ---@type City3DBubbleNeed
    local bubble = luaBehaviour.Instance
    bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnRepairClick), self.tileView.tile)
    self._bubble = bubble
    self:Refresh()
end

function CityTileAssetSafeAreaWallOrDoorBubble:Refresh()
    if self._bubble == nil then return end
    self._bubble:Reset():ShowDangerImg(self._isPolluted)
    local datum = CityBuildingRepairSafeAreaBlockDatum.new():Setup(self._city, self._wallId)
    for i, v in ipairs(datum:GetBubbleNeedData()) do
        self._bubble:AppendCustom(v.icon, v.text, v.showCheck)
    end
end

function CityTileAssetSafeAreaWallOrDoorBubble:OnWallStatusChanged(castleBriefId)
    if not self._isMyCity or not self._castleBriefId or self._castleBriefId ~= castleBriefId then
        return
    end
    self._isPolluted = ModuleRefer.CitySafeAreaModule:GetWallOrDoorIsPolluted(self._wallId)
    local status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    if status ~= self._status then
        self._status = status
        self:ForceRefresh()
    end
end

---@param entity wds.CastleBrief
---@param changedTable table
function CityTileAssetSafeAreaWallOrDoorBubble:OnCityAbilityChanged(entity, changedTable)
    if self._castleBriefId ~= entity.ID then
        return
    end
    self._abilityValid = self:DoCheckAbility()
    self:ForceRefresh()
end

function CityTileAssetSafeAreaWallOrDoorBubble:DoCheckAbility()
    if not self._requireAbilityType then
        return true
    end
    local castle = self._city:GetCastle()
    local lv = castle and castle.CastleAbility and castle.CastleAbility[self._requireAbilityType] or 0
    return lv >= self._requireAbilityLv
end

---@param index number
---@param item City3DBubbleNeedItem
function CityTileAssetSafeAreaWallOrDoorBubble:OnRepairClick(index, item)
    if self._isPolluted then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
        return
    end
    if not self._abilityValid then
        return
    end
    self.tileView.tile:GetCity():EnterRepairSafeAreaWallOrDoorState(self.tileView.tile.x,  self.tileView.tile.y)
end

return CityTileAssetSafeAreaWallOrDoorBubble