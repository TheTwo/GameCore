local BaseUIComponent = require("BaseUIComponent")

---@class CityItemHarvestItemCell:BaseUIComponent
---@field new fun():CityItemHarvestItemCell
---@field super BaseUIComponent
local CityItemHarvestItemCell = class('CityItemHarvestItemCell', BaseUIComponent)

function CityItemHarvestItemCell:ctor()
    self._phaseOneEnd = true
    self._phaseTwoEnd = true
    self._arriveSoundEffect = nil
end

function CityItemHarvestItemCell:OnCreate(param)
    self._selfTrans = self:RectTransform("")
    self._p_img_1 = self:Image("p_img_1")
    self._p_text_1 = self:Text("p_text_1")
    self._vx_trigger_item_reward = self:AnimTrigger("vx_trigger_item_reward")
end

---@param data CityItemHarvestItemCellData
function CityItemHarvestItemCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.itemIcon, self._p_img_1)
    self._p_text_1.text = string.format("+%d", data.addCount)
    self._arriveSoundEffect = data.arriveSoundEffect
end

---@param targetPos CS.UnityEngine.Vector2
function CityItemHarvestItemCell:Start(targetPos, firstPhaseLength)
    self._phaseOneEnd = false
    self._phaseTwoEnd = false
    self._selfTrans:SetVisible(true)
    self._vx_trigger_item_reward:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._vx_trigger_item_reward:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    local dir = CS.UnityEngine.Random.Range(-45, 45)
    local x = math.cos(dir)
    local y = math.sin(dir)
    local dirVec = CS.UnityEngine.Vector3(x, y, 0).normalized * firstPhaseLength
    local tween = self._selfTrans:DOLocalMove(self._selfTrans.position + dirVec, 0.2)
    tween:SetEase(CS.DG.Tweening.Ease.OutCubic)
    tween:OnComplete(function() 
        self._phaseOneEnd = true
        local t2 = self._selfTrans:DOAnchorPos(targetPos, 0.5)
        t2:SetEase(CS.DG.Tweening.Ease.InCubic)
        t2:OnComplete(function()
            self._phaseTwoEnd = true
            if self._arriveSoundEffect then
                g_Game.SoundManager:PlayAudio(self._arriveSoundEffect)
            end
            self._arriveSoundEffect = nil
        end)
        self._selfTrans:DOPlay()
    end)
    self._selfTrans:DOPlay()
end

---@return boolean
function CityItemHarvestItemCell:TickEnd(dt)
    return self._phaseOneEnd and self._phaseTwoEnd
end

---@param poolTrans CS.UnityEngine.Transform
function CityItemHarvestItemCell:Recycle(poolTrans)
    self._phaseOneEnd = true
    self._phaseTwoEnd = true
    self._arriveSoundEffect = nil
    self._vx_trigger_item_reward:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._selfTrans:DOKill(false)
    self._selfTrans:SetVisible(false)
    self._selfTrans.parent = poolTrans
end

return CityItemHarvestItemCell