--- scene:scene_story_movie_player

local Delegate = require("Delegate")
local Utils = require("Utils")
local StoryPopupMoviePlayerDefine = require("StoryPopupMoviePlayerDefine")
local SdkCrashlytics = require("SdkCrashlytics")

local BaseUIMediator = require("BaseUIMediator")

---@class StoryPopupMoviePlayerMediatorParameter
---@field videoAssets string
---@field allowClickSkip boolean
---@field onPlayExit fun(reason:StoryPopupMoviePlayerDefine.ExitReason)
---@field onClickAny fun()
---@field videoAspectRatio CS.UnityEngine.Video.VideoAspectRatio

---@class StoryPopupMoviePlayerMediator:BaseUIMediator
---@field new fun():StoryPopupMoviePlayerMediator
---@field super BaseUIMediator
local StoryPopupMoviePlayerMediator = class('StoryPopupMoviePlayerMediator', BaseUIMediator)

function StoryPopupMoviePlayerMediator:ctor()
    ---@type string
    self._assetName = nil
    ---@type fun(reason:StoryPopupMoviePlayerDefine.ExitReason)
    self._onPlayExit = nil
    ---@type boolean
    self._allowSkip = false
    self._onClickAny = nil
    self._delayFramePlay = nil
    ---@type CS.UnityEngine.Video.VideoClip
    self._videoClip = nil
    self._videoAspect = CS.UnityEngine.Video.VideoAspectRatio.FitInside
end

function StoryPopupMoviePlayerMediator:OnCreate(param)
    ---@type CS.VideoPlayerMediator
    self._playerMediator = self:BindComponent("", typeof(CS.VideoPlayerMediator))
    self._p_content = self:RectTransform("p_content")
    self._p_black_btn = self:Button("p_black_btn", Delegate.GetOrCreate(self, self.OnClickAny))
    ---@type CS.UnityEngine.UI.RawImage
    self._p_drawer = self:BindComponent("p_drawer", typeof(CS.UnityEngine.UI.RawImage))
    self._p_skip_btn = self:Button("p_skip_btn", Delegate.GetOrCreate(self, self.OnClickBtnSkip))
    if Utils.IsNotNull(self._p_skip_btn) then
        ---@type CS.UnityEngine.RectTransform
        local rect = self._p_skip_btn.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        rect.anchorMin = CS.UnityEngine.Vector2(0.5, 1)
        rect.anchorMax = CS.UnityEngine.Vector2(0.5, 1)
        rect.sizeDelta = CS.UnityEngine.Vector2(100, 100)
        rect.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        rect.anchoredPosition = CS.UnityEngine.Vector2(910, -50)
        ---@type CS.UnityEngine.UI.Image
        local img = self._p_skip_btn.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if Utils.IsNotNull(img) then
            img.color = CS.UnityEngine.Color(0.7, 0.7, 0.7, 0.7)
        end
    end
end

function StoryPopupMoviePlayerMediator:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self , self.Tick))
end

function StoryPopupMoviePlayerMediator:OnHide()
    self._delayFramePlay = nil
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self , self.Tick))
end

---@param param StoryPopupMoviePlayerMediatorParameter
function StoryPopupMoviePlayerMediator:OnOpened(param)
    self._assetName = param.videoAssets
    self._onPlayExit = param.onPlayExit
    self._allowSkip = param.allowClickSkip
    self._onClickAny = param.onClickAny
    self._p_skip_btn:SetVisible(param.allowClickSkip)
    if string.IsNullOrEmpty(self._assetName) then
        self:CallThenClearExitCallBack(StoryPopupMoviePlayerDefine.ExitReason.NoAsset)
        self:CloseSelf()
        return
    end
    local videoClip = g_Game.VideoClipManager:LoadVideoClip(self._assetName)
    if Utils.IsNullOrEmpty(videoClip) then
        self:CallThenClearExitCallBack(StoryPopupMoviePlayerDefine.ExitReason.NoAsset)
        self:CloseSelf()
        return
    end
    self._videoClip = videoClip
    self._delayFramePlay = 2
    -- self._playerMediator:Play(videoClip, Delegate.GetOrCreate(self, self.OnReachLoopPoint) , g_Game.UIManager:GetUICamera())
end

function StoryPopupMoviePlayerMediator:OnClose(data)
    self._videoClip = nil
    if not string.IsNullOrEmpty(self._assetName) then
        g_Game.VideoClipManager:UnloadVideoClip(self._assetName)
    end
    self._assetName = nil
    self:CallThenClearExitCallBack(StoryPopupMoviePlayerDefine.ExitReason.ClosedByOther)
    BaseUIMediator.OnClose(self, data)
end

function StoryPopupMoviePlayerMediator:OnClickAny()
    if self._onClickAny then
        self._onClickAny()
    end
end

function StoryPopupMoviePlayerMediator:OnClickBtnSkip()
    if self._allowSkip then
        self._playerMediator:Stop()
        self:CallThenClearExitCallBack(StoryPopupMoviePlayerDefine.ExitReason.Skip)
        self:CloseSelf()
    end
end

local function LogExceptionOrError(result)
    if not SdkCrashlytics.LogCSException(result) then
        SdkCrashlytics.LogLuaErrorAsException(result)
    end
end

---@param reason StoryPopupMoviePlayerDefine.ExitReason
function StoryPopupMoviePlayerMediator:CallThenClearExitCallBack(reason)
    if self._onPlayExit then
        local callBack = self._onPlayExit
        self._onPlayExit = nil
        try_catch_traceback(function() callBack(reason)  end, LogExceptionOrError)
    end
end

function StoryPopupMoviePlayerMediator:OnReachLoopPoint()
    self._playerMediator:Stop()
    self:CallThenClearExitCallBack(StoryPopupMoviePlayerDefine.ExitReason.Success)
    self:CloseSelf()
end

function StoryPopupMoviePlayerMediator:Tick(dt)
    if not self._delayFramePlay then return end
    self._delayFramePlay = self._delayFramePlay - 1
    if self._delayFramePlay < 0 then
        self._delayFramePlay = nil
        if Utils.IsNotNull(self._videoClip) then
            self._playerMediator:Play(self._videoClip, Delegate.GetOrCreate(self, self.OnReachLoopPoint) , g_Game.UIManager:GetUICamera(), self._videoAspect)
            self._videoClip = nil
        end
    end
end

return StoryPopupMoviePlayerMediator