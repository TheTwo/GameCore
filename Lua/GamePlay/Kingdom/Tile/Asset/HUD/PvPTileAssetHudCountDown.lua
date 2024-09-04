local PvPTileAssetHud = require("PvPTileAssetHud")
local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")


---@class PvPTileAssetHudCountDown :PvPTileAssetHud
---@field behavior MapProgressBar
---@field finished boolean
local PvPTileAssetHudCountDown = class("PvPTileAssetHudCountDown", PvPTileAssetHud)

function PvPTileAssetHudCountDown:GetLodPrefab(lod)
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return string.Empty
    end
    if not KingdomMapUtils.InMapNormalLod(lod) then
        return string.Empty
    end
    return ManualResourceConst.ui3d_bubble_map_progress
end

function PvPTileAssetHudCountDown:CanShow()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return false
    end

    local progress, timeStr = self:UpdateProgress(entity)
    self.finished = progress >= 1
    return not self.finished or self:CanShowReward(entity)
end

function PvPTileAssetHudCountDown:OnShow()
    g_Game.EventManager:AddListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelect))
    g_Game.EventManager:AddListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselect))
end

function PvPTileAssetHudCountDown:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelect))
    g_Game.EventManager:RemoveListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselect))
end

function PvPTileAssetHudCountDown:OnSelect(entity)
    if not entity then
        return
    end

    local entityId = self.view:GetUniqueId()
    local entityType = self.view:GetTypeId()
    if entityId == entity.ID and entityType == entity.TypeHash then
        self:Refresh()
    end
end

function PvPTileAssetHudCountDown:OnUnselect(entity)
    if not entity then
        return
    end
    local entityId = self.view:GetUniqueId()
    local entityType = self.view:GetTypeId()
    if entityId == entity.ID or entityType == entity.TypeHash then
        self:Refresh()
    end
end

function PvPTileAssetHudCountDown:OnConstructionSetup()
    PvPTileAssetHudCountDown.super.OnConstructionSetup(self)

    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    self.behavior = self.root:GetLuaBehaviour("MapProgressBar").Instance
    self:SecondTick()

    if KingdomMapUtils.IsMapEntitySelected(self.view:GetUniqueId()) or self.finished and self:CanShowReward(entity) then
        self:ShowBigBubble(entity)
    else
        self:ShowMiniBubble(entity)
    end
    
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
end

function PvPTileAssetHudCountDown:OnConstructionShutdown()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
    self.finished = false

    PvPTileAssetHudCountDown.super.OnConstructionShutdown(self)
end

function PvPTileAssetHudCountDown:OnConstructionUpdate()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    self:SecondTick()
    if KingdomMapUtils.IsMapEntitySelected(self.view:GetUniqueId()) or self.finished and self:CanShowReward(entity) then
        self:ShowBigBubble(entity)
    else
        self:ShowMiniBubble(entity)
    end
end

function PvPTileAssetHudCountDown:SecondTick()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    if Utils.IsNull(self.behavior) then
        return
    end

    local progress, timeStr = self:UpdateProgress(entity)
    self.finished = progress >= 1
    if not self.finished then
        self.behavior:ShowProgress(true)
        self.behavior:UpdateProgress(progress)
        self.behavior:UpdateTime(timeStr)
        self.behavior:UpdateIcon(self:GetNormalIcon(entity))
        self.behavior:ShowHighlightVfx(false)
    elseif self:CanShowReward(entity) then
        self.behavior:ShowProgress(false)
        self.behavior:UpdateTime(string.Empty)
        self.behavior:UpdateIcon(self:GetClaimIcon(entity))
        self.behavior:EnableTrigger(true)
        self.behavior:SetTrigger(Delegate.GetOrCreate(self, self.OnClaimReward))
        self.behavior:ShowHighlightVfx(true)
        self:ShowBigBubble(entity)
    end
end

function PvPTileAssetHudCountDown:ShowBigBubble(entity)
    self.behavior:UseSmallState(false)
    self.behavior:DisplayRedBar(false)
    self.behavior:HideDesc()
end

function PvPTileAssetHudCountDown:ShowMiniBubble(entity)
    self.behavior:UseSmallState(true)
    self.behavior:DisplayRedBar(false)
    self.behavior:HideDesc()
end

---behavior implementation

function PvPTileAssetHudCountDown:GetNormalIcon(entity)
end

function PvPTileAssetHudCountDown:GetClaimIcon(entity)
end

function PvPTileAssetHudCountDown:UpdateProgress(entity)
    return 1, string.Empty
end

function PvPTileAssetHudCountDown:CanShowReward(entity)
end

function PvPTileAssetHudCountDown:OnClaimReward()
end

return PvPTileAssetHudCountDown