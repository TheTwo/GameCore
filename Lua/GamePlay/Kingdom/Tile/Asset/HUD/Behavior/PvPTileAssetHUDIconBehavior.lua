---prefabName:ui3d_bubble_building_icon
local Utils = require("Utils")
local ManualUIConst = require("ManualUIConst")

local Color = CS.UnityEngine.Color

---@class PvPTileAssetHUDIconBehavior
---@field root CS.UnityEngine.Transform
---@field p_icon_building CS.U2DSpriteMesh
---@field p_icon_building_base CS.U2DSpriteMesh
---@field p_group_name CS.UnityEngine.GameObject
---@field p_text_name CS.U2DTextMesh
---@field p_text_lv CS.U2DTextMesh
---@field p_lv_base CS.U2DSpriteMesh
---@field p_anchor_lv CS.U2DAnchor
---@field p_trigger CS.DragonReborn.LuaBehaviour
---@field iconMaterialSetter CS.Lod.U2DWidgetMaterialSetter
---@field textMaterialSetter CS.Lod.U2DWidgetMaterialSetter
---@field facingCamera CS.U2DFacingCamera
local PvPTileAssetHUDIconBehavior = class("PvPTileAssetHUDIconBehavior")

function PvPTileAssetHUDIconBehavior:Reset()
    self:ShowLevel(true)
    self:ShowName(true)
    self:SetNameColor()
    self:SetLevelColor()
    self:ShowIconBase(false)
    self:SetLevelBase(ManualUIConst.sp_comp_base_lv_3)
end

---@param enable boolean
function PvPTileAssetHUDIconBehavior:EnableTrigger(enable)
    if Utils.IsNull(self.p_trigger) then return end
    ---@type MapUITrigger
    local trigger = self.p_trigger.Instance
    trigger:SetEnable(enable)
end

function PvPTileAssetHUDIconBehavior:SetTrigger(callback)
    if Utils.IsNull(self.p_trigger) then return end
    self.p_trigger.Instance:SetTrigger(callback)
end

function PvPTileAssetHUDIconBehavior:SetIcon(icon, refresh)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_building)
    if refresh then
        self.p_icon_building:UpdateImmediate()
    end
end

function PvPTileAssetHUDIconBehavior:SetIconBase(icon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_building_base)
end

function PvPTileAssetHUDIconBehavior:SetLevelBase(icon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_lv_base)
end

function PvPTileAssetHUDIconBehavior:AdjustNameLevel(name, level, refresh)
    local showName = not string.IsNullOrEmpty(name)
    if showName then
        self.p_text_name.text = name
        showName = self.p_text_name.gameObject.activeSelf
    else
        self.p_text_name:SetVisible(false)
    end
    local showLevel = not string.IsNullOrEmpty(level)
    if showLevel then
        self.p_text_lv.text = level
    else
        self.p_text_lv:SetVisible(false)
    end
    self:AdjustLevelPosition(showName)

    if refresh then
        self.p_text_name:UpdateImmediate()
        self.p_text_lv:UpdateImmediate()
    end
end

function PvPTileAssetHUDIconBehavior:SetNameColor(color, refresh)
    if Utils.IsNull(self.p_text_name) then
        return
    end

    color = color or Color.white
    self.p_text_name.color = color
    if refresh then
        self.p_text_name:UpdateImmediate()
    end
end

function PvPTileAssetHUDIconBehavior:SetLevelColor(color, refresh)
    if Utils.IsNull(self.p_text_lv) then
        return
    end

    color = color or Color.black
    self.p_text_lv.color = color
    if refresh then
        self.p_text_lv:UpdateImmediate()
    end
end

---@param state boolean
function PvPTileAssetHUDIconBehavior:Show(state)
    self.root:SetVisible(state)
end

---@param state boolean
function PvPTileAssetHUDIconBehavior:ShowIcon(state)
    self.p_icon_building:SetVisible(state)
end

---@param state boolean
function PvPTileAssetHUDIconBehavior:ShowIconBase(state)
    self.p_icon_building_base:SetVisible(state)
end

---@param state boolean
function PvPTileAssetHUDIconBehavior:ShowName(state)
    self.p_text_name:SetVisible(state)
    self:AdjustLevelPosition(state)
end

---@param state boolean
function PvPTileAssetHUDIconBehavior:ShowLevel(state)
    self.p_text_lv:SetVisible(state)
end

function PvPTileAssetHUDIconBehavior:SetName(name)
    self.p_text_name.text = name
end

function PvPTileAssetHUDIconBehavior:SetLevel(level)
    self.p_text_lv.text = level
end

function PvPTileAssetHUDIconBehavior:RefreshAll()
    self.p_icon_building:UpdateImmediate()
    self.p_text_name:UpdateImmediate()
    self.p_text_lv:UpdateImmediate()
end

function PvPTileAssetHUDIconBehavior:SetOrthographicScale(scale)
    self.facingCamera.OrthographicScale = scale
end

---@param showName boolean
function PvPTileAssetHUDIconBehavior:AdjustLevelPosition(showName)
    if showName then
        self.p_anchor_lv.enabled = true
    else
        self.p_anchor_lv.enabled = false
        self.p_text_lv.transform.localPosition = CS.UnityEngine.Vector3.zero
    end
end


return PvPTileAssetHUDIconBehavior