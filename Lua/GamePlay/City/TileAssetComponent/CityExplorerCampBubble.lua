local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@class CityExplorerCampBubble
---@field new fun():CityExplorerCampBubble
---@field root CS.UnityEngine.Transform
local CityExplorerCampBubble = class('CityExplorerCampBubble')

---@param param CityGridCell
function CityExplorerCampBubble:Init(param)
    self._buildingId = param.tileId
    self._uid = ModuleRefer.CityModule.myCity.uid
    self.root.localPosition = self.root.up * (math.max(param.sizeX, param.sizeY))
    self:Refresh()
end

function CityExplorerCampBubble:OnEnable()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.InCityInfo.Explorers.MsgPath, Delegate.GetOrCreate(self, self.OnExplorerDataChanged))
    self:Refresh()
end

function CityExplorerCampBubble:OnDisable()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.InCityInfo.Explorers.MsgPath, Delegate.GetOrCreate(self, self.OnExplorerDataChanged))
end

---@param entity wds.CastleBrief
---@param changedData table
function CityExplorerCampBubble:OnExplorerDataChanged(entity,  changedData)
    if entity.ID ~= self._uid then
        return
    end
    self:Refresh()
end

function CityExplorerCampBubble:Refresh()
    local show = true
    if self._buildingId then
        local player = ModuleRefer.PlayerModule:GetPlayer()
        if player then
            local info = player.Castle.InCityInfo.Explorers
            if info[self._buildingId] then
                show = false
            end
        end
    end
    self.root.gameObject:SetVisible(show)
end

function CityExplorerCampBubble:OnClickBubble()
    if not self._buildingId then
        return
    end
    g_Game.UIManager:Open("CityExplorerUIMediator", self._buildingId)
end

return CityExplorerCampBubble