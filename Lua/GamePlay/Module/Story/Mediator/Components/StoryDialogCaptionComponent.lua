---scene:scene_child_story_caption
local StoryCaptionLocationType = require("StoryCaptionLocationType")
local ArtResourceUtils = require("ArtResourceUtils")
local TyperStyle = require("TyperStyle")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

local BaseUIComponent = require("BaseUIComponent")

---@class StoryDialogCaptionComponent:BaseUIComponent
---@field super BaseUIComponent
---@field host StoryDialogUIMediator
local StoryDialogCaptionComponent = class("StoryDialogCaptionComponent", BaseUIComponent)

function StoryDialogCaptionComponent:ctor()
    StoryDialogCaptionComponent.super.ctor(self)
end

function StoryDialogCaptionComponent:OnCreate()
    -- caption node
    self._g_caption_middle = self:GameObject("p_caption_middle")
    self._lb_caption_middle = self:Text("p_text_caption_m")
    self._g_caption_bottom = self:GameObject("p_caption_bottom")
    self._lb_caption_bottom = self:Text("p_text_caption_b")
    self._p_layoutTrans_m = self:Transform("p_layoutTrans_m")
    self._p_layoutTrans_b = self:Transform("p_layoutTrans_b")
    self._lb_caption_middle:SetVisible(false)
    self._lb_caption_bottom:SetVisible(false)
    self._p_caption_leftright = self:GameObject("p_caption_leftright")
    self._p_layoutTrans_l = self:Transform("p_layoutTrans_l")
    self._p_layoutTrans_r = self:Transform("p_layoutTrans_r")
    self._p_text_left = self:Transform("p_text_left")
    self._p_text_right = self:Transform("p_text_right")
    self._p_text_left:SetVisible(false)
    self._p_text_right:SetVisible(false)
end

---@param captionConfig ChapterCaptionConfigCell
---@param lb CS.UnityEngine.UI.Text
---@param layoutTrans CS.UnityEngine.Transform
local function MakeCaptionGroup(captionConfig, lb, layoutTrans)
    local ret = {}
    ---@type string[]
    ret._content = {}
    ret._waitTime = captionConfig:Wait()
    ret._waitTimeRuntime = 0
    ret._typerStyle = TyperStyle.new()
    ret._useTyper = captionConfig:TypeWriter() > 0
    ret._index = 0
    ret._lb = lb
    ret._layoutTrans = layoutTrans
    ret._typingEnd = true
    for i = 1, captionConfig:ContentLength() do
        local c = captionConfig:Content(i)
        ret._content[i] = g_Game.LocalizationManager:Get(c)
    end
    return ret
end

function StoryDialogCaptionComponent:InitForCaption()
    local cfg = self.host._param._captionConfig
    local pos = cfg:Location()
    local lb
    local layoutTrans
    if pos == StoryCaptionLocationType.Bottom then
        self._g_caption_bottom:SetActive(true)
        self._g_caption_middle:SetActive(false)
        lb = self._lb_caption_bottom
        layoutTrans = self._p_layoutTrans_b
    elseif pos == StoryCaptionLocationType.Center then
        self._g_caption_bottom:SetActive(false)
        self._g_caption_middle:SetActive(true)
        lb = self._lb_caption_middle
        layoutTrans = self._p_layoutTrans_m
    elseif pos == StoryCaptionLocationType.Left then
        self._g_caption_bottom:SetActive(false)
        self._g_caption_middle:SetActive(false)
        self._p_caption_leftright:SetVisible(true)
        lb = self._p_text_left
        layoutTrans = self._p_layoutTrans_l
    elseif pos == StoryCaptionLocationType.Right then
        self._g_caption_bottom:SetActive(false)
        self._g_caption_middle:SetActive(false)
        self._p_caption_leftright:SetVisible(true)
        lb = self._p_text_right
        layoutTrans = self._p_layoutTrans_r
    else
        g_Logger.Error("ChapterCaptionConfigCell:%s unsupported pos:%s", cfg:Id(), pos)
        self._g_caption_bottom:SetActive(false)
        self._g_caption_middle:SetActive(true)
        lb = self._lb_caption_middle
        layoutTrans = self._p_layoutTrans_m
    end
    local background = cfg:Background() > 0 and ArtResourceUtils.GetUIItem(cfg:Background()) or string.Empty
    self.host:SetBackGround((not string.IsNullOrEmpty(background)), background)
    local voice = cfg:VoiceRes() > 0 and ArtResourceUtils.GetAudio(cfg:VoiceRes()) or string.Empty
    if not string.IsNullOrEmpty(voice) then
        self._runningVoiceHandle = g_Game.SoundManager:Play(voice)
    end
    self.host._captionGroup = MakeCaptionGroup(cfg, lb, layoutTrans)
    self:StartNextCaption()
end

function StoryDialogCaptionComponent:StartNextCaption()
    local group = self.host._captionGroup
    if (not group) or (group._index >= #group._content) then
        self.host:OnCaptionEnd()
        return
    end
    group._index = group._index + 1
    group._waitTimeRuntime = group._waitTime
    local content = group._content[group._index]
    if not group._typingEnd then
        group._typerStyle:StopTyping()
    end
    ---@type CS.UnityEngine.UI.Text
    local lb = UIHelper.DuplicateUIGameObject(group._lb.gameObject, group._layoutTrans):GetComponent(typeof(CS.UnityEngine.UI.Text))
    lb:SetVisible(true)
    table.insert(self.host._createdCaptions, lb.gameObject)
    if group._useTyper then
        lb.text = ""
        group._typingEnd = false
        group._typerStyle:Initialize(content
        , function(text)
                    if Utils.IsNotNull(lb) then
                        lb.text = text
                    end
                end
        , function() group._typingEnd = true end
        , 0.012)
        group._typerStyle:StartTyping()
    else
        lb.text = content
        group._typingEnd = true
    end
end

return StoryDialogCaptionComponent