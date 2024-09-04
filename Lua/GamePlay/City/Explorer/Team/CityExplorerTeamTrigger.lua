local Delegate = require("Delegate")
local Utils = require("Utils")
local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")

---@class CityExplorerTeamTrigger
---@field new fun():CityExplorerTeamTrigger
local CityExplorerTeamTrigger = sealedClass('CityExplorerTeamTrigger')

function CityExplorerTeamTrigger:ctor()
    ---@type CS.UnityEngine.GameObject
    self._asset = nil
    ---@type CityExplorerTeam
    self._team = nil
    self._isShow = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._handle = nil
    self._canClick = false
    self._pos = nil
    ---@type CS.UnityEngine.Transform
    self._selectRing = nil
    self._showSelected = false
    self._trigger = nil
    ---@type fun(trigger:CityExplorerTeamTrigger)
    self._onClick = nil
end

---@param team CityExplorerTeam
function CityExplorerTeamTrigger:Init(team)
    self._team = team
end

function CityExplorerTeamTrigger:Show()
    if self._isShow then
        return
    end
    self._isShow = true
    if self._asset then
        self._asset:SetVisible(true)
    elseif not self._handle then
        self._handle = self._team._mgr._goCreator:Create(ManualResourceConst.city_team_city_trigger, self._team._mgr.city.CityExploreRoot, Delegate.GetOrCreate(self, self.OnAssetLoaded))
    end
end

function CityExplorerTeamTrigger:Tick(dt)
    if not self._isShow then
        return
    end
    self._canClick = false
    if not self._team or not self._team:HasHero() then
        return
    end
    local p = self._team:GetPosition()
    if not p then
        return
    end
    self._pos = p
    if Utils.IsNotNull(self._asset) then
        self._asset.transform.position = self._pos
        self._canClick = true
    end
end

function CityExplorerTeamTrigger:Hide()
    if not self._isShow then
        return
    end
    self._isShow = false
    if self._asset then
        self._asset:SetVisible(false)
    end
end

function CityExplorerTeamTrigger:SetSelected(isSelected)
    self._showSelected = isSelected
    if Utils.IsNotNull(self._selectRing) then
        self._selectRing:SetVisible(self._showSelected)
    end
end

function CityExplorerTeamTrigger:Release()
    if self._trigger then
        self._trigger:SetOnTrigger()
    end
    self._trigger = nil
    self._onClick = nil
    if self._handle then
        self._handle:Delete()
    end
    self._handle = nil
end

---@param go CS.UnityEngine.GameObject
---@param userData any
function CityExplorerTeamTrigger:OnAssetLoaded(go, userData)
    if Utils.IsNull(go) then
        return
    end
    self._asset = go
    self._selectRing = go.transform:Find("selected_ring")
    local be = go:GetLuaBehaviourInChildren("CityTrigger", true)
    if Utils.IsNotNull(be) then
        self._trigger = be.Instance
        if self._trigger then
            self._trigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickTrigger),nil,nil,true)
            self._trigger:SetOnPress(Delegate.GetOrCreate(self, self.OnDragBegin), Delegate.GetOrCreate(self, self.OnDrag), Delegate.GetOrCreate(self, self.OnDragEnd))
        end
    end
    if self._pos then
        self._asset.transform.position = self._pos
    end
    self._asset:SetVisible(self._isShow)
    if Utils.IsNotNull(self._selectRing) then
        self._selectRing:SetVisible(self._showSelected)
    end
end

function CityExplorerTeamTrigger:SetOnClick(onClick)
    self._onClick = onClick
end

---@return boolean
function CityExplorerTeamTrigger:OnClickTrigger(trigger)
    if not self._onClick then return false end
    self._onClick(self)
    return true
end

function CityExplorerTeamTrigger:SetOnDrag(onDragBegin,onDrag,onDragEnd)
    self._onDragBegin = onDragBegin
    self._onDrag = onDrag
    self._onDragEnd = onDragEnd
end

function CityExplorerTeamTrigger:OnDragBegin()
    if self._onDragBegin then
        self._onDragBegin()
    end
end

function CityExplorerTeamTrigger:OnDrag()
    if self._onDrag then
        self._onDrag()
    end
end

function CityExplorerTeamTrigger:OnDragEnd()
    if self._onDragEnd then
        self._onDragEnd()
    end
end

return CityExplorerTeamTrigger

