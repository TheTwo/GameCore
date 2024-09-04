local EmptyStep = require("EmptyStep")
---@class MoveStep:EmptyStep
---@field new fun():MoveStep
local MoveStep = class("MoveStep", EmptyStep)
local ModuleRefer = require("ModuleRefer")

function MoveStep:ctor(x, z)
    self.x, self.z = x, z
    self.city = ModuleRefer.CityModule:GetMyCity()
end

function MoveStep:TryExecuted(lastReturn)
    local unit = self.city.citySeManger:GetCurrentCameraFocusOnHero(0)
    if not unit then return false end

    local pos = unit:GetActor():GetPosition()
    if not pos then return false end

    local mapInfo = self.city.citySeManger._seEnvironment:GetMapInfo()
    if not mapInfo then return false end
    
    local logicPos = mapInfo:ClientPos2Server(CS.UnityEngine.Vector3(pos.x, 0, pos.z))
    local distance = math.sqrt((self.x - logicPos.x) ^ 2 + (self.z - logicPos.y) ^ 2)
    if distance < 4 then return true end

    local param = require("MoveStepParameter").new()
    param.args.DestPoint.X = self.x
    param.args.DestPoint.Y = self.z
    param:Send()
    return false
end

return MoveStep