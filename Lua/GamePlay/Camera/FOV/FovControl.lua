local FovControl = {}

---@param camera BasicCamera
function FovControl.UpdateFov(camera, sizeList, fovList)
    local sizeCount = #sizeList
    local fovCount = #fovList

    if fovCount == 0 then return end
    local cameraSize = camera:GetSize()
    if cameraSize <= sizeList[1] then
        return camera:SetFov(fovList[1])
    elseif cameraSize >= sizeList[fovCount] then
        return camera:SetFov(fovList[fovCount])
    end

    for i = 1, sizeCount do
        local sizel = sizeList[i]
        if i < fovCount and cameraSize > sizel then
            local total = (sizeList[i+1] - sizel)
            if total <= 0 then
                total = 1
            end
            local cur = (cameraSize - sizel)
            if cur <= 0 then
                cur = 1
            end
            local t = math.clamp01(cur / total)
            return camera:SetFov(math.lerp(fovList[i], fovList[i+1], t))
        end
    end

    return camera:SetFov(fovList[fovCount])
end

return FovControl