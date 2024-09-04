local BaseManager = require("BaseManager")

---@class VideoClipManager:BaseManager
---@field new fun():VideoClipManager
---@field super BaseManager
local VideoClipManager = class('VideoClipManager', BaseManager)

function VideoClipManager:ctor()
    ---@type CS.DragonReborn.AssetTool.VideoClipManager
    self.manager = CS.DragonReborn.AssetTool.VideoClipManager.Instance
    self.manager:OnGameInitialize(nil)
end

function VideoClipManager:Reset()
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
end

function VideoClipManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function VideoClipManager:LoadVideoClip(assetName)
    return self.manager:LoadVideoClip(assetName)
end

function VideoClipManager:UnloadVideoClip(assetName)
    self.manager:UnloadVideoClip(assetName)
end

return VideoClipManager