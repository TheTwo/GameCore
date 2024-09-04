local Delegate = require("Delegate")
local SdkWrapper = require("SdkWrapper")

---@class StreamingVideoPlayHandle
---@field new fun(stream:string,canSkip:boolean):StreamingVideoPlayHandle
local StreamingVideoPlayHandle = class('StreamingVideoPlayHandle')

---@param stream string @url
---@param canSkip boolean
function StreamingVideoPlayHandle:ctor(stream, canSkip)
    self._stream = stream
    self._canSkip = canSkip
    
    self._callBack = nil
    self._ready = false
    self._isPlaying = false
    self._isComplete = false
end

function StreamingVideoPlayHandle:Prepare(playOnReady)
    self._playOnReady = playOnReady
    --if UNITY_EDITOR then
    --    self._handle = CS.StreamVideoPlayer.PlayStreamVideo(self._stream)
    --    self._handle:SetPrepareReady(Delegate.GetOrCreate(self, self.Prepared))
    --    self._handle:SetOnComplete(Delegate.GetOrCreate(self, self.Complete))
    --    self._handle:Prepare()
    --else
    --    self:Prepared()
    --end
    self:Prepared()
end

function StreamingVideoPlayHandle:Prepared()
    self._ready = true
    g_Game.PowerManager:BackupAndroidWindowFlags()
    if self._playOnReady then
        self:Play()
    end
end

function StreamingVideoPlayHandle:Play()
    if not self._ready then
        return false
    end
    if self._isPlaying then
        return true
    end
    g_Logger.TraceChannel(nil, "Play url:%s", self._stream)
    self._isPlaying = true
    if UNITY_EDITOR then
        --self._handle:Play()
        g_Logger.TraceChannel(nil, "Editor or Standalone has none impl for streaming video, Skip,url:%s", self._stream)
    --else
    --    local has,sdkStreamMedia = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkStreamMedia)
    --    if has then
    --        sdkStreamMedia:OpenVideo(self._stream, string.Empty, true, self._canSkip, Delegate.GetOrCreate(self, self.OnStreamCallback))
    --    else
    --        self:Stop()
    --        self:Complete()
    --    end
    end
    local has,sdkStreamMedia = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkStreamMedia)
    if has then
        sdkStreamMedia:OpenVideo(self._stream, string.Empty, true, self._canSkip, Delegate.GetOrCreate(self, self.OnStreamCallback))
    else
        self:Stop()
        self:Complete()
    end
    return true
end

function StreamingVideoPlayHandle:Stop()
    g_Logger.TraceChannel(nil, "Stop url:%s", self._stream)
    self._isPlaying = false
    self._playOnReady = false
    --if UNITY_EDITOR then
    --    if self._handle then
    --        self._handle:Stop()
    --    end
    --else
    --    local has,sdkStreamMedia = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkStreamMedia)
    --    if has then
    --        sdkStreamMedia:CloseVideo()
    --    end
    --end
    local has,sdkStreamMedia = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkStreamMedia)
    if has then
        sdkStreamMedia:CloseVideo()
    end
    g_Game.PowerManager:RestoreAndroidWindowFlags()
end

---@param onComplete fun(handle:StreamingVideoPlayHandle)
function StreamingVideoPlayHandle:SetOnComplete(onComplete)
    if self._isComplete and onComplete then
        onComplete(self)
    end
    self._callBack = onComplete
end

function StreamingVideoPlayHandle:Complete()
    if self._isComplete then
        return
    end
    g_Logger.TraceChannel(nil, "Complete url:%s", self._stream)
    self._isComplete = true
    local callback = self._callBack
    self._callBack = nil
    if callback then
        callback(self)
    end
end

---@param playResult CS.SdkAdapter.SdkModels.SdkStreamMedia.PlayResult
function StreamingVideoPlayHandle:OnStreamCallback(playResult)
    self:Stop()
    self:Complete()
end

return StreamingVideoPlayHandle