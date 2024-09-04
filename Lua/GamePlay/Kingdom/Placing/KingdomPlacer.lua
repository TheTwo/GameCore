local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")

local MapUtils = CS.Grid.MapUtils
local Vector2Short = CS.DragonReborn.Vector2Short
local Vector3 = CS.UnityEngine.Vector3
local Color = CS.UnityEngine.Color

local _, yesColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#C9D469DD")
local _, noColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#CC3434FF")
local _, gridColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#B4FF55")

---@class KingdomPlacer
---@field context KingdomPlacerContext
---@field staticMapData CS.Grid.StaticMapData
---@field mapSystem CS.Grid.MapSystem
---@field behavior KingdomPlacerBehavior
---@field meshDrawer CS.GridMapBuildingMesh
---@field gameObject CS.UnityEngine.GameObject
---@field transform CS.UnityEngine.Transform
---@field allTileValid boolean
---@field validator fun():boolean
---@field heightmapHandle CS.DragonReborn.AssetTool.AssetHandle
local KingdomPlacer = class("KingdomPlacer")
KingdomPlacer.yesColor = yesColor
KingdomPlacer.noColor = noColor
KingdomPlacer.gridColor = gridColor
KingdomPlacer.clearColor = Color.clear

function KingdomPlacer:Awake()
    self.gameObject = self.behaviour.gameObject
    self.transform = self.gameObject.transform
    self.allowDragTarget = false
    self.dragTarget = false
    ---@type CS.DragonReborn.Vector2Short
    self.dragTargetCoord = nil
    ---@type CS.DragonReborn.Vector2Short
    self.dragPosFix = nil
end

---@param behaviors table
---@param context KingdomPlacerContext
function KingdomPlacer:Initialize(behaviors, context)
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    self.behaviors = behaviors
    self.context = context
    self.allowDragTarget = context and context.allowDragTarget

    ---@type CS.DragonReborn.AssetTool.AssetManager
    local assetManager = CS.DragonReborn.AssetTool.AssetManager.Instance
    local heightMapName = string.format("tex_height_map_%s_full", self.staticMapData.Prefix)
    self.heightmapHandle = assetManager:LoadAssetAsync(heightMapName, function(success, handle)
        if not success or not handle or Utils.IsNull(handle.Asset) then
            return
        end
        ---@type CS.UnityEngine.MeshRenderer
        local renderer = self.meshDrawer and self.meshDrawer:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
        if Utils.IsNotNull(renderer) then
            local material = renderer.sharedMaterial
            material:SetTexture("_HeightTex", handle.Asset);
            material:SetTextureScale("_HeightTex", CS.UnityEngine.Vector2(1 / self.staticMapData.UnitsPerMapX, 1 / self.staticMapData.UnitsPerMapZ));
            material:SetFloat("_HeightMin", 0)
            material:SetFloat("_HeightMax", self.staticMapData:GetMaxHeight())
        end
    end)
   

    for _, v in ipairs(self.behaviors) do
        v:OnInitialize(self, context)
    end
end

function KingdomPlacer:Dispose()
    ---@type CS.DragonReborn.AssetTool.AssetManager
    local assetManager = CS.DragonReborn.AssetTool.AssetManager.Instance
    if self.heightmapHandle then
        assetManager:UnloadAsset(self.heightmapHandle)
    end
    for _, v in ipairs(self.behaviors) do
        v:OnDispose()
    end
end

---@param behaviorParameter table
function KingdomPlacer:SetParameter(behaviorParameter)
    self.context:SetParameter(behaviorParameter)
    for _, v in ipairs(self.behaviors) do
        v:OnSetParameter(behaviorParameter)
    end
end

---@param validator fun():boolean
function KingdomPlacer:SetValidator(validator)
    self.validator = validator
end

function KingdomPlacer:Show()
    self.gameObject:SetActive(true)
    for _, v in ipairs(self.behaviors) do
        v:OnShow()
    end
end

function KingdomPlacer:Hide()
    for _, v in ipairs(self.behaviors) do
        v:OnHide()
    end
    self.gameObject:SetActive(false)
end

function KingdomPlacer:UpdatePosition(x, y)
    if self.dragTarget then
        return
    end
    self:DoUpdatePosition(x, y)
end

function KingdomPlacer:DoUpdatePosition(x, y)
    self.context.coord = Vector2Short(x, y)
    self.transform.position = MapUtils.CalculateCoordToTerrainPosition(self.context.coord.X, self.context.coord.Y, self.mapSystem)

    local ret = self:UpdateValid()
    self.meshDrawer:UpdateAllColor(ret)

    for _, v in ipairs(self.behaviors) do
        v:OnUpdatePosition()
    end
end

function KingdomPlacer:Place()
    for _, v in ipairs(self.behaviors) do
        v:OnPlacing()
    end
end

function KingdomPlacer:SetSize(sizeX, sizeY)
    self.context.sizeX, self.context.sizeY = sizeX, sizeY
    self:InitMesh(self.context.sizeX, self.context.sizeY, 100)
    self:InitArrows(self.context.sizeX, self.context.sizeY)
end

function KingdomPlacer:InitMesh(sizeX, sizeY, sortingOrder)
    local ret = self:UpdateValid()

    local unitX = self.staticMapData.UnitsPerTileX
    local unitY = self.staticMapData.UnitsPerTileZ
    self.meshDrawer:Initialize(sizeX, sizeY, unitX, unitY, ret, {noColor, yesColor}, sortingOrder)
end

function KingdomPlacer:UpdateValid()
    local ret = {}
    self.allTileValid = true
    for j = 0, self.context.sizeY - 1 do
        for i = 0, self.context.sizeX - 1 do
            local offsetX = self.context.coord.X
            local offsetY = self.context.coord.Y
            local valid = self.validator and self.validator(i + offsetX, j + offsetY)
            self.allTileValid = self.allTileValid and valid
            local value = valid and 1 or 0
            table.insert(ret, value)
        end
    end
    return ret
end

function KingdomPlacer:InitArrows(sizeX, sizeY)
    local unitX = self.staticMapData.UnitsPerTileX
    local unitY = self.staticMapData.UnitsPerTileZ
    local width = sizeX * unitX
    local height = sizeY * unitY
    self.arrowL.localScale = Vector3.one * unitX
    self.arrowR.localScale = Vector3.one * unitX
    self.arrowB.localScale = Vector3.one * unitX
    self.arrowT.localScale = Vector3.one * unitX
    self.arrowL.localPosition = Vector3(-1, 0, height / 2)
    self.arrowR.localPosition = Vector3(width + 1, 0, height / 2)
    self.arrowB.localPosition = Vector3(width / 2, 0, -1)
    self.arrowT.localPosition = Vector3(width / 2, 0, height + 1)
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacer:IsDragStartWithTarget(gesture)
    local coord = self:ScreenToGridCoord(gesture.position)
    if coord.X >= self.context.coord.X
            and coord.X <= self.context.coord.X + self.context.sizeX
            and coord.Y >= self.context.coord.Y
            and coord.Y <= self.context.coord.Y + self.context.sizeY
    then
        return true
    end
    return false
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacer:OnDragStart(gesture)
    self.dragTarget = self.allowDragTarget and self:IsDragStartWithTarget(gesture)
    if self.dragTarget then
        self.dragTargetCoord = self.context.coord
        local gestureCoord = self:ScreenToGridCoord(gesture.position)
        self.dragPosFix = Vector2Short(self.dragTargetCoord.X - gestureCoord.X, self.dragTargetCoord.Y - gestureCoord.Y)
        ModuleRefer.KingdomPlacingModule:OnDragPlacerHideCircle()
    end
    return self.dragTarget
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacer:OnDragUpdate(gesture)
    if self.dragTarget then
        local coord = self:ScreenToGridCoord(gesture.position)
        coord.X = coord.X + self.dragPosFix.X
        coord.Y = coord.Y + self.dragPosFix.Y
        if coord.X ~= self.dragTargetCoord.X or coord.Y ~= self.dragTargetCoord.Y then
            self.dragTargetCoord = coord
            self:DoUpdatePosition(coord.X, coord.Y)
        end
    end
    return self.dragTarget
end

---@param gesture CS.DragonReborn.DragGesture
function KingdomPlacer:OnDragEnd(gesture)
    if self.dragTarget then
        local coord = self:ScreenToGridCoord(gesture.position)
        coord.X = coord.X + self.dragPosFix.X
        coord.Y = coord.Y + self.dragPosFix.Y
        if coord.X ~= self.dragTargetCoord.X or coord.Y ~= self.dragTargetCoord.Y then
            self.dragTargetCoord = coord
            self:DoUpdatePosition(coord.X, coord.Y)
        end
        self.dragTarget = false
        local camera = ModuleRefer.KingdomPlacingModule.basicCamera
        camera:ForceGiveUpTween()
        camera:LookAt(MapUtils.CalculateCoordToTerrainPosition(self.dragTargetCoord.X, self.dragTargetCoord.Y, KingdomMapUtils.GetMapSystem()))
        return true
    end
    return self.dragTarget
end

---@param screenPosition CS.UnityEngine.Vector3
---@return CS.DragonReborn.Vector2Short
function KingdomPlacer:ScreenToGridCoord(screenPosition)
    local screenPos = Vector3(screenPosition.x, screenPosition.y, 0)
    local worldPos = KingdomMapUtils.ScreenToWorldPosition(screenPos, true)
    return MapUtils.CalculateWorldPositionToCoord(worldPos, self.staticMapData)
end

return KingdomPlacer