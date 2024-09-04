local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local CityStateExplorerTeamSelect = require("CityStateExplorerTeamSelect")

local HUDExplorerListBaseMode = require("HUDExplorerListBaseMode")

---@class HUDExplorerListCityMode:HUDExplorerListBaseMode
---@field new fun():HUDExplorerListCityMode
---@field super HUDExplorerListBaseMode
local HUDExplorerListCityMode = class('HUDExplorerListCityMode', HUDExplorerListBaseMode)

function HUDExplorerListCityMode:ctor()
    HUDExplorerListBaseMode.ctor(self)
    self._teamReady = false
    ---@type MyCity
    self._city = nil
    ---@type CityExplorerManager
    self._explorerMgr = nil
    ---@type CityStateExplorerTeamSelect
    self._selectedState = nil
    self._teamStatusNeedTick = false
    self._dragDelayStart = false
end

function HUDExplorerListCityMode:Enter()
    HUDExplorerListBaseMode.Enter(self)
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_STATUES_UPDATE, Delegate.GetOrCreate(self, self.OnTeamDataChanged))
    self:Refresh()
end

function HUDExplorerListCityMode:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_STATUES_UPDATE, Delegate.GetOrCreate(self, self.OnTeamDataChanged))
    self:Reset()
    HUDExplorerListBaseMode.Exit(self)
end

function HUDExplorerListCityMode:Reset()
    self._teamReady = false
    self._city = nil
    self._explorerMgr = nil
    self._selectedState = nil
    self._teamStatusNeedTick = false
    self._dragDelayStart = false
end

function HUDExplorerListCityMode:Refresh()
    local lastTeamStatus = self._teamReady
    local lastSelectedStatus= self._selectedState
    self:Reset()
    local city,explorerMgr,teamData,explorers,team
    city = ModuleRefer.CityModule.myCity
    if not city then
       goto endOfRefresh 
    end
    explorerMgr = city.cityExplorerManager
    if not explorerMgr then
        goto endOfRefresh
    end
    teamData = explorerMgr._teamData
    if not teamData then
        goto endOfRefresh
    end
    explorers = explorerMgr._explorersData
    if not explorers or # explorers <= 0 then
        goto endOfRefresh
    end
    team = explorerMgr._team
    if not team then
        goto endOfRefresh
    end
    
    self._city = city
    self._explorerMgr = explorerMgr
    self._teamReady = true
    self:RefreshUI(teamData, explorers)
    
    ::endOfRefresh::
    
    self:CleanupIfTeamReadyChanged(lastTeamStatus, lastSelectedStatus)
end

---@param teamData CityExplorerTeamData
---@param explorer CityExplorerData[]
function HUDExplorerListCityMode:RefreshUI(teamData, explorer)
    self._host._p_icon_add:SetVisible(false)
    self._host._p_troop_status:SetVisible(true)
    self._host._p_img_hero:SetVisible(true)
    self._host._p_icon_explore_empty:SetVisible(false)
    self._host._p_icon_explore:SetVisible(true)
    
    local leaderData = explorer[1]
    local heroConfig = ConfigRefer.Heroes:Find(leaderData.HeroConfigId)
    local resData = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(resData:HeadMini()), self._host._p_img_hero)
    self:RefreshStatusIcon(teamData)
end

---@param teamData CityExplorerTeamData
function HUDExplorerListCityMode:RefreshStatusIcon(teamData)
    local iconAndBackground = teamData:GetStatusIconAndBackground()
    g_Game.SpriteManager:LoadSprite(iconAndBackground[1], self._host._p_icon_status)
    g_Game.SpriteManager:LoadSprite(iconAndBackground[2], self._host._p_troop_status)
end

---@param lastReadyStatus boolean
---@param lastSelectedState CityStateExplorerTeamSelect
function HUDExplorerListCityMode:CleanupIfTeamReadyChanged(lastReadyStatus, lastSelectedState)
    if lastReadyStatus and not self._teamReady then
        if lastSelectedState then
            lastSelectedState:ExitToIdleState()
        end
    end
    if not self._teamReady then
        self._host._p_icon_add:SetVisible(true)
        self._host._p_troop_status:SetVisible(false)
        self._host._p_img_hero:SetVisible(false)
        self._host._p_icon_explore_empty:SetVisible(true)
        self._host._p_icon_explore:SetVisible(false)
    end
end

function HUDExplorerListCityMode:OnTeamDataChanged(_)
    self:Refresh()
end

function HUDExplorerListCityMode:OnClick()
    if not self._teamReady then
        return
    end
    if not self._city then
        return
    end
    ---@type CityStateExplorerTeamSelect
    local currentState = self._city.stateMachine:GetCurrentState()
    if not currentState then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_SELECT, self._city.uid, true)
end

function HUDExplorerListCityMode:OnDragBegin(go, event)
    if not self._teamReady then
        return
    end
    if not self._city then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_SELECT, self._city.uid, false)
    ---@type CityStateExplorerTeamSelect
    local currentState = self._city.stateMachine:GetCurrentState()
    if not currentState then
        return
    end
    if not currentState:is(CityStateExplorerTeamSelect) then
        return
    end
    self._selectedState = currentState
    self._dragDelayStart = true
    --self._selectedState:OnDragStartExternal(event)
end

function HUDExplorerListCityMode:OnDragUpdate(go, event)
    if not self._selectedState then
        return
    end
    if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._host._p_btn_resident_rect, event.position) then
        return
    end
    if self._dragDelayStart then
        self._dragDelayStart = false
        self._selectedState:OnDragStartExternal(event)
    else
        self._selectedState:OnDragUpdate(event)
    end
end

function HUDExplorerListCityMode:OnDragEnd(go, event)
    self._dragDelayStart = false
    if not self._selectedState then
        return
    end
    self._selectedState:OnDragEnd(event)
    self._selectedState = nil
end

function HUDExplorerListCityMode:OnDragCancel(go)
    self._dragDelayStart = false
    if self._selectedState then
        self._selectedState:ExitToIdleState()
    end
    self._selectedState = nil
end

return HUDExplorerListCityMode