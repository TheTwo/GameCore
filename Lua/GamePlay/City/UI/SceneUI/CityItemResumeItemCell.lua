local BaseUIComponent = require("BaseUIComponent")

---@class CityItemResumeItemCell:BaseUIComponent
---@field new fun():CityItemResumeItemCell
---@field super BaseUIComponent
local CityItemResumeItemCell = class('CityItemResumeItemCell', BaseUIComponent)

function CityItemResumeItemCell:ctor()
    BaseUIComponent.ctor(self)
    self._aniLength = 0
    self._aniLeftTime = 0
    self._aniDelay = nil
end

function CityItemResumeItemCell:OnCreate(param)
    self._selfTrans = self:Transform("")
    self._p_img_drop_item = self:Image("p_img_drop_item")
    self._p_text_1 = self:Text("p_text_1")
    self._vx_trigger_item_resume = self:AnimTrigger("vx_trigger_item_resume")
    self._aniLength = self._vx_trigger_item_resume:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom1)
end

---@param data CityItemResumeMediatorQueueItem
function CityItemResumeItemCell:OnFeedData(data)
    self._vx_trigger_item_resume:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_text_1.text = tostring(0 - data.count)
    g_Game.SpriteManager:LoadSprite(data.itemIcon, self._p_img_drop_item)
end

function CityItemResumeItemCell:Start(delay)
    self._aniDelay = (delay and delay > 0 and delay) or nil
    self._selfTrans:SetVisible(true)
    self._aniLeftTime = self._aniLength
    if not self._aniDelay then
        self._vx_trigger_item_resume:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

---@return boolean
function CityItemResumeItemCell:TickEnd(dt)
    if self._aniDelay then
        self._aniDelay = self._aniDelay - dt
        if self._aniDelay <= 0 then
            self._aniDelay = nil
            self._vx_trigger_item_resume:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
        return false
    end
    if self._aniLeftTime <= 0 then
        return true
    end
    self._aniLeftTime = self._aniLeftTime - dt
    return false
end

---@param poolTrans CS.UnityEngine.Transform
function CityItemResumeItemCell:Recycle(poolTrans)
    self._aniLeftTime = 0
    self._aniDelay = 0
    self._vx_trigger_item_resume:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._selfTrans:SetVisible(false)
    self._selfTrans.parent = poolTrans
end

return CityItemResumeItemCell