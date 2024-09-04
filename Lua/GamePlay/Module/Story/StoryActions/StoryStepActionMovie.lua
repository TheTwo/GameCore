local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local MovieSourceType = require("MovieSourceType")
local UIMediatorNames = require("UIMediatorNames")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionMovie:StoryStepActionBase
---@field new fun():StoryStepActionMovie
---@field super StoryStepActionBase
local StoryStepActionMovie = class('StoryStepActionMovie', StoryStepActionBase)

function StoryStepActionMovie:ctor()
    StoryStepActionMovie.super.ctor(self)
    self._handle = nil
    self._stream = 0
    self._mediatorRuntimeId = nil
    self._originBgmVolume = nil
end

function StoryStepActionMovie:LoadConfig(actionParam)
    StoryStepActionMovie.super.LoadConfig(self, actionParam)
    self._stream = tonumber(actionParam)
end

function StoryStepActionMovie:OnEnter()
    if not self._stream then
        g_Logger.Error("nil stream config")
        self:SetEndStatus(false)
        return
    end
    local movieConfig = ConfigRefer.Movie:Find(self._stream)
    if not movieConfig then
        g_Logger.Error("nil movieConfig:%s", self._stream)
        self:SetEndStatus(false)
        return
    end
    self._originBgmVolume = g_Game.SoundManager:GetBgmVolume()
    g_Game.SoundManager:SetBgmVolume(0)
    if movieConfig:SrcType() == MovieSourceType.Web then
        ---@type StreamingVideoModule
        local StreamingVideoModule = g_Game.ModuleManager:RetrieveModule("StreamingVideoModule")
        self._handle = StreamingVideoModule:Play(movieConfig:Path(), movieConfig:AllowSkip(), Delegate.GetOrCreate(self, self.OnMovieComplete))
    elseif movieConfig:SrcType() == MovieSourceType.Bundle then
        ---@type StoryPopupMoviePlayerMediatorParameter
        local parameter = {}
        parameter.allowClickSkip = movieConfig:AllowSkip()
        parameter.videoAssets = movieConfig:Path()
        parameter.onPlayExit = Delegate.GetOrCreate(self, self.OnMovieComplete)
        self._mediatorRuntimeId = g_Game.UIManager:Open(UIMediatorNames.StoryPopupMoviePlayerMediator, parameter)
    else
        self:EndAction(false)
    end
end

function StoryStepActionMovie:OnLeave()
    if self._originBgmVolume then
        local v = self._originBgmVolume
        self._originBgmVolume = nil
        g_Game.SoundManager:SetBgmVolume(v)
    end
    if self._handle then
        self._handle:Stop()
    end
    self._handle = nil
    if self._mediatorRuntimeId then
        g_Game.UIManager:Close(self._mediatorRuntimeId)
    end
    self._mediatorRuntimeId = nil
end

---@param handle StreamingVideoPlayHandle
function StoryStepActionMovie:OnMovieComplete(handle)
    self:EndAction()
end

function StoryStepActionMovie:OnSetEndStatus(isRestore)
    --do nothing, play movie no need rebuild environment
end

return StoryStepActionMovie