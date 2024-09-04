local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
---@class CityWorkData
---@field new fun():CityWorkData
local CityWorkData = class("CityWorkData")

function CityWorkData:ctor()
    self.id = 0
    self.workCfgId = 0
    ---@type CityWorkConfigCell
    self.workCfg = nil
    ---@type table<number, boolean>
    self.petIdMap = nil
end

---@param castleWork wds.CastleWork
function CityWorkData:UpdateFromCastleWork(id, castleWork)
    self.id = id
    self.workCfgId = castleWork.ConfigId or 0
    self.workCfg = ConfigRefer.CityWork:Find(self.workCfgId)
    self.targetId = castleWork.WorkTarget or 0
    self.petIdMap = {}
    for i, petId in ipairs(castleWork.WorkerIds) do
        self.petIdMap[petId] = true
    end
    self.realStartTime = castleWork.RealWorkStartTime.ServerSecond
end

function CityWorkData:GetName()
    if self.workCfg then
        return I18N.Get(self.workCfg:Name())
    end
    return ""
end

return CityWorkData