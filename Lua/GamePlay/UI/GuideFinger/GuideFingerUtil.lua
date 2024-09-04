local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local ConfigRefer = require('ConfigRefer')
local GuideFingerType = require('GuideFingerType')
local Utils = require("Utils")
local GuideUtils = require('GuideUtils')
---@class GuideFingerUtil
local GuideFingerUtil = class('GuideFingerUtil')

---@param worldPos CS.UnityEngine.Vector3|fun():CS.UnityEngine.Vector3
---@param fingerPosOffset CS.UnityEngine.Vector3 or nil
---@return number @runtimeId of an UIMediator
function GuideFingerUtil.ShowGuideFingerByWorldPos(worldPos, fingerPosOffset)
    if not GuideFingerUtil.CheckCanOpen() then
        return
    end
    local data = {}
    data.useWorldPos = true
    data.worldPos = worldPos
    data.fingerType = GuideFingerType.RightBottom
    data.fingerPosOffset = fingerPosOffset
    return g_Game.UIManager:Open(UIMediatorNames.UIGuideFingerMediator,data)
end

function GuideFingerUtil.ShowGuideFingerOnBubbleTransform(bubbleTrans)
    if not GuideFingerUtil.CheckCanOpen() then
        return
    end
    ---@type CS.UnityEngine.BoxCollider
    local touchCollider = bubbleTrans.gameObject:GetComponent(typeof(CS.UnityEngine.BoxCollider))
    if Utils.IsNotNull(touchCollider) then
        GuideFingerUtil.ShowGuideFingerByWorldPos(function()
            if Utils.IsNotNull(touchCollider) then
                return touchCollider.transform:TransformPoint(touchCollider.center)
            end
            return nil
        end)
    else
        GuideFingerUtil.ShowGuideFingerByWorldPos(function()
            if Utils.IsNotNull(bubbleTrans) then
                return bubbleTrans.position
            end
            return nil
        end)
    end
end

function GuideFingerUtil.CheckCanOpen()
    if g_Game.UIManager:IsOpenedByType(UIMediatorNames.UIGuideFingerMediator) then
        return false
    end

    if g_Game.UIManager:IsOpenedByType(CS.DragonReborn.UI.UIMediatorType.Dialog) then
        return false
    end

    return true
end

---@param config GuideConfigCell
---@param targetData StepTargetData
---@param dstTargetData StepTargetData
---@return GuideFingerUIData
function GuideFingerUtil.CreateUIDataFromConfig(config,targetData,dstTargetData)
    if not config  then
        return nil
    end
    ---@type GuideFingerUIData
    local uiData = {}
    --Get Config Data
    uiData.guideId = config:Id()
    uiData.guideType = config:Type()
    uiData.maskType = config:MaskType()
    local maskSize = config:MaskSize()
    uiData.maskSize = CS.UnityEngine.Vector2(maskSize:X(),maskSize:Y())
    local maskOffset = config:MaskOffset()
    uiData.maskOffset = CS.UnityEngine.Vector2(maskOffset:X(),maskOffset:Y())
    local hotZone = config:HotZone()
    uiData.hotZone = CS.UnityEngine.Vector2(hotZone:X(),hotZone:Y())
    uiData.fingerType = config:FingerType()
    local infoContain = config:TextContain()
    if not string.IsNullOrEmpty(infoContain) then
        uiData.infoContain = infoContain
        uiData.infoImage = config:TextImage()
        uiData.infoAnchorMin,uiData.infoAnchorMax = UIHelper.GetAnchorValue(config:TextAnchor())
        local infoOffset = config:TextOffset()
        uiData.infoOffset = CS.UnityEngine.Vector2(infoOffset:X(),infoOffset:Y())
    end
    uiData.targetData    = targetData
    uiData.dstTargetData = dstTargetData

    local dragId = config:Drag()
    if dragId and dragId > 0 then
        local dragCgf = ConfigRefer.GuideGesture:Find(dragId)
        uiData.hideDragArrow = dragCgf:HideArrow()
    end
    g_Logger.LogChannel("GuideFingerUtil", "CreateUIDataFromConfig guideID = "..config:Id())

    return uiData
end

---@param uiData GuideFingerUIData
---@return CS.UnityEngine.Vector3,CS.UnityEngine.Rect,CS.UnityEngine.RectTransform
function GuideFingerUtil.GetUIPosFromeUIData(uiData)
    if not uiData then
        return nil
    end
    local zonePos,zoneRect,zoneTrans = nil
    if uiData.targetData then
        zonePos,zoneRect,zoneTrans = GuideUtils.GetTargetUIPos(uiData.targetData)
    end
    return zonePos,zoneRect,zoneTrans
end

return GuideFingerUtil