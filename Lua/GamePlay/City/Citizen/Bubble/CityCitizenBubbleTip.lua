---prefab:ui3d_bubble_citizen_tip
local Delegate = require("Delegate")
local I18N = require("I18N")
local CityUtils = require("CityUtils")

---@class CityCitizenBubbleTipTaskContext
---@field icon string
---@field callback fun()
---@field bg string
---@field effect string
---@field triggerAni number @nil-none,1->custom1 reward,2->custom2 hint

---@class CityCitizenBubbleTip
---@field new fun():CityCitizenBubbleTip
---@field p_bubble_npc CS.UnityEngine.GameObject
---@field p_npc_bubble_base CS.U2DSpriteMesh
---@field p_effect_holder CS.UnityEngine.Transform
---@field p_icon_npc CS.U2DSpriteMesh
---@field p_bubble_npc_trigger CS.DragonReborn.LuaBehaviour
---@field p_escape CS.UnityEngine.GameObject
---@field p_bubble_talk CS.UnityEngine.GameObject
---@field p_text_talk CS.U2DTextMesh
---@field p_bubble_evaluation CS.UnityEngine.GameObject
---@field p_text_evaluation CS.U2DTextMesh
---@field p_icon_evaluation CS.U2DSpriteMesh
---@field p_emoji CS.UnityEngine.GameObject
---@field p_emoji_icon CS.U2DSpriteMesh
---@field p_trigger_new CS.FpAnimation.FpAnimationCommonTrigger
local CityCitizenBubbleTip = sealedClass('CityCitizenBubbleTip')

function CityCitizenBubbleTip:ctor()
    self._needReSizeText = false
    self._clickCallback = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._effectHandle = nil
end

function CityCitizenBubbleTip:Reset()
    self._clickCallback = nil
    self.p_bubble_npc:SetVisible(false)
    self.p_escape:SetVisible(false)
    self.p_bubble_talk:SetVisible(false)
    self.p_bubble_evaluation:SetVisible(false)
    self.p_emoji:SetVisible(false)
    if self._effectHandle then
        self._effectHandle:Delete()
    end
    self._effectHandle  = nil
end

---@param context CityCitizenBubbleTipTaskContext
function CityCitizenBubbleTip:SetupTaskButton(context)
    local icon, callback, bg, effect,triggerAni = context.icon,context.callback, context.bg, context.effect, context.triggerAni
    self._clickCallback = callback
    self.p_bubble_npc:SetActive(true)
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_npc)
    ---@type CityTrigger
    local trigger = self.p_bubble_npc_trigger.Instance
    trigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickTrigger), nil, true)
    g_Game.SpriteManager:LoadSpriteAsync(bg, self.p_npc_bubble_base)
    if triggerAni == 1 then
        self.p_trigger_new:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    elseif triggerAni == 2 then
        self.p_trigger_new:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    else
        self.p_trigger_new:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    if self._effectHandle then
        if self._effectHandle.PrefabName == effect then return end
        self._effectHandle:Delete()
        self._effectHandle = nil
    end
    if string.IsNullOrEmpty(effect) then return end
    self._effectHandle = CityUtils.GetPooledGameObjectCreateHelper():Create(effect, self.p_effect_holder, nil)
end

---@param config BubbleConfigCell
function CityCitizenBubbleTip:SetTipContent(config)
    self.p_bubble_talk:SetActive(true)
    self.p_text_talk.text = I18N.Get(config:Content())
end

function CityCitizenBubbleTip:SetupEscape()
    self.p_escape:SetVisible(true)
end

function CityCitizenBubbleTip:SetupEvaluation(icon, value)
    self.p_bubble_evaluation:SetVisible(true)
    self.p_text_evaluation.text = value > 0 and ("+%d"):format(math.floor(value)) or ("-%d"):format(math.ceil(value))
    if string.IsNullOrEmpty(icon) then return end
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_evaluation)
end

function CityCitizenBubbleTip:SetupEmoji(icon)
    self.p_emoji:SetVisible(true)
    g_Game.SpriteManager:LoadSprite(icon, self.p_emoji_icon)
end

function CityCitizenBubbleTip:OnClickTrigger()
    if self._clickCallback then
        self._clickCallback()
    end
    return true
end

return CityCitizenBubbleTip