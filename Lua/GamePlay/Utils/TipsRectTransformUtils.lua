local TipsRectTransformUtils = {}
local TipsEdgeDefine = {
    Top = 1,
    Bottom = 2,
    Left = 3,
    Right = 4,
}
local Vector3 = CS.UnityEngine.Vector3
TipsRectTransformUtils.TipsEdgeDefine = TipsEdgeDefine

---@param rectTrans CS.UnityEngine.RectTransform
function TipsRectTransformUtils.IsTipsAllInScreen(rectTrans)
    local Utils = require("Utils")
    if Utils.IsNull(rectTrans) then return false end
    
    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return false end

    local bl, tl, tr, br = rectTrans:GetWorldCorners()
    local points = {bl, tl , tr, br}
    for i, v in ipairs(points) do
        local viewport = uiCamera:WorldToViewportPoint(v)
        local x, y = viewport.x, viewport.y
        if x < 0 or x > 1 or y < 0 or y > 1 then
            return false
        end
    end
    return true
end

---@param rectTrans CS.UnityEngine.RectTransform
---@param basicCamera BasicCamera
---@param worldPos CS.UnityEngine.Vector3
---@param edge number
function TipsRectTransformUtils.SimpleAnchorTipsRectTransform(rectTrans, basicCamera, worldPos, edge)
    local Utils = require("Utils")
    if Utils.IsNull(rectTrans) then return false end

    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return false end

    local viewport = basicCamera.mainCamera:WorldToViewportPoint(worldPos)
    local bl, tl, tr, br = rectTrans:GetWorldCorners()
    local origin
    if edge == TipsEdgeDefine.Top then
        origin = (tl + tr) / 2
    elseif edge == TipsEdgeDefine.Bottom then
        origin = (bl + br) / 2
    elseif edge == TipsEdgeDefine.Left then
        origin = (tl + bl) / 2
    elseif edge == TipsEdgeDefine.Right then
        origin = (tr + br) / 2
    end
    if not origin then return false end
    local target = uiCamera:ViewportToWorldPoint({x = viewport.x, y = viewport.y, z = 0})
    local offset = target - origin
    rectTrans.position = rectTrans.position + offset
end

--- 功能 让tipRectTrans 贴靠在 anchorRectTrans 的一边 且保证 tipRectTrans在屏幕范围内 用于点击按钮展示tip tip 贴靠在点击按钮的旁边 且让tip 显示在屏幕范围内
---@param anchorRectTrans CS.UnityEngine.RectTransform
---@param tipRectTrans CS.UnityEngine.RectTransform
---@param forceEdge number @nil-auto,1-top,2-bottom,3-left,4-right
function TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(anchorRectTrans, tipRectTrans, forceEdge)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local anchorbl, _, anchortr, _ = anchorRectTrans:GetScreenCorners(uiCamera)
    local anchorX, anchorY = (anchorbl.x + anchortr.x) / 2, (anchorbl.y + anchortr.y) / 2
    local anchorSizeX, anchorSizeY = anchortr.x - anchorbl.x, anchortr.y - anchorbl.y

    local rootbl, _, roottr, _ = tipRectTrans:GetScreenCorners(uiCamera)
    local sizeX, sizeY = roottr.x - rootbl.x, roottr.y - rootbl.y

    local screenHeight = uiCamera.pixelHeight
    local screenWidth = uiCamera.pixelWidth
    local screenRate = screenWidth / screenHeight
    
    -- 先判断使用停靠在点击的rect四边的哪一侧
    local attempt_width = (anchorSizeX + sizeX) * 0.5
    local attempt_height = (anchorSizeY + sizeY) * 0.5
    local attempt_left_space = anchorX - attempt_width
    local attempt_right_space = screenWidth - attempt_width - anchorX
    local attempt_top_space = screenHeight - attempt_height - anchorY
    local attempt_bottom_space = anchorY - attempt_height
    
    local targetTipXMin = sizeX * 0.5
    local targetTipXMax =  screenWidth - targetTipXMin
    local targetTipYMin = sizeY * 0.5
    local targetTipYMax = screenHeight - targetTipYMin
    
    local baseTipPosX = screenWidth * 0.5
    local baseTipPosY = screenHeight * 0.5
    
    local choose = 0 -- 1 上边 2 下边 3 左边 4 右边
    if forceEdge ~= 1 and forceEdge ~= 2 and forceEdge ~= 3 and forceEdge ~= 4 then
        -- 规则调整 上下剩余空间以乘以屏幕长宽比后与左右剩余空间对比 那边剩余贴靠在那边
        local tbMaxSpace = math.max(attempt_top_space, attempt_bottom_space)
        local lrMaxSpace = math.max(attempt_left_space, attempt_right_space)
        local rateTbMaxSpace = tbMaxSpace * screenRate
        if rateTbMaxSpace > lrMaxSpace then
            if attempt_top_space > attempt_bottom_space then
                choose = 1
            else
                choose = 2
            end
        else
            if attempt_left_space > attempt_right_space then
                choose = 3
            else
                choose = 4
            end
        end
    else
        choose = forceEdge
    end
    
    if choose == 1 then
        baseTipPosX = anchorX
        baseTipPosY = anchorY + attempt_height
    elseif choose == 2 then
        baseTipPosX = anchorX
        baseTipPosY = anchorY - attempt_height
    elseif choose == 3 then
        baseTipPosX = anchorX - attempt_width
        baseTipPosY = anchorY
    elseif choose == 4 then
        baseTipPosX = anchorX + attempt_width
        baseTipPosY = anchorY
    end
    baseTipPosX = math.clamp(baseTipPosX, math.min(targetTipXMin, targetTipXMax), math.max(targetTipXMin, targetTipXMax))
    baseTipPosY = math.clamp(baseTipPosY, math.min(targetTipYMin, targetTipYMax), math.max(targetTipYMin, targetTipYMax))

    tipRectTrans.position = uiCamera:ScreenToWorldPoint(Vector3(baseTipPosX, baseTipPosY, 0))
    return choose
end

---@param rectTransform CS.UnityEngine.RectTransform
---@param uiCamera CS.UnityEngine.Camera
function TipsRectTransformUtils.CalculateTargetRectTransformViewportOffset(rectTransform, uiCamera)
    local wbl, wtl, wtr, wbr = rectTransform:GetWorldCorners()
    local vbl = uiCamera:WorldToViewportPoint(wbl)
    local vtl = uiCamera:WorldToViewportPoint(wtl)
    local vtr = uiCamera:WorldToViewportPoint(wtr)
    local vbr = uiCamera:WorldToViewportPoint(wbr)
    local vheight = vtl.y - vbl.y
    local vwidth = vbr.x - vbl.x

    local skipVertical = vheight >= 1
    local skipHorizontal = vwidth >= 1
    
    if skipVertical and skipHorizontal then
        return 0, 0
    end

    local offsetVX, offsetVY = 0, 0
    if vbl.x < 0 then       ---- 溢出左侧屏幕
        offsetVX = vbl.x
    elseif vbr.x > 1 then   ---- 溢出右侧屏幕
        offsetVX = vbr.x - 1
    end

    if vbl.y < 0 then       ---- 溢出下侧屏幕
        offsetVY = vbl.y
    elseif vtl.y > 1 then   ---- 溢出上侧屏幕
        offsetVY = vtl.y - 1
    end
    return offsetVX, offsetVY
end

return TipsRectTransformUtils