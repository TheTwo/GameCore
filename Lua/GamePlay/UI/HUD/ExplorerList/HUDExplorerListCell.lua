local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local HeroConfigCache = require("HeroConfigCache")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class HUDExplorerListCellParameter
---@field teamData CityExplorerTeamData
---@field explorers CityExplorerData[]
---@field onClick fun(teamData:CityExplorerTeamData)
---@field OnDragBegin fun(CS.UnityEngine.GameObject, CS.UnityEngine.PointerEventData)
---@field OnDragUpdate fun(CS.UnityEngine.GameObject, CS.UnityEngine.PointerEventData)
---@field OnDragEnd fun(CS.UnityEngine.GameObject, CS.UnityEngine.PointerEventData)

---@class HUDExplorerListCell:BaseTableViewProCell
---@field new fun():HUDExplorerListCell
---@field super BaseTableViewProCell
local HUDExplorerListCell = class('HUDExplorerListCell', BaseTableViewProCell)

function HUDExplorerListCell:ctor()
   self._onClick = nil 
end

function HUDExplorerListCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    ---@type HeroInfoItemComponent
    self._child_card_hero_s = self:LuaObject("child_card_hero_s")
    self._p_icon_status = self:Image("p_icon_status")
    self:DragEvent(""
        , Delegate.GetOrCreate(self, self.OnDragBegin) 
        , Delegate.GetOrCreate(self, self.OnDragUpdate) 
        , Delegate.GetOrCreate(self, self.OnDragEnd) 
        , false
    )
end

---@param data HUDExplorerListCellParameter
function HUDExplorerListCell:OnFeedData(data)
    self._teamData = data.teamData
    self._onClick = data.onClick
    self._onDragBegin = data.OnDragBegin
    self._onDragUpdate = data.OnDragUpdate
    self._onDragEnd = data.OnDragEnd
    local explorerData = data.explorers[1]
    local heroesConfigCell = ConfigRefer.Heroes:Find(explorerData.HeroConfigId)
    ---@type HeroInfoData
    local HeroInfoData = {}
    HeroInfoData.heroData = HeroConfigCache.New(heroesConfigCell)
    HeroInfoData.onClick = Delegate.GetOrCreate(self, self.OnClickSelf)
    self._child_card_hero_s:FeedData(HeroInfoData)
    g_Game.SpriteManager:LoadSprite(data.teamData:GetStatusIconAndBackground()[1], self._p_icon_status)
end

function HUDExplorerListCell:OnClickSelf()
    if self._onClick then
        self._onClick(self._teamData)
    end
end

function HUDExplorerListCell:OnDragBegin(go, event)
    if self._onDragBegin then
        self._onDragBegin(go, event)
    end
end

function HUDExplorerListCell:OnDragUpdate(go, event)
    if self._onDragUpdate then
        self._onDragUpdate(go, event)
    end
end

function HUDExplorerListCell:OnDragEnd(go, event)
    if self._onDragEnd then
        self._onDragEnd(go, event)
    end
end

return HUDExplorerListCell