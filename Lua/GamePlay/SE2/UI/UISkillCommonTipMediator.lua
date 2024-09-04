--- scene:scene_common_skill_tip

local Delegate = require("Delegate")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local Utils = require("Utils")

local BaseUIMediator = require("BaseUIMediator")

---@class UISkillCommonTipMediatorParameter
---@field clickTrans CS.UnityEngine.RectTransform
---@field ShowSocSkillTips {socSkillId:number,skillLevel:number} 
---@field ShowSlgSkillTips {slgSkillId:number,skillLevel:number} 
---@field ShowSECardTips {unitManager:SEUnitManager,cardCfgId:number,useSkillId:boolean,isNormalAttack:boolean,skillLevel:number} 
---@field ShowHeroSkillTips {slgSkillId:number,cardId:number,isLock:boolean,skillLevel:number,slgSkillCell:SlgSkillInfoConfigCell,onGoto:fun(),hasHero:boolean}
---@field ShowCustomTips {name:string,desc:string}
---@field offset CS.UnityEngine.Vector2

---@class UISkillCommonTipMediator:BaseUIMediator
---@field new fun():UISkillCommonTipMediator
---@field super BaseUIMediator
local UISkillCommonTipMediator = class('UISkillCommonTipMediator', BaseUIMediator)

function UISkillCommonTipMediator:ctor()
    UISkillCommonTipMediator.super.ctor(self)
    self._v = 0
end

function UISkillCommonTipMediator:OnCreate(param)
    self.rectRoot = self:RectTransform("")
    self._p_tip_rect = self:RectTransform("p_tip_rect")
    ---@type SEHudTipsSkillCard
    self._child_tips_skill_card = self:LuaObject("child_tips_skill_card")
    self._child_tips_skill_card_rect = self:RectTransform("child_tips_skill_card")
    ---@type CS.UnityEngine.RectTransform
    self._child_p_table_detail_rect = nil
end

---@param param UISkillCommonTipMediatorParameter
function UISkillCommonTipMediator:OnOpened(param)
    ---@type CS.UnityEngine.RectTransform
    self._child_p_table_detail_rect = self._child_tips_skill_card.tableviewproTableDetail.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._param = param
    if param.ShowSocSkillTips then
        local p = param.ShowSocSkillTips
        self._child_tips_skill_card:ShowSocSkillTips(p.socSkillId, p.skillLevel)
    elseif param.ShowSlgSkillTips then
        local p = param.ShowSlgSkillTips
        self._child_tips_skill_card:ShowSlgSkillTips(p.slgSkillId, p.skillLevel)
    elseif param.ShowSECardTips then
        local p = param.ShowSECardTips
        self._child_tips_skill_card:ShowSECardTips(p.cardCfgId, p.unitManager, p.useSkillId, p.isNormalAttack, p.skillLevel)
    elseif param.ShowHeroSkillTips then
        local p = param.ShowHeroSkillTips
        self._child_tips_skill_card:ShowHeroSkillTips(p.slgSkillId, p.cardId, p.isLock, p.skillLevel, p.slgSkillCell, p.onGoto, p.hasHero)
    elseif param.ShowCustomTips then
        self._child_tips_skill_card:ShowCustomTips(param.ShowCustomTips)
    elseif UNITY_DEBUG then
        self._child_tips_skill_card:ShowCustomTips("UISkillCommonTipMediatorParameter 参数错误")
    end
    self:UpdateTipRectSize()
    if param.offset and not param.clickTrans then
        self.rectRoot.anchoredPosition = self.rectRoot.anchoredPosition + param.offset
    end
end

function UISkillCommonTipMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function UISkillCommonTipMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function UISkillCommonTipMediator:LateUpdate(dt)
    if not self._param then return end
    if Utils.IsNull(self._param.clickTrans) then return end
    self:UpdateTipRectSize(true, dt)
    TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self._param.clickTrans, self._p_tip_rect)
end

function UISkillCommonTipMediator:UpdateTipRectSize(smoothDamp, dt)
    local size = self._p_tip_rect.sizeDelta
    local oldSize = size.x
    if self._child_p_table_detail_rect.gameObject.activeSelf then
        size.x = self._child_tips_skill_card_rect.sizeDelta.x + self._child_p_table_detail_rect.sizeDelta.x
    else
        size.x = self._child_tips_skill_card_rect.sizeDelta.x
    end
    if math.abs(size.x - oldSize) < 0.01 then
        self._v = 0
        return
    end
    if smoothDamp then
        local x, v = UISkillCommonTipMediator.SmoothDamp(oldSize, size.x, self._v, dt,10000, dt)
        self._v = v
        size.x = x
    else
        self._v = 0
    end
    self._p_tip_rect.sizeDelta = size
end

function UISkillCommonTipMediator.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed , deltaTime)
    smoothTime = math.max(0.0001, smoothTime)
    local num1 = 2.0 / smoothTime
    local num2 = num1 * deltaTime
    local num3 = (1.0 / (1.0 + num2 + 0.47999998927116394 * num2 * num2 + 0.23499999940395355 * num2 * num2 *num2))
    local num4 = current - target
    local num5 = target
    local max = maxSpeed * smoothTime
    local num6 = math.clamp(num4, -max, max)
    target = current - num6
    local num7 = (currentVelocity + num1 * num6) * deltaTime
    currentVelocity = (currentVelocity - num1 * num7) * num3
    local num8 = target + (num6 + num7) * num3
    if ((num5 - current > 0.0) == (num8 > num5)) then
        num8 = num5
        currentVelocity = (num8 - num5) / deltaTime
    end
    return num8, currentVelocity
end

return UISkillCommonTipMediator