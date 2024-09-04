local I18N = require("I18N")
---@type CS.DG.Tweening.Ease
local Ease = CS.DG.Tweening.Ease
local UIHelper = require("UIHelper")
local ArtResourceUtils = require("ArtResourceUtils")
local TimeFormatter = require("TimeFormatter")

local BaseUIComponent = require("BaseUIComponent")

---@class CityCitizenResidentFeedbackPaperCell:BaseUIComponent
---@field new fun():CityCitizenResidentFeedbackPaperCell
---@field super BaseUIComponent
local CityCitizenResidentFeedbackPaperCell = class('CityCitizenResidentFeedbackPaperCell', BaseUIComponent)

---@class CityCitizenResidentFeedbackPaperCellParameter
---@field id number
---@field citizenConfig CitizenConfigCell
---@field timeStamp number

function CityCitizenResidentFeedbackPaperCell:OnCreate(param)
    self._p_self_root = self:RectTransform("")
    ---@type CS.UnityEngine.CanvasGroup
    self._p_self_canvasGroup = self:BindComponent("", typeof(CS.UnityEngine.CanvasGroup))
    self._p_img_refugee = self:Image("p_img_refugee")
    self._p_text_name = self:Text("p_text_name")
    self._p_talent = self:Transform("p_talent")
    self._p_icon_talent = self:Image("p_icon_talent")
    self._p_text_talent = self:Text("p_text_talent")
    self._p_text_story = self:Text("p_text_story")
    ---@type CS.UnityEngine.Animation
    self._p_img_stamp = self:BindComponent("p_img_stamp", typeof(CS.UnityEngine.Animation))
    self._p_text_time = self:Text("p_text_time")

    self._p_talent:SetVisible(false)
    self._p_img_stamp:SetVisible(false)
end

---@param data CityCitizenResidentFeedbackPaperCellParameter
function CityCitizenResidentFeedbackPaperCell:OnFeedData(data)
    self._data = data
    local config = data.citizenConfig
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:Icon()), self._p_img_refugee)
    self._p_text_name.text = I18N.Get(config:Name())
    self._p_text_talent.text = ""
    self._p_text_story.text = I18N.Get(config:Description())
    self._p_text_time.text = string.format("Reg.%s", TimeFormatter.TimeToDateTimeString(data.timeStamp))
    self._p_img_stamp:SetVisible(false)
end

function CityCitizenResidentFeedbackPaperCell:OnPlayCollectAni()
    self._p_img_stamp:SetVisible(true)
    self._p_img_stamp:Stop()
    local clip = self._p_img_stamp.clip
    local clipName = clip.name
    self._p_img_stamp:SetAnimationTime(clipName, 0)
    self._p_img_stamp:Play()
end

function CityCitizenResidentFeedbackPaperCell:FastForwardCollectAni()
    self._p_img_stamp:SetVisible(true)
    self._p_img_stamp:Stop()
    local clip = self._p_img_stamp.clip
    local clipName = clip.name
    local clipLength = clip.length
    self._p_img_stamp:SetAnimationTime(clipName, clipLength)
    self._p_img_stamp:Sample()
end

function CityCitizenResidentFeedbackPaperCell:PlayFlyawayThenDestroy(callback)
    self._p_self_canvasGroup:DOFade(0, 0.5)
    local size = self._p_self_root.rect.size
    local localPos = self._p_self_root.localPosition
    localPos.x = localPos.x + size.x * 0.5
    localPos.y = localPos.y + size.y
    self._p_self_root:DOKill(true)
    self._p_self_root:DOLocalMove(localPos, 0.5, false):SetEase(Ease.InCubic):OnComplete(function()
        if callback then
            callback()
        end
        UIHelper.DeleteUIComponent(self)
    end)
end

return CityCitizenResidentFeedbackPaperCell

