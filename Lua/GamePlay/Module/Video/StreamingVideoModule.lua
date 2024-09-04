local StreamingVideoPlayHandle = require("StreamingVideoPlayHandle")

local BaseModule = require("BaseModule")

---@class StreamingVideoModule:BaseModule
---@field new fun():StreamingVideoModule
---@field super BaseModule
local StreamingVideoModule = class('StreamingVideoModule', BaseModule)

function StreamingVideoModule:ctor()
    self._isPlaying = false
end

function StreamingVideoModule:OnRegister()
    
end

function StreamingVideoModule:OnRemove()
    
end

---@param videoName string
---@param canSkip boolean
---@return StreamingVideoPlayHandle
function StreamingVideoModule:CreatePlayHandle(videoName, canSkip)
    self:InitOnce()
    return StreamingVideoPlayHandle.new(videoName, canSkip)
end

---@param videoName string
---@param canSkip boolean
---@param onComplete fun(handle:StreamingVideoPlayHandle)
---@return StreamingVideoPlayHandle
function StreamingVideoModule:Play(videoName, canSkip, onComplete)
    local ret = self:CreatePlayHandle(videoName, canSkip)
    ret:SetOnComplete(onComplete)
    ret:Prepare(true)
    return ret
end

---@private
function StreamingVideoModule:InitOnce()
    
end

return StreamingVideoModule