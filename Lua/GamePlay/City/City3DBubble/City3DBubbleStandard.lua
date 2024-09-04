---prefabName:ui3d_bubble_group
---@class City3DBubbleStandard
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field transform CS.UnityEngine.Transform
---@field p_rotation CS.UnityEngine.Transform
---@field p_position CS.UnityEngine.Transform
---@field trigger CS.DragonReborn.LuaBehaviour
---@field p_bubble CS.UnityEngine.GameObject
---@field p_bubble_1 CS.UnityEngine.GameObject
---@field p_icon_status_1 CS.U2DSpriteMesh
---@field p_bubble_collider CS.UnityEngine.Collider
---@field p_base_nomal CS.UnityEngine.GameObject
---@field p_base_red CS.UnityEngine.GameObject
---@field p_icon_status CS.U2DSpriteMesh
---@field p_text_quantity CS.U2DTextMesh
---@field p_icon_check CS.UnityEngine.GameObject
---@field p_progress CS.UnityEngine.GameObject
---@field p_progress_collider CS.UnityEngine.Collider
---@field p_icon CS.U2DSpriteMesh
---@field p_bar_blue CS.U2DSpriteMesh
---@field p_bar_red CS.U2DSpriteMesh
---@field p_text_time CS.U2DTextMesh
---@field p_text_number CS.U2DTextMesh
---@field p_icon_danger CS.UnityEngine.GameObject
---@field p_icon_ban CS.UnityEngine.GameObject
---@field p_icon_process CS.UnityEngine.GameObject
---@field p_vx_trigger CS.FpAnimation.FpAnimationCommonTrigger
---@field cityTrigger CityTrigger
---@field bubbleNormalBg CS.U2DSpriteMesh
---@field bubbleSeBg CS.U2DSpriteMesh
---@field iconEffectHolder CS.UnityEngine.Transform
---@field trigger_new CS.FpAnimation.FpAnimationCommonTrigger
local City3DBubbleStandard = class("City3DBubbleStandard")
local Utils = require("Utils")
local CityUtils = require("CityUtils")

local Status = {Bubble = 1, Progress = 2, Ban = 3}
local BubbleBackStats = {Normal = 1, Red = 2}
local ProgressBackStats = {Blue = 1, Red = 2}

local DefaultSortingOrder = {
    BubbleIcon = 1100,
    BubbleIconMin = 1001,
    BubbleIconMax = 1399,
    BubbleBack = 1000,
    ProcessBack = 500,
    ProcessIcon = 600,
    ProcessIconMin = 501,
    ProcessIconMax = 999,
}

local defaultRootStatus = Status.Bubble
local defaultBubbleBack = BubbleBackStats.Normal
local defaultProgressBack = ProgressBackStats.Blue
local defaultBubbleBackIcon = "sp_city_bubble_base_01"
local defaultBubbleSeBackIcon = "sp_city_bubble_base_hurt"

function City3DBubbleStandard:Awake()
    self.rootStatus = defaultRootStatus
    self.cityTrigger = self.trigger.Instance

    self.enableTrigger = true
    
    self.bubbleBackStatus = defaultBubbleBack
    self.showText = self.p_text_quantity.gameObject.activeSelf
    self.showCheckImg = self.p_icon_check.gameObject.activeSelf
    self.showDangerImg = self.p_icon_danger.gameObject.activeSelf
    self.showBubbleIcon = self.p_icon_status.gameObject.activeSelf
    
    self.progressBackStatus = defaultProgressBack
    self.showTimeText = self.p_text_time.gameObject.activeSelf
    self.showProgressIcon = self.p_icon.gameObject.activeSelf
    self.showNumberText = self.p_text_number.gameObject.activeSelf

    self.showBubbleNormalBgIcon = self.bubbleNormalBg.sprite and self.bubbleNormalBg.sprite.name or string.Empty
    self.showBubbleSeBgIcon = self.bubbleSeBg.sprite and self.bubbleSeBg.sprite.name or string.Empty
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self.showBubbleEffectHandle = nil

    self.showGear = self.p_icon_process.activeSelf
    self.root = {
        [Status.Bubble] = self.p_bubble,
        [Status.Progress] = self.p_progress,
        [Status.Ban] = self.p_icon_ban,
    }
    for k, v in pairs(self.root) do
        v:SetActive(self.rootStatus == k)
    end

    self.progressIconSortingOrderComp = self.p_icon:GetComponent(typeof(CS.DragonReborn.RendererSortingOrderModifier))
    self.progressIconSortingOrder = self.progressIconSortingOrderComp.SortingOrder
    self.bubbleIconSortingOrderComp = self.p_icon_status:GetComponent(typeof(CS.DragonReborn.RendererSortingOrderModifier))
    self.bubbleIconSortingOrder = self.bubbleIconSortingOrderComp.SortingOrder

    self.bubbleIconPath = string.Empty
    self.progressIconPath = string.Empty
end

function City3DBubbleStandard:IsValid()
    return Utils.IsNotNull(self.behaviour)
end

---@private
function City3DBubbleStandard:SwitchRootStatus(targetStatus)
    if self.rootStatus == targetStatus then
        return
    end

    self:ResetCurrentStatus()
    self:SwitchImp(targetStatus)
end

---@private
function City3DBubbleStandard:ResetCurrentStatus()
    if self.rootStatus == Status.Bubble then
        self:ResetBubbleBack()
        self:ResetBubbleText()
        self:ResetBubbleCheckImg()
        self:ResetSubIcon()
        self:ResetBubbleSortingOrder()
    elseif self.rootStatus == Status.Progress then
        self:ResetProgressIcon()
        self:ResetProgressBack()
        self:ResetProgressTimeText()
        self:ResetProgressNumberText()
        self:ResetProgressSortingOrder()
    end
    self:ResetBubbleDangerImg()
    self:ResetLoopAnim()
    self:ResetGear()
    self:ResetRewardAnim()
    self:ResetBubbleVerticalPos()
end

---@private
function City3DBubbleStandard:ResetBubbleBack()
    if self.bubbleBackStatus ~= defaultBubbleBack then
        self.p_base_nomal:SetActive(true)
        self.p_base_red:SetActive(false)
        self.bubbleBackStatus = defaultBubbleBack
    end
    self.showBubbleNormalBgIcon = defaultBubbleBackIcon
    g_Game.SpriteManager:LoadSpriteAsync(defaultBubbleBackIcon, self.bubbleNormalBg)
    self.showBubbleSeBgIcon = defaultBubbleSeBackIcon
    g_Game.SpriteManager:LoadSpriteAsync(defaultBubbleSeBackIcon, self.bubbleSeBg)
end

---@private
function City3DBubbleStandard:ResetBubbleText()
    if self.showText then
        self.p_text_quantity:SetVisible(false)
        self.showText = false
    end
end

---@private
function City3DBubbleStandard:ResetBubbleCheckImg()
    if self.showCheckImg then
        self.p_icon_check:SetVisible(false)
        self.showCheckImg = false
    end
end

function City3DBubbleStandard:ResetSubIcon()
    self:ShowSubIcon(nil)
end

function City3DBubbleStandard:ResetBubbleSortingOrder()
    if self.bubbleIconSortingOrder ~= DefaultSortingOrder.BubbleIcon then
        self.bubbleIconSortingOrderComp.SortingOrder = DefaultSortingOrder.BubbleIcon
        self.bubbleIconSortingOrder = DefaultSortingOrder.BubbleIcon
    end
end

---@private
function City3DBubbleStandard:ResetBubbleDangerImg()
    self:ShowDangerImg(false)
end

---@private
function City3DBubbleStandard:ResetGear()
    self:ShowGear(false)
end

function City3DBubbleStandard:ResetLoopAnim()
    self.p_vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom6)
end

function City3DBubbleStandard:ResetProgressIcon()
    self:ShowProgressIcon(nil)
end

---@private
function City3DBubbleStandard:ResetProgressBack()
    if self.progressBackStatus ~= defaultProgressBack then
        self.p_bar_blue:SetVisible(true)
        self.p_bar_red:SetVisible(false)
        self.progressBackStatus = defaultProgressBack
    end
end

---@private
function City3DBubbleStandard:ResetProgressTimeText()
    if self.showTimeText then
        self.p_text_time:SetVisible(false)
        self.showTimeText = false
    end
end

function City3DBubbleStandard:ResetProgressNumberText()
    if self.showNumberText then
        self.p_text_number:SetVisible(false)
        self.showNumberText = false
    end
end

function City3DBubbleStandard:ResetProgressSortingOrder()
    if self.progressIconSortingOrder ~= DefaultSortingOrder.ProcessIcon then
        self.progressIconSortingOrderComp.SortingOrder = DefaultSortingOrder.ProcessIcon
        self.progressIconSortingOrder = DefaultSortingOrder.ProcessIcon
    end
end

---@private
function City3DBubbleStandard:SwitchImp(targetStatus)
    self.root[self.rootStatus]:SetActive(false)
    self.rootStatus = targetStatus
    self.root[self.rootStatus]:SetActive(true)
end

function City3DBubbleStandard:ShowBubble(icon, red, text, showCheck, showDanger, showGear, subIcon)
    self:SwitchRootStatus(Status.Bubble)
    self:ShowBubbleIcon(icon)
    self:ChangeBubbleBack(red and BubbleBackStats.Red or BubbleBackStats.Normal)
    self:ShowBubbleText(text)
    self:ShowBubbleCheckImg(showCheck == true)
    self:ShowDangerImg(showDanger == true)
    self:ShowGear(showGear == true)
    self:ShowSubIcon(subIcon)
    return self
end

function City3DBubbleStandard:ShowBubbleIcon(icon)
    local showBubbleIcon = not string.IsNullOrEmpty(icon)
    local bubbleDirty = self.bubbleIconPath ~= icon
    if self.showBubbleIcon ~= showBubbleIcon then
        self.showBubbleIcon = showBubbleIcon
        self.p_icon_status:SetVisible(showBubbleIcon)
    end
    if showBubbleIcon and bubbleDirty then
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_status)
    end
    self.bubbleIconPath = icon
    return self
end

function City3DBubbleStandard.GetDefaultNormalBg()
    return defaultBubbleBackIcon
end

function City3DBubbleStandard.GetDefaultSeBg()
    return defaultBubbleSeBackIcon
end

function City3DBubbleStandard:ShowBubbleBackIcon(icon)
    if string.IsNullOrEmpty(icon) then return self end
    if self.showBubbleNormalBgIcon ~= icon then
        self.showBubbleNormalBgIcon = icon
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.bubbleNormalBg)
    end
    return self
end

function City3DBubbleStandard:ShowBubbleSeBackIcon(icon)
    if string.IsNullOrEmpty(icon) then return self end
    if self.showBubbleSeBgIcon ~= icon then
        self.showBubbleSeBgIcon = icon
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.bubbleSeBg)
    end
    return self
end

function City3DBubbleStandard:ShowBubbleIconEffect(effect)
    if self.showBubbleEffectHandle then
        if self.showBubbleEffectHandle.PrefabName == effect then return self end
        self.showBubbleEffectHandle:Delete()
        self.showBubbleEffectHandle = nil
    end
    if not string.IsNullOrEmpty(effect) then
        self.showBubbleEffectHandle = CityUtils.GetPooledGameObjectCreateHelper():Create(effect, self.iconEffectHolder, nil)
    end
    return self
end

function City3DBubbleStandard:ChangeBubbleBack(backStatus)
    if self.bubbleBackStatus == backStatus then return self end

    self.bubbleBackStatus = backStatus
    self.p_base_nomal:SetActive(backStatus == BubbleBackStats.Normal)
    self.p_base_red:SetActive(backStatus == BubbleBackStats.Red)
    return self
end

function City3DBubbleStandard:ShowBubbleText(text)
    local isStr = type(text) == "string"
    if self.showText ~= isStr then
        self.showText = isStr
        self.p_text_quantity:SetVisible(isStr)
    end
    if isStr then
        self.p_text_quantity.text = text
    end
    return self
end

function City3DBubbleStandard:ShowBubbleCheckImg(showCheck)
    if self.showCheckImg ~= showCheck then
        self.showCheckImg = showCheck
        self.p_icon_check:SetVisible(showCheck)
    end
    return self
end

function City3DBubbleStandard:ShowSubIcon(icon)
    local showSubIcon = not string.IsNullOrEmpty(icon)
    if self.showSubIcon ~= showSubIcon then
        self.showSubIcon = showSubIcon
        self.p_bubble_1:SetActive(showSubIcon)
    end

    if showSubIcon then
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_status_1)
    end
    return self
end

function City3DBubbleStandard:SetBubbleIconSortingOrder(sortingOrder)
    local rawValue = math.clamp(sortingOrder, DefaultSortingOrder.BubbleIconMin, DefaultSortingOrder.BubbleIconMax)
    if rawValue ~= self.bubbleIconSortingOrder then
        self.bubbleIconSortingOrderComp.SortingOrder = rawValue
        self.bubbleIconSortingOrder = rawValue
    end
    return self
end

function City3DBubbleStandard:ShowProgress(progress, icon, red, timeText, showDanger, showGear, numberText)
    self:SwitchRootStatus(Status.Progress)
    self:ShowProgressIcon(icon)
    self:ChangeProgressBack(red and ProgressBackStats.Red or ProgressBackStats.Blue)
    self:UpdateProgress(progress or 0)
    self:ShowTimeText(timeText)
    self:ShowNumberText(numberText)

    self:ShowDangerImg(showDanger == true)
    self:ShowGear(showGear == true)
    return self
end

function City3DBubbleStandard:ShowProgressIcon(icon)
    local showProgressIcon = not string.IsNullOrEmpty(icon)
    local progressIconDirty = self.progressIconPath ~= icon
    if self.showProgressIcon ~= showProgressIcon then
        self.showProgressIcon = showProgressIcon
        if self.p_icon then
            self.p_icon:SetVisible(showProgressIcon)
        end
    end
    if showProgressIcon and progressIconDirty then
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon)
    end
    self.progressIconPath = icon
    return self
end

function City3DBubbleStandard:ShowRedProgress(red)
    return self:ChangeProgressBack(red and ProgressBackStats.Red or ProgressBackStats.Blue)
end

function City3DBubbleStandard:ChangeProgressBack(backStatus)
    if self.progressBackStatus == backStatus then return self end

    self.progressBackStatus = backStatus
    self.p_bar_blue:SetVisible(backStatus == ProgressBackStats.Blue)
    self.p_bar_red:SetVisible(backStatus == ProgressBackStats.Red)
    return self
end

function City3DBubbleStandard:UpdateProgress(progress)
    if self.progressBackStatus == ProgressBackStats.Blue then
        self.p_bar_blue.fillAmount = math.clamp01(progress)
    elseif self.progressBackStatus == ProgressBackStats.Red then
        self.p_bar_red.fillAmount = math.clamp01(progress)
    end
    return self
end

function City3DBubbleStandard:ShowTimeText(text)
    local isStr = type(text) == "string"
    if self.showTimeText ~= isStr then
        self.showTimeText = isStr
        self.p_text_time:SetVisible(isStr)
    end
    if isStr then
        self.p_text_time.text = text
    end
    return self
end

function City3DBubbleStandard:ShowNumberText(numberText)
    local isStr = type(numberText) == "string"
    if self.showNumberText ~= isStr then
        self.showNumberText = isStr
        self.p_text_number:SetVisible(isStr)
    end
    if isStr then
        self.p_text_number.text = numberText
    end
    return self
end

function City3DBubbleStandard:ShowDangerImg(showDanger)
    if self.showDangerImg ~= showDanger then
        self.showDangerImg = showDanger
        self.p_icon_danger:SetVisible(showDanger)
    end
    return self
end

function City3DBubbleStandard:ShowGear(showGear, playGearAni)
    if playGearAni == nil then
        playGearAni = showGear
    end

    if self.showGear ~= showGear then
        self.showGear = showGear
        self.p_icon_process:SetActive(showGear)
        
        if playGearAni then
            self:PlayGearAni()
        else
            self:ResetGearAni()
        end
    end
    return self
end

function City3DBubbleStandard:SetProgressIconSortingOrder(sortingOrder)
    local rawValue = math.clamp(sortingOrder, DefaultSortingOrder.ProcessIconMin, DefaultSortingOrder.ProcessIconMax)
    if rawValue ~= self.progressIconSortingOrder then
        self.progressIconSortingOrderComp.SortingOrder = rawValue
        self.progressIconSortingOrder = rawValue
    end
end

function City3DBubbleStandard:EnableGearAnim(isPlay)
    if not self.showGear then return self end

    if isPlay then
        self:PlayGearAni()
    else
        self:ResetGearAni()
    end
    return self
end

function City3DBubbleStandard:ShowBan()
    self:SwitchRootStatus(Status.Ban)
    return self
end

function City3DBubbleStandard:EnableTrigger(flag)
    if self.enableTrigger ~= flag then
        self.enableTrigger = flag
        self.p_bubble_collider.enabled = flag
        self.p_progress_collider.enabled = flag
    end
    return self
end

function City3DBubbleStandard:SetOnTrigger(callback, tile)
    self.callback = callback
    self.cityTrigger:SetOnTrigger(callback, tile, true)
    return self
end

function City3DBubbleStandard:ClearTrigger()
    if self.callback ~= nil then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.callback = nil
    end
    return self
end

function City3DBubbleStandard:Reset()
    self:SwitchRootStatus(defaultRootStatus)
    self:ResetCurrentStatus()
    self:ShowRoot(true)
    self:ResetAllAni()
    self:ClearTrigger()
    self:EnableTrigger(true)
    if self.showBubbleEffectHandle then
        self.showBubbleEffectHandle:Delete()
    end
    self.showBubbleEffectHandle = nil
    return self
end

function City3DBubbleStandard:ShowRoot(flag)
    self.transform:SetVisible(flag)
    return self
end

function City3DBubbleStandard:ResetAllAni()
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7)
    return self
end

function City3DBubbleStandard:GetFadeOutDuration()
    return self.p_vx_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom3)
end

function City3DBubbleStandard:PlayInAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, onFinish)
    return self
end

function City3DBubbleStandard:PlayProgressInAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, onFinish)
    return self
end

function City3DBubbleStandard:PlayOutAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, onFinish)
    return self
end

function City3DBubbleStandard:PlayProgressOutAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4, onFinish)
    return self
end

function City3DBubbleStandard:PlayLoopAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5, onFinish)
    return self
end

function City3DBubbleStandard:PlayGearAni(onFinish)
    self.p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6, onFinish)
    return self
end

function City3DBubbleStandard:ResetGearAni()
    self.p_vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom6)
    return self
end

function City3DBubbleStandard:PlayRewardAnim()
    self.trigger_new:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    return self
end

function City3DBubbleStandard:ResetRewardAnim()
    self.trigger_new:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    return self
end

function City3DBubbleStandard:PlayTaskHintAnim()
    self.trigger_new:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    return self
end

function City3DBubbleStandard:ResetTaskHintAnim()
    self.trigger_new:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    return self
end

function City3DBubbleStandard:SetBubbleVerticalPos()
    self.p_rotation.localPosition = CS.UnityEngine.Vector3(0,4,0)
end

function City3DBubbleStandard:ResetBubbleVerticalPos()
    self.p_rotation.localPosition = CS.UnityEngine.Vector3(0,0,0)
end

return City3DBubbleStandard