local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
local QueuedTask = require('QueuedTask')
local EventConst = require('EventConst')
local KingdomMapUtils = require('KingdomMapUtils')
local GuideConst = require('GuideConst')
local Utils = require('Utils')
local UIHelper = require('UIHelper')

---@class GuideUtils
local GuideUtils = class("GuideUtils")

---@param id number @GuideCallConfigCell:Id()
function GuideUtils.GotoByGuide(id)
    local keyMap = FPXSDKBIDefine.ExtraKey.go_to
    local extraDic = {}
    extraDic[keyMap.id] = id
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.go_to, extraDic)
    g_Logger.LogChannel('GuideModule', "GotoByGuide: " .. tonumber(id))
    local callCfgCell = ConfigRefer.GuideCall:Find(id)
    if callCfgCell then
        local triggerFunc = function()
            ModuleRefer.GuideModule:StopCurrentStep()
            return ModuleRefer.GuideModule:CallGuide(id, nil)
        end
        if callCfgCell:NeedToWorld() > 0 and KingdomMapUtils.IsCityState() then
            KingdomMapUtils.GetKingdomScene():LeaveCity()
            local queuedTask = QueuedTask.new()
            queuedTask:WaitEvent(EventConst.FIRST_UPDATE_AOI_RECEIVED, nil, function()
                return true
            end):DoAction(function()
                    triggerFunc()
                end
            ):Start()
        elseif callCfgCell:NeedToCity() > 0 and KingdomMapUtils.IsMapState() then
            KingdomMapUtils.GetKingdomScene():ReturnMyCity()
            local queuedTask = QueuedTask.new()
            queuedTask:WaitEvent(EventConst.CITY_SET_ACTIVE, nil, function()
                return true
            end):DoAction(function()
                    triggerFunc()
                end
            ):Start()
        else
            return triggerFunc()
        end
        return true
    end
    return false
end

---@param itemId number @ItemConfigCell:Id()
---@param index number
---@return boolean
function GuideUtils.GotoItemAccess(itemId,index)
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if not itemCfg then return false end
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return false end
    local accessId = getMoreCfg:Goto(index):Goto()
    return GuideUtils.GotoByGuide(accessId)
end

function GuideUtils.GetAllPossibleInvolvedAssets()
    local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
    local set = HashSetString()
    set:Add('ui_guide_finger')
    set:Add('city_root')

    for i, v in ConfigRefer.Guide:ipairs() do
        ---@type GuideConfigCell
        local cell = v
        if cell:StringParamsLength() > 0 then
            local uiMediatorName = cell:StringParams(1)
            local prefabName = g_Game.UIManager:GetPrefabName(uiMediatorName)
            if prefabName then
                set:Add(prefabName)
                g_Logger.Log('GetAllPossibleInvolvedAssets: %s', prefabName)
            end
        end
    end

    local otherMediators = {
        'SimpleToastMediator',
        'HudCloudScreen',
    }
    for _, uiMediatorName in ipairs(otherMediators) do
        local prefabName = g_Game.UIManager:GetPrefabName(uiMediatorName)
        if prefabName then
            set:Add(prefabName)
            g_Logger.Log('GetAllPossibleInvolvedAssets: %s', prefabName)
        end
    end

    return set
end

---@return boolean
function GuideUtils.IsInMyCityExplorMode()
    ---@type KingdomScene
    local curScene = g_Game.SceneManager.current
    if not curScene or curScene:GetName() ~= require("KingdomScene").Name or not curScene:IsInMyCity() then
        return false
    end
    local city = curScene:GetCurrentViewedCity()
    return city:IsInSingleSeExplorerMode()
end

---@return City | nil
function GuideUtils.FindMyCity()
    ---@type KingdomScene
    local curScene = g_Game.SceneManager.current
    local myCity = nil
    if curScene and curScene:GetName() == 'KingdomScene' then
        if curScene:IsInMyCity() then
            myCity = ModuleRefer.CityModule.myCity
        end
    end
    return myCity
end

---@param tiles CityCellTile[]
---@return CityCellTile | nil
function GuideUtils.GetNearestTile(tiles)
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        return nil
    end
    local _, x, y, _ = myCity:RaycastCityCellTile(CS.UnityEngine.Vector3(CS.UnityEngine.Screen.width / 2, CS.UnityEngine.Screen.height / 2))
    local nearestLength = math.maxinteger
    local nearestTile = nil
    for _, tile in ipairs(tiles) do
        if not nearestTile then
            nearestTile = tile
            nearestLength = math.abs(tile.x - x) + math.abs(tile.y - y)
        else
            local length = math.abs(tile.x - x) + math.abs(tile.y - y)
            if length < nearestLength then
                nearestTile = tile
                nearestLength = length
            end
        end
    end
    return nearestTile
end

function GuideUtils.IsTileHasByCreepBlock(value, type)
    if type == 1 then
        return value == require("CreepStatus").ACTIVE
    elseif type == 2 then
        return false
    end
    return false
end

function GuideUtils.NeedFocus(target, dstTarget)
    local needFocus = false
    if (target and target.type ~= GuideConst.TargetTypeEnum.UITrans)
        or (dstTarget
            and dstTarget.type ~= GuideConst.TargetTypeEnum.UITrans
            and dstTarget.type ~= GuideConst.TargetTypeEnum.ScreenPos)
    then
        needFocus = true
    end
    return needFocus
end

function GuideUtils.GetTargetPosWS(targetData)
    if not targetData then return nil end
    if targetData.type == GuideConst.TargetTypeEnum.UITrans and Utils.IsNotNull(targetData.target) then
        return targetData.target.position
    elseif targetData.type == GuideConst.TargetTypeEnum.CityTile and Utils.IsNotNull(targetData.target) and Utils.IsNotNull(targetData.target.gridView) then
        return targetData.target:GetWorldCenter()
    elseif targetData.type == GuideConst.TargetTypeEnum.Troop and Utils.IsNotNull(targetData.target) then
        return targetData.target:GetPosition()
    elseif targetData.type == GuideConst.TargetTypeEnum.WorldPos then
        return targetData.position
    elseif targetData.type == GuideConst.TargetTypeEnum.Transform and Utils.IsNotNull(targetData.target) then
        return targetData.target.position
    elseif targetData.type == GuideConst.TargetTypeEnum.Mob and Utils.IsNotNull(targetData.target) then
        return targetData.target:GetPosition()
    else
        return targetData.position
    end
end

function GuideUtils.GetTargetFocusPosWS(target, dstTarget)
    local retTarget = nil
    local focusPosWS = GuideUtils.GetTargetPosWS(target)
    if focusPosWS then
        retTarget = target
    end
    if focusPosWS == nil and dstTarget then
        focusPosWS = GuideUtils.GetTargetPosWS(dstTarget)
        if focusPosWS then
            retTarget = dstTarget
        end
    end
    return focusPosWS, retTarget
end

function GuideUtils.SimulatClickTarget(targetType, uiTrans, uiPos, offset)
    if not uiPos then return end
    local screenPos = UIHelper.UIPos2ScreenPos(uiPos)
    if offset then
        screenPos = screenPos + offset * g_Game.UIManager:GetUIRootCanvasScaler()
    end
    if targetType == GuideConst.TargetTypeEnum.UITrans then
        if Utils.IsNull(uiTrans) then
            return
        end
        local eventData = CS.UnityEngine.EventSystems.PointerEventData(nil)
        eventData.position = CS.UnityEngine.Vector2(screenPos.x,screenPos.y)
        local downHandlers = uiTrans.gameObject:GetComponents(typeof(CS.UnityEngine.EventSystems.IPointerDownHandler))
        if downHandlers and downHandlers.Length > 0 then
            for i = 0, downHandlers.Length - 1 do
                downHandlers[i]:OnPointerDown(eventData)
            end
        end
        --点击后，UI可能会消失
        if Utils.IsNull(uiTrans) then
            return
        end
        local clickHandlers = uiTrans.gameObject:GetComponents(typeof(CS.UnityEngine.EventSystems.IPointerClickHandler))
        if clickHandlers and clickHandlers.Length > 0 then
            for i = 0, clickHandlers.Length - 1 do
                clickHandlers[i]:OnPointerClick(eventData)
            end
        end
        --点击后，UI可能会消失
        if Utils.IsNull(uiTrans) then
            return
        end
        --IPointerUpHandler
        local upHandlers = uiTrans.gameObject:GetComponents(typeof(CS.UnityEngine.EventSystems.IPointerUpHandler))
        if upHandlers and upHandlers.Length > 0 then
            for i = 0, upHandlers.Length - 1 do
                upHandlers[i]:OnPointerUp(eventData)
            end
        end
    elseif targetType == GuideConst.TargetTypeEnum.CityTile then
        g_Game.GestureManager:SimulateClick(screenPos)
    elseif targetType == GuideConst.TargetTypeEnum.WorldPos then
        local curScene = g_Game.SceneManager.current
        local sceneName
        if curScene then
            sceneName = curScene:GetName()
            if sceneName == 'SeScene' then
                local seEnv = require('SEEnvironment').Instance()
                if seEnv then
                    seEnv:SimulateScreenClick(screenPos,true)
                end
            elseif sceneName == 'KingdomScene' then
                g_Game.GestureManager:SimulateClick(screenPos)
            end
        end
    elseif targetType == GuideConst.TargetTypeEnum.Transform then
        g_Game.GestureManager:SimulateClick(screenPos)
    elseif targetType == GuideConst.TargetTypeEnum.Mob then
        g_Game.GestureManager:SimulateClick(screenPos)
    end
end

---@param step BaseGuideStep
---@param callback fun()
function GuideUtils.FocusSceneCamera(step, callback)
    local needFocus = GuideUtils.NeedFocus(step.target, step.dragTarget)
    if not needFocus then
        if callback then
            callback()
        end
        return
    end
    local focusPosWS,_ = GuideUtils.GetTargetFocusPosWS(step.target, step.dstTarget)
    local curScene = g_Game.SceneManager.current
    --kingdom scene only
    ---@type BasicCamera
    local sceneCam = nil
    if curScene then
        sceneCam = curScene.basicCamera
    end
    if sceneCam and focusPosWS then
        local lookatPos = sceneCam:GetLookAtPosition()
        local offset = focusPosWS - lookatPos
        offset.y = 0
        step:ShowGuideFinger(true)
        if not sceneCam:Idle() then
            sceneCam:ForceGiveUpTween()
            sceneCam:StopSlidingWithEvt()
        end
        local moveTime = step:GetCfg():CameraMoveTime()  > 0 and step:GetCfg():CameraMoveTime()  or 0.2
        if step.target and step.target.camerSize and step.target.camerSize > 0 then
            sceneCam:ZoomToWithFocus(step.target.camerSize, CS.UnityEngine.Vector3(0.5, 0.5), focusPosWS, moveTime, callback)
        else
            sceneCam:LookAt(focusPosWS, moveTime, callback)
        end
    else
        if callback then
            callback()
        end
    end
end

function GuideUtils.Range2Rect(range)
    local min = - range / 2.0
    return CS.UnityEngine.Rect(min, min, range, range)
end

function GuideUtils.GetUIPosFromRectTransform(rectTransform)
    local uiPos = nil
    local uiRect = nil
    local uiTrans = nil

    --ui trans
    if Utils.IsNotNull(rectTransform) then
        uiRect = rectTransform.rect
        uiPos = g_Game.UIManager:GetUIRoot().transform:InverseTransformPoint(rectTransform.position)
        uiTrans = rectTransform
    end
    return uiPos,uiRect,uiTrans
end

function GuideUtils.GetTargetUIPos(targetData)
    if not targetData then return nil end

    ---2D element
    if targetData.type == GuideConst.TargetTypeEnum.ScreenPos then
        return targetData.position, GuideUtils.Range2Rect(targetData.range)
    end

    if targetData.type == GuideConst.TargetTypeEnum.UITrans then
        --ui trans
        return GuideUtils.GetUIPosFromRectTransform(targetData.target)
    end

    local uiPos
    local uiRect
    ---3D element
    local curScene = g_Game.SceneManager.current
    local sceneCam = nil
    local sceneName = nil
    if curScene then
        sceneName = curScene:GetName()
        if sceneName == 'SeScene' then
            local seEnv = require('SEEnvironment').Instance()
            if seEnv ~= nil then
                sceneCam = seEnv._camera
            end
        elseif sceneName == 'KingdomScene' then
            sceneCam = curScene.camera
        elseif KingdomMapUtils.IsNewbieState() then
            sceneCam = curScene.camera
        end
    end

    if not sceneCam then
        uiPos = CS.UnityEngine.Vector3.zero
        uiRect = CS.UnityEngine.Rect()
        return uiPos, uiRect
    end
    local posWS = GuideUtils.GetTargetPosWS(targetData)
    if posWS and sceneCam then
        uiPos = UIHelper.WorldPos2UIPos(sceneCam,posWS)
        uiRect = GuideUtils.Range2Rect(targetData.range)
    else
        uiPos = CS.UnityEngine.Vector3.zero
        uiRect = CS.UnityEngine.Rect()
    end
    return uiPos, uiRect
end

function GuideUtils.AutoClickTarget(target)
    if target == nil then
        return false
    end
    local uiPos, _, uiTrans = GuideUtils.GetTargetUIPos(target)
    if uiPos then
        GuideUtils.SimulatClickTarget(target.type, uiTrans, uiPos, target.offset)
    end
end

return GuideUtils