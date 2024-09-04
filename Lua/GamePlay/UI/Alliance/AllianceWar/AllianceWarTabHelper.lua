local KingdomMapUtils = require("KingdomMapUtils")
local MapUtils = CS.Grid.MapUtils
local CameraConst = require("CameraConst")
local KingdomConstant = require("KingdomConstant")
local EventConst = require("EventConst")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local ModuleRefer = require("ModuleRefer")

---@class AllianceWarTabHelper
---@field new fun():AllianceWarTabHelper
local AllianceWarTabHelper = sealedClass('AllianceWarTabHelper')

function AllianceWarTabHelper.CalculateMapDistance(posAx, posAz, posBx, posBz)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    posAx = posAx * staticMapData.UnitsPerTileX
    posAz = posAz * staticMapData.UnitsPerTileZ
    local posAy = KingdomMapUtils.SampleHeight(posAx, posAz)
    local posA = CS.UnityEngine.Vector3(posAx, posAy, posAz)
    posBx = posBx * staticMapData.UnitsPerTileX
    posBz = posBz * staticMapData.UnitsPerTileZ
    local posBy = KingdomMapUtils.SampleHeight(posBx, posBz)
    local posB = CS.UnityEngine.Vector3(posBx, posBy, posBz)
    return CS.UnityEngine.Vector3.Distance(posA, posB)
end

---@param x number
---@param y number
---@param waiAndShowUnit boolean
---@param context any
---@param callback fun(tile:MapRetrieveResult, context:any)
---@param moveDuration number|nil
function AllianceWarTabHelper.GoToCoord(x, y, waiAndShowUnit, depth, isEnterMap, context, callback, enterSize, noEnterZoomDuration, moveDuration)
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.KingdomScene_radar_world_unlock)
    if not unlocked then
        ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(NewFunctionUnlockIdDefine.KingdomScene_radar_world_unlock)
        return
    end
    depth = depth or 0
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    if depth > 2 then
        return
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then
        return
    end
    if scene:IsInCity() then
        scene:LeaveCity(function()
            AllianceWarTabHelper.GoToCoord(x, y, waiAndShowUnit,depth + 1, true, context, callback, enterSize, noEnterZoomDuration, moveDuration)
        end)
        return
    end
    local camera = KingdomMapUtils.GetBasicCamera()
    camera:ForceGiveUpTween()
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos({X=x,Y=y})
    local anchoredPosition = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, KingdomMapUtils.GetMapSystem()) 
    enterSize = enterSize or KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    if isEnterMap then
        camera.ignoreLimit = true
        camera:LookAt(anchoredPosition)
        camera:SetSize(enterSize - CameraConst.TransitionMapSize)
        camera:ZoomTo(enterSize, CameraConst.TransitionZoomDuration, function()
            KingdomMapUtils.GetBasicCamera().ignoreLimit = false
            if waiAndShowUnit then
                g_Game.EventManager:TriggerEvent(EventConst.WAIT_AND_SHOW_UNIT, x, y, KingdomConstant.NormalLod, context)
            end
            if callback then
                g_Game.EventManager:TriggerEvent(EventConst.WAIT_SHOW_UNIT_CALLBACK, x, y, KingdomConstant.NormalLod, callback, context)
            end
        end)
    else
        if noEnterZoomDuration and noEnterZoomDuration <= 0 then
            camera:SetSize(enterSize)
            KingdomMapUtils.MoveAndZoomCamera(anchoredPosition, enterSize, moveDuration or 0.1, 0, nil, function()
                if waiAndShowUnit then
                    g_Game.EventManager:TriggerEvent(EventConst.WAIT_AND_SHOW_UNIT, x, y, KingdomConstant.NormalLod, context)
                end
                if callback then
                    g_Game.EventManager:TriggerEvent(EventConst.WAIT_SHOW_UNIT_CALLBACK, x, y, KingdomConstant.NormalLod, callback, context)
                end
            end)
        else
            KingdomMapUtils.MoveAndZoomCamera(anchoredPosition, enterSize, moveDuration or 0.1, noEnterZoomDuration or 0.1, nil, function()
                if waiAndShowUnit then
                    g_Game.EventManager:TriggerEvent(EventConst.WAIT_AND_SHOW_UNIT, x, y, KingdomConstant.NormalLod, context)
                end
                if callback then
                    g_Game.EventManager:TriggerEvent(EventConst.WAIT_SHOW_UNIT_CALLBACK, x, y, KingdomConstant.NormalLod, callback, context)
                end
            end)
        end
    end
end

return AllianceWarTabHelper
