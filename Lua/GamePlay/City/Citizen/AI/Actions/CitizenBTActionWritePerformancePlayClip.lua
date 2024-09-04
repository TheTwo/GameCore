local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionWritePerformancePlayClip:CitizenBTActionNode
---@field new fun():CitizenBTActionWritePerformancePlayClip
---@field super CitizenBTActionNode
local CitizenBTActionWritePerformancePlayClip = class('CitizenBTActionWritePerformancePlayClip', CitizenBTActionNode)

function CitizenBTActionWritePerformancePlayClip:InitFromConfig(config)
    self._clipName = config:StringParamLength() > 0 and config:StringParam(1) or nil
    self._soundId = config:IntParamLength() > 0 and config:IntParam(1) or 0
    self._leftTime = config:FloatParamLength() > 0 and config:FloatParam(1) or nil
end

function CitizenBTActionWritePerformancePlayClip:Run(context, gContext)
    if string.IsNullOrEmpty(self._clipName) then
        return false
    end 
    ---@type CitizenBTActionPlayClipContextParam
    local param = {}
    param.clipName = self._clipName
    param.soundId = self._soundId
    param.leftTime = self._leftTime
    param.dumpStr = CitizenBTDefine.DumpWorkInfo
    context:Write(CitizenBTDefine.ContextKey.PlayClipInfo, param)
    return CitizenBTActionWritePerformancePlayClip.super.Run(self, context, gContext)
end

return CitizenBTActionWritePerformancePlayClip