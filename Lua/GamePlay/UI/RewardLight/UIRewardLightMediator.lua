---scene: scene_common_reward_light
local BaseUIMediator = require ('BaseUIMediator')
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')
local Utils = require('Utils')
local TimerUtility = require('TimerUtility')
local ConfigRefer = require("ConfigRefer")
local AudioConsts = require("AudioConsts")
local EventConst = require('EventConst')

local Ease = CS.DG.Tweening.Ease

local Vector3 = CS.UnityEngine.Vector3
local orginCount = 31

---@class UIRewardLightMediator : BaseUIMediator
local UIRewardLightMediator = class('UIRewardLightMediator', BaseUIMediator)

function UIRewardLightMediator:OnCreate()
    self.root = self:GameObject("")
    self.items = {}
    for i = 1, orginCount do
        self.items[#self.items + 1] = {go = self:GameObject('p_item_' .. i), comp = self:LuaObject('p_item_' .. i), isUsing = false, index = i}
        self.items[i].go:SetActive(false)
    end
    self.compItem1 = self:LuaBaseComponent('p_item_1')
    ---@type Timer
    self.timers = {}
end

function UIRewardLightMediator:AddRewardList(itemInfos)
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if not hudMediator then
        return
    end
    if not self.lockTimers then
        self.lockTimers = {}
    end
    self:OnShowReward(itemInfos)
end

---@param itemInfos table {{id, count}}
function UIRewardLightMediator:OnShow(itemInfos)
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if not hudMediator then
        return
    end
    self.lockTimers = {}
    self:OnShowReward(itemInfos)
end

function UIRewardLightMediator:OnClose()
    ModuleRefer.RewardModule:ClearRewardUIId()
    
    for _, timer in pairs(self.timers) do
        TimerUtility.StopAndRecycle(timer)
    end
    table.clear(self.timers)
end

function UIRewardLightMediator:OnHide()
    for _, item in ipairs(self.items) do
        if Utils.IsNotNull(item.go) then
            item.go.transform:DOKill()
            item.go:SetActive(false)
        end
    end
    if self.closeTimer then
        TimerUtility.StopAndRecycle(self.closeTimer)
        self.closeTimer = nil
    end
    for _, timer in pairs(self.lockTimers or {}) do
        if timer then
            TimerUtility.StopAndRecycle(timer)
        end
    end
end

function UIRewardLightMediator:GetItemsFromPool(count)
    local idleItems = {}
    for _, item in ipairs(self.items) do
        if not item.isUsing then
            idleItems[#idleItems + 1] = item
            item.isUsing = true
            if #idleItems == count then
                break
            end
        end
    end
    -- local lackCount = count - #idleItems
    -- if lackCount > 0 then
    --     local curCount = #self.items
    --     for i = 1, lackCount do
    --         local comp = UIHelper.DuplicateUIComponent(self.compItem1, self.root.transform)
    --         local index = curCount + i
    --         local go = comp.gameObject
    --         go.transform.name = 'p_item_' .. index
    --         local item = {go = go, comp = comp.Lua, isUsing = true, index = index}
    --         self.items[index] = item
    --         idleItems[#idleItems + 1] = item
    --     end
    -- end
    return idleItems
end

function UIRewardLightMediator:ReturnItemToPool(item)
    if Utils.IsNotNull(item.go) then
        item.go.transform:DOKill()
        item.comp:StopEffect()
        item.go:SetActive(false)
        self.items[item.index].isUsing = false
    end
end

function UIRewardLightMediator:OnShowReward(itemInfos)
    if self.closeTimer then
        TimerUtility.StopAndRecycle(self.closeTimer)
        self.closeTimer = nil
    end
    local usingItems = self:GetItemsFromPool(#itemInfos)
    if #usingItems == 0 then
        return
    end
    -- local startPos = self:GetStartPos((itemInfos or {})[1].reason)
    for index, item in ipairs(usingItems) do
        item.comp:OnFeedData(itemInfos[index])
        item.go:SetActive(true)
        item.go.transform.localScale = Vector3.zero
        item.go.transform.localPosition = Vector3.zero
        -- if startPos then
        --     item.go.transform.position = startPos
        -- else
        local y = math.random(-10, 10)
        local x = math.random(-10, 10)
        item.go.transform.localPosition = Vector3(x, y, 0)
        --end
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_large_gifts_01)
    self:StartTween(usingItems)
    self:StartLockPosTimer(usingItems)
end

function UIRewardLightMediator:StartTween(usingItems)
    local floatingIndexes = {}
    for _, item in ipairs(usingItems) do
        if item.go.activeSelf then
            if item.comp:IsFixedScreenPos() then
                if self:IsInCity() then
                    item.go.transform:DOScale(1, 0.8):SetEase(Ease.InOutElastic):OnComplete(function()
                        self:ReturnItemToPool(item)
                    end)
                else
                    self:ReturnItemToPool(item)
                end
            else
                local itemId = item.comp:GetItemId()
                local targetPosition = self:GetItemTargetPos(itemId)
                local targetScale = self:GetItemScale(itemId)
                if targetPosition then
                    if true then
                        if not floatingIndexes[targetPosition] then
                            floatingIndexes[targetPosition] = 0
                        end
                        floatingIndexes[targetPosition] = floatingIndexes[targetPosition] + 1
                        item.go.transform.eulerAngles = Vector3(0, 0, item.comp:GetRotation())
                        local targetX = self:GetRandomNumber()
                        local targetY = self:GetRandomNumber()
                        local timer1 = TimerUtility.DelayExecute(function()
                            item.go.transform:DOLocalMove(item.go.transform.localPosition + Vector3(targetX, targetY, 0), 0.25):SetEase(Ease.Flash)
                            item.go.transform:DOScale(item.comp:GetScale(), item.comp:GetScaleTime()):SetEase(item.comp:GetScaleEase()):OnComplete(function()
                                local originPos = item.go.transform.position
                                local offset = targetPosition - originPos
                                local curve = item.comp:GetFlyCurve()
                                local duration = item.comp:GetFlyTime() + floatingIndexes[targetPosition] * 0.012
                                local ease = item.comp:GetFlyEase()
                                local wayPoints = {}
                                local wayPointsCount = duration * 60
                                for i = 1, wayPointsCount do
                                    local percent = i / wayPointsCount
                                    local curveValue = curve:Evaluate(percent)
                                    wayPoints[#wayPoints + 1] = originPos + Vector3(offset.x * percent, offset.y * curveValue, 0)
                                end
                                item.go.transform:DOPath(wayPoints, duration):SetEase(ease):OnComplete(function()
                                    item.comp:PlayEffect()
                                    local timer2 = TimerUtility.DelayExecute(function()
                                        self:ReturnItemToPool(item)
                                    end, 0.5)
                                    table.insert(self.timers, timer2)
                                end)
                                item.go.transform:DOScale(targetScale * 0.5, duration):SetEase(Ease.OutQuad)
                                item.go.transform:DORotate(Vector3(0, 0, item.comp:GetFlyRotation()), duration)
                            end)
                        end, math.random(0, 1) * 0.1)
                        table.insert(self.timers, timer1)
                    else
                        item.go.transform:DOScale(targetScale, 0.5):SetEase(Ease.InOutElastic):OnComplete(function()
                            item.go.transform:DOLocalMove(item.go.transform.localPosition - Vector3(50, -50, 0), 0.1):SetEase(Ease.OutCubic):OnComplete(function()
                                item.go.transform:DOMove(targetPosition, 0.4):SetEase(Ease.InCubic)
                                item.go.transform:DOScale(targetScale * 0.5, 0.4):SetEase(Ease.OutQuad):OnComplete(function()
                                    item.comp:PlayEffect()
                                    local timer3 = TimerUtility.DelayExecute(function()
                                        self:ReturnItemToPool(item)
                                    end, 0.5)
                                    table.insert(self.timers, timer3)
                                end)
                            end)
                        end)
                    end
                end
            end
        end
    end
end

function UIRewardLightMediator:GetRandomNumber()
    local rangeMin = -100
    local rangeMax = 100
    return math.random(rangeMin, rangeMax)
end

function UIRewardLightMediator:IsInCity()
    local _scene = g_Game.SceneManager.current
    if _scene:GetName() == require('KingdomScene').Name then
        if _scene:IsInMyCity() then
            return true
        end
    end
    return false
end

function UIRewardLightMediator:StartLockPosTimer(usingItems)
    for index, item in ipairs(usingItems) do
        if self.lockTimers[item.index] ~= nil then
            TimerUtility.StopAndRecycle(self.lockTimers[item.index])
        end
        self.lockTimers[item.index] = TimerUtility.StartFrameTimer(function()
            if item.go.activeSelf and self:IsInCity() then
                if item.comp:IsFixedScreenPos() then
                    local pos = item.comp:GetCoorPos()
                    local city = ModuleRefer.CityModule.myCity
                    if city == nil then
                        return
                    end
                    local worldPos = city:GetWorldPositionFromCoord(pos.X, pos.Y)
                    if worldPos then
                        local screenPos = city.camera.mainCamera:WorldToScreenPoint(worldPos)
                        screenPos.z = 0
                        local uiCamera = g_Game.UIManager:GetUICamera()
                        local result = uiCamera:ScreenToWorldPoint(screenPos)
                        item.go.transform.position = result
                        local x = 0
                        if index > 1 then
                            if index % 2 == 0 then
                                x = index * 60
                            else
                                x = - math.floor(index / 2) * 120
                            end
                        end
                        item.go.transform.localPosition = item.go.transform.localPosition + Vector3(x, 0, 0)
                    end
                end
            end
        end, 0, -1, true)
    end
end

-- function UIRewardLightMediator:GetStartPos(reason)
--     return ModuleRefer.RewardModule:PopRerwdDropPos(reason)
-- end

function UIRewardLightMediator:GetItemTargetPos(itemId)
    local targetPos
    local resId = ModuleRefer.InventoryModule:GetResTypeByItemId(itemId)
    local topMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.BagMediator)
    if topMediator then
        if itemId == ConfigRefer.ConstMain:UniversalCoin() then
            targetPos = topMediator:GetCoinPos()
        elseif ModuleRefer.RewardModule:IsMoney(itemId) then
            targetPos = topMediator:GetMoneyPos()
        elseif resId ~= nil then
            targetPos = topMediator:GetResCellPos(resId)
        end
    end
    if targetPos then
        return targetPos
    end
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if not hudMediator then
        return
    end
    if itemId == ConfigRefer.ConstMain:UniversalCoin() then
        targetPos = hudMediator:GetCoinPos()
    elseif ModuleRefer.RewardModule:IsMoney(itemId) then
        targetPos = hudMediator:GetMoneyPos()
    elseif resId ~= nil then
        targetPos = hudMediator:GetResCellPos(resId)
    elseif itemId == 51001 then
        local radarMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.RadarMediator)
        if radarMediator then
            targetPos = radarMediator:GetItemPos()
        else
            local bagBtn = hudMediator:GetTargetEventBtn("BagMediator")
            targetPos = bagBtn.gameObject.transform.position
        end
    elseif itemId == ModuleRefer.NoviceModule:GetScoreItemId() then
        local noviceMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.NoviceTaskMediator)
        if noviceMediator then
            targetPos = noviceMediator:GetItemPos()
        else
            local bagBtn = hudMediator:GetTargetEventBtn("BagMediator")
            targetPos = bagBtn.gameObject.transform.position
        end
    elseif itemId == ConfigRefer.ConstMain:CityExpItem() then
        targetPos = hudMediator:GetCorePos()
    elseif itemId == require("EarthRevivalDefine").ProgressItemId then
        local earthRevivalMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.EarthRevivalMediator)
        if earthRevivalMediator then
            targetPos = earthRevivalMediator:GetItemPos()
        else
            local bagBtn = hudMediator:GetTargetEventBtn("BagMediator")
            targetPos = bagBtn.gameObject.transform.position
        end
    elseif ModuleRefer.CityConstructionModule:IsFurnitureRelativeItem(itemId) then
        targetPos = hudMediator:GetHammerPos()
    elseif itemId == require("AllianceModuleDefine").AllianceCurrencyItemId then
        local allianceCurrencyMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.AllianceTechResearchMediator)
        if allianceCurrencyMediator then
            targetPos = allianceCurrencyMediator:GetAllianceCurrencyItemPos()
        else
            local bagBtn = hudMediator:GetTargetEventBtn("BagMediator")
            targetPos = bagBtn.gameObject.transform.position
        end
        local res = {}
        res[itemId] = 1
        g_Game.EventManager:TriggerEvent(EventConst.UI_ALLIANCE_TECH_CURRENCY_UPDATE,res)
    end
    if not targetPos then
        local bagBtn = hudMediator:GetTargetEventBtn("BagMediator")
        targetPos = bagBtn.gameObject.transform.position
    end
    return targetPos
end

function UIRewardLightMediator:GetItemScale(itemId)
    local scale = 1
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if not hudMediator then
        return
    end
    local resId = ModuleRefer.InventoryModule:GetResTypeByItemId(itemId)
    if itemId == ConfigRefer.ConstMain:UniversalCoin() or resId then
        scale = 0.5
    end
    return scale
end

return UIRewardLightMediator
