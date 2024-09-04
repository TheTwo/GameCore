local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityAreaRecoverModule:BaseModule
---@field taskToAreaMap table<number, CityZoneRecoverConfigCell> Task表id--CityZoneRecover
local CityAreaRecoverModule = class('CityAreaRecoverModule', BaseModule)

function CityAreaRecoverModule:OnRegister()
    self:InitTaskToAreaRecoverMap()
end

function CityAreaRecoverModule:OnRemove()
    self.taskToAreaMap = nil
end

function CityAreaRecoverModule:InitTaskToAreaRecoverMap()
    self.taskToAreaMap = {}
    for _, v in ConfigRefer.CityZoneRecover:pairs() do
        for i = 1, v:RecoverTasksLength() do
            local taskId = v:RecoverTasks(i)
            self.taskToAreaMap[taskId] = v
        end
    end
end

return CityAreaRecoverModule