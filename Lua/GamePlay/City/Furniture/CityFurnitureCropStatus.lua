local Utils = require("Utils")

---@class CityFurnitureCropStatus
---@field cropFileds CS.UnityEngine.GameObject[] @CS.System.Collections.Generic.List(typeof(CS.UnityEngine.GameObject)
---@field cropStatusTemplate CS.UnityEngine.GameObject[] @CS.System.Collections.Generic.List(typeof(CS.UnityEngine.GameObject)
local CityFurnitureCropStatus = class("CityFurnitureCropStatus")

function CityFurnitureCropStatus:ctor()
    self._createdGo = {}
    self._statusCount = 0
    self._fieldsCount = 0
end

function CityFurnitureCropStatus:Awake()
    ---@type table<number, {go:CS.UnityEngine.GameObject, status:number, root:CS.UnityEngine.Transform}>
    self._currentCropStatus = {}
    ---@type {go:CS.UnityEngine.GameObject, normalized:number}[]
    self._statusNormalizeTemplate = {}
    self._statusCount = self.cropStatusTemplate.Count
    local normalizeStageValue = ((self._statusCount > 1) and (0.75 / (self._statusCount - 1))) or 0
    for index = 0, self._statusCount - 1 do
        ---@type {go:CS.UnityEngine.GameObject, normalized:number}
        local pair = {}
        pair.go = self.cropStatusTemplate[index]
        pair.normalized = index * normalizeStageValue
        table.insert(self._statusNormalizeTemplate, pair)
    end
    self._fieldsCount = self.cropFileds.Count
    for index = 1, self._fieldsCount do
        self._currentCropStatus[index] = {status = 0, root = self.cropFileds[index - 1].transform}
    end
end

function CityFurnitureCropStatus:GetStatusCount()
    return self._statusCount
end

function CityFurnitureCropStatus:GetFieldsCount()
    return self._fieldsCount
end

function CityFurnitureCropStatus:SetupGrowNormalized(filedIndex, value)
    local valueIndex = 0
    if value > 0 then
        for index, stage in ipairs(self._statusNormalizeTemplate) do
            if value <= stage.normalized then
                break
            end
            valueIndex = index
        end
    end
    self:SyncCropToStatus(filedIndex, valueIndex)
end

function CityFurnitureCropStatus:SyncCropToStatus(filedIndex, status)
    local filedInfo = self._currentCropStatus[filedIndex]
    if not filedInfo then return end
    if filedInfo.status == status then return end
    if Utils.IsNotNull(filedInfo.go) then
        CS.UnityEngine.Object.Destroy(filedInfo.go)
    end
    local templateInfo = self._statusNormalizeTemplate[status]
    filedInfo.go = nil
    if not self._isMoving then
        if templateInfo and Utils.IsNotNull(templateInfo.go) and Utils.IsNotNull(filedInfo.root)  then
            filedInfo.go = CS.UnityEngine.Object.Instantiate(templateInfo.go, filedInfo.root, false)
            filedInfo.go:SetLayerRecursively("City")
        end
    end
    filedInfo.status = status
end

function CityFurnitureCropStatus:ClearAllCrop()
    for index, _ in pairs(self._currentCropStatus) do
        self:SyncCropToStatus(index)
    end
end

function CityFurnitureCropStatus:OnMoveBegin()
    self._isMoving = true
    for _, filedInfo in pairs(self._currentCropStatus) do
        if Utils.IsNotNull(filedInfo.go) then
            CS.UnityEngine.Object.Destroy(filedInfo.go)
        end
        filedInfo.go = nil
    end
end

function CityFurnitureCropStatus:OnMoveEnd()
    self._isMoving = false
    for _, filedInfo in pairs(self._currentCropStatus) do
        if Utils.IsNotNull(filedInfo.go) then
            CS.UnityEngine.Object.Destroy(filedInfo.go)
        end
        local templateInfo = self._statusNormalizeTemplate[filedInfo.status]
        if templateInfo and Utils.IsNotNull(templateInfo.go) and Utils.IsNotNull(filedInfo.root)  then
            filedInfo.go = CS.UnityEngine.Object.Instantiate(templateInfo.go, filedInfo.root, false)
            filedInfo.go:SetLayerRecursively("City")
        end
    end
end

return CityFurnitureCropStatus