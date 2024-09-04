local BaseUIComponent = require("BaseUIComponent")
local Utils = require("Utils")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local TimerUtility = require("TimerUtility")

local RenderTexture = CS.UnityEngine.RenderTexture
local RenderUtil = CS.RenderExtension.RenderUtil
local Vector3 = CS.UnityEngine.Vector3

---@class LandformMapParameter
---@field startSelectLandformConfigID number
---@field showMyCastle boolean
---@field unlockedDistricts number[]
---@field selectLandformCallback fun(number)
---@field rectXMin number
---@field rectXMax number
---@field rectYMin number
---@field rectYMax number


---@class LandformMap : BaseUIComponent
---@field districtRT CS.UnityEngine.RenderTexture
---@field unlockedDistricts number[]
---@field selectLandformCallback fun(number)
---@field maskHandles table<number, CS.DragonReborn.AssetTool.AssetHandle>
---@field blitMaterialHandle CS.DragonReborn.AssetTool.AssetHandle
---@field ringMaterials CS.UnityEngine.Material[]
local LandformMap = class("LandformMap", BaseUIComponent)

local RT_SIZE = 1024

function LandformMap:ctor()
    self.maskHandles = {}
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    self.tilesPerMapX = staticMapData.TilesPerMapX
    self.tilesPerMapZ = staticMapData.TilesPerMapZ
end

function LandformMap:OnCreate(param)
    self.p_icon_city = self:RectTransform("p_icon_city")
    self.p_btn_map = self:RectTransform("p_btn_map")
    self.p_map_root = self:RectTransform("p_map_root")
    
    --暂时屏蔽了。圈层太细，手机上点起来不方便。一般都是从外部控制选中
    --self:PointerClick("p_btn_map", Delegate.GetOrCreate(self, self.OnMapClicked))

  
end

function LandformMap:OnClose(param)
    self:DestroyDistrictMask()
    
    ---@type CS.DragonReborn.AssetTool.AssetManager
    local assetManager = CS.DragonReborn.AssetTool.AssetManager.Instance
    for _, handle in pairs(self.maskHandles) do
        assetManager:UnloadAsset(handle)
    end
    table.clear(self.maskHandles)
    
    if self.blitMaterialHandle then
        assetManager:UnloadAsset(self.blitMaterialHandle)
        self.blitMaterialHandle = nil
    end
end

---@param data LandformMapParameter
function LandformMap:OnFeedData(data)
    self.unlockedDistricts = data.unlockedDistricts
    self.selectLandformCallback = data.selectLandformCallback

    TimerUtility.DelayExecuteInFrame(function()
        self.ringMaterials = {}
        table.insert(self.ringMaterials, self:Image("p_img_map_1").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_2").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_3").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_4").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_5").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_6").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_7").RenderMaterial)
        table.insert(self.ringMaterials, self:Image("p_img_map_8").RenderMaterial)
        self:DestroyDistrictMask()
        self:RefreshDistrictMask()
        self:SelectLandform(data.startSelectLandformConfigID)
        local centerX, centerY, scale = self:CalculateZoom(data.rectXMin, data.rectYMin, data.rectXMax, data.rectYMax)
        self:RefreshMapTransform(centerX, centerY, scale)
        self:RefreshMyCastle(data.showMyCastle, centerX, centerY, scale)
    end)
end

function LandformMap:SelectLandform(landformConfigID)
    local landformConfig = ConfigRefer.Land:Find(landformConfigID)
    if not landformConfig then
        return
    end
    local layerNum = landformConfig:LayerNum()
    for id, material in pairs(self.ringMaterials) do
        if layerNum == id then
            self:DoSelectLandform(material)
        else
            self:DoDeselectLandform(material)
        end
    end
    if self.selectLandformCallback then
        self.selectLandformCallback(landformConfigID)
    end
end

function LandformMap:CalculateZoom(xMin, yMin, xMax, yMax)
    local centerX, centerY, size = self:CalculateZoomSquare(xMin, yMin, xMax, yMax)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local texSize = self.p_map_root.rect.width
    local unitX = texSize / staticMapData.TilesPerMapX
    local unitY = texSize / staticMapData.TilesPerMapZ
    local zoomCenterX = texSize * 0.5 - centerX * unitX
    local zoomCenterY = texSize * 0.5 - centerY * unitY
    local zoomScale = texSize / (size * unitX)
    return zoomCenterX, zoomCenterY, zoomScale
end

function LandformMap:CalculateZoomSquare(xMin, yMin, xMax, yMax)
    local centerX = (xMin + xMax) * 0.5
    local centerY = (yMin + yMax) * 0.5
    local width = xMax - xMin
    local height = yMax - yMin
    return centerX, centerY, math.max(width, height)
end

---@private
function LandformMap:RefreshDistrictMask()
    if not self.unlockedDistricts then
        return
    end

    self.districtRT = RenderTexture.GetTemporary(RT_SIZE, RT_SIZE, 0, CS.UnityEngine.RenderTextureFormat.R16)

    local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
    local set = HashSetString()

    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local baseID = staticMapData:GetBaseId()
    for _, districtID in ipairs(self.unlockedDistricts) do
        local id = districtID - baseID
        local maskName = ("tex_district_mask_%s_%s"):format(staticMapData.Prefix, id)
        set:Add(maskName)
    end
    set:Add("mat_district_mask")
    g_Game.AssetManager:EnsureSyncLoadAssets(set, true)

    self.blitMaterialHandle = g_Game.AssetManager:LoadAsset("mat_district_mask")
    for _, districtID in ipairs(self.unlockedDistricts) do
        local id = districtID - baseID
        if not self.maskHandles[id] then
            local maskName = ("tex_district_mask_%s_%s"):format(staticMapData.Prefix, id)
            local handle = g_Game.AssetManager:LoadAsset(maskName)
            self.maskHandles[id] = handle
        end
        
        local texMask = self.maskHandles[id].Asset
        if Utils.IsNotNull(texMask) then
            RenderUtil.Blit(texMask, self.districtRT, self.blitMaterialHandle.Asset)
        end
    end

    for _, mat in ipairs(self.ringMaterials) do
        mat:SetTexture("_Mask", self.districtRT)
    end
    
end

---@private
function LandformMap:DestroyDistrictMask()
    if Utils.IsNotNull(self.districtRT) then
        RenderTexture.ReleaseTemporary(self.districtRT)
        self.districtRT = nil
    end
end

function LandformMap:RefreshMapTransform(centerX, centerY, scale)
    self.p_map_root.localPosition = CS.UnityEngine.Vector3(centerX * scale, centerY * scale, 0)
    self.p_map_root.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
end

function LandformMap:RefreshMyCastle(show, centerX, centerY, scale)
    if show then
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(castle.MapBasics.Position)
        local rect = self.p_btn_map.rect
        local x = tileX / self.tilesPerMapX * rect.width - 0.5 * rect.width
        local y = tileZ / self.tilesPerMapZ * rect.height - 0.5 * rect.height
        local offset = CS.UnityEngine.Vector3(centerX * scale, centerY * scale, 0)
        self.p_icon_city.localPosition = offset + Vector3(x * scale, y * scale, 0)
        self.p_icon_city:SetVisible(true)
    else
        self.p_icon_city:SetVisible(false)
    end
end

---@private
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function LandformMap:OnMapClicked(go, eventData)
    local uiCamera = g_Game.UIManager.uiCam
    local screenPosition = Vector3(eventData.position.x, eventData.position.y, uiCamera.nearClipPlane)
    local clickWorldPosition = uiCamera:ScreenToWorldPoint(screenPosition)
    local clickLocalPosition = self.p_btn_map:InverseTransformPoint(clickWorldPosition)
    local rect = self.p_btn_map.rect
    local u = (clickLocalPosition.x + 0.5 * rect.width) / rect.width
    local v = (clickLocalPosition.y + 0.5 * rect.height) / rect.height
    local tileX = math.floor(self.tilesPerMapX * u)
    local tileZ = math.floor(self.tilesPerMapZ * v)
    local landformConfigID = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    self:SelectLandform(landformConfigID)
end

---@private
---@param material CS.UnityEngine.Material
function LandformMap:DoSelectLandform(material)
    if Utils.IsNotNull(material) then
        material:SetFloat("_choose_toggle", 1)
        material:EnableKeyword("_CHOOSE")
    end
end

---@private
---@param material CS.UnityEngine.Material
function LandformMap:DoDeselectLandform(material)
    if Utils.IsNotNull(material) then
        material:SetFloat("_choose_toggle", 0)
        material:DisableKeyword("_CHOOSE")
    end
end

return LandformMap