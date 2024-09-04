local CityStateDefault = require("CityStateDefault")
---@class CityStateLockedLegoSelected:CityStateDefault
---@field new fun():CityStateLockedLegoSelected
local CityStateLockedLegoSelected = class("CityStateLockedLegoSelected", CityStateDefault)

function CityStateLockedLegoSelected:Enter()
    ---@type CityLegoBuilding
    self.legoBuilding = self.stateMachine:ReadBlackboard("legoBuilding")
    ---@type NpcServiceConfigCell
    self.npcServiceCfg = self.stateMachine:ReadBlackboard("npcServiceCfg")

    if self.legoBuilding == nil then
        self:ExitToIdleState()
        return
    end

    self.legoBuilding:ShowLockedServiceBubble(self.npcServiceCfg)
end

function CityStateLockedLegoSelected:Exit()
    self.legoBuilding:HideLockedServiceBubble()
    self.legoBuilding = nil
    self.npcServiceCfg = nil
end

function CityStateLockedLegoSelected:OnClick(gesture)
    self:ExitToIdleState()
end

return CityStateLockedLegoSelected