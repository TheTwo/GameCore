local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetHUDConstructionBehavior
---@field facingCamera CS.U2DFacingCamera
---@field goDurability CS.UnityEngine.GameObject
---@field sliderProgressNormal CS.U2DSlider
---@field sliderProgressRed CS.U2DSlider
---@field textProgress CS.U2DTextMesh
---
---@field goTroopQuantity CS.UnityEngine.GameObject
---@field textTroopQuantity CS.U2DTextMesh
---
---@field goStateTime CS.UnityEngine.GameObject
---@field textStateTime CS.U2DTextMesh
---@field imgStateIcon CS.U2DSpriteMesh
---
---@field allianceLogo CS.DragonReborn.LuaBehaviour
---@field verticalLayoutGroup CS.UnityEngine.UI.VerticalLayoutGroup
---
---@field goTitle CS.UnityEngine.GameObject
---@field textTitle CS.U2DTextMesh
---@field imgTitle CS.U2DSpriteMesh
local PvPTileAssetHUDConstructionBehavior = class("PvPTileAssetHUDConstructionBehavior")

function PvPTileAssetHUDConstructionBehavior:ShowDurability(state)
    self.goDurability:SetVisible(state)
end

---@param durability number
---@param maxDurability number
function PvPTileAssetHUDConstructionBehavior:SetDurability(durability, maxDurability, color, refresh)
    if durability and maxDurability then
        local progress = math.inverseLerp(0, maxDurability, durability)
        self.sliderProgressNormal.progress = progress

        if color then
            self.sliderProgressNormal.spriteMesh.color = color
        end
        
        if refresh then
            self.sliderProgressNormal.spriteMesh:UpdateImmediate()
        end
    end
end

function PvPTileAssetHUDConstructionBehavior:ShowDurabilityText(state)
    self.textProgress:SetVisible(state)
end

function PvPTileAssetHUDConstructionBehavior:SetDurabilityText(durability, maxDurability, refresh)
    if durability and maxDurability then
        self.textProgress.text = string.format("%d/%d", durability, maxDurability)
        if refresh then
            self.textProgress:UpdateImmediate()
        end
    end
end

function PvPTileAssetHUDConstructionBehavior:ShowTroopQuantity(state)
    self.goTroopQuantity:SetVisible(state)
end

function PvPTileAssetHUDConstructionBehavior:SetTroopQuantity(troopCount, refresh)
    if troopCount then
        self.textTroopQuantity.text = tostring(troopCount)
        if refresh then
            self.textTroopQuantity:UpdateImmediate()
        end
    end
end

function PvPTileAssetHUDConstructionBehavior:ShowStateTime(state)
    self.goStateTime:SetVisible(state)
end

function PvPTileAssetHUDConstructionBehavior:SetStateTime(textKey, timeStr, refresh)
    self.textStateTime.text = I18N.GetWithParams(textKey, timeStr)
    if refresh then
        self.textStateTime:UpdateImmediate()
    end
end

function PvPTileAssetHUDConstructionBehavior:SetStateIcon(iconName)
    g_Game.SpriteManager:LoadSpriteAsync(iconName, self.imgStateIcon)
end

function PvPTileAssetHUDConstructionBehavior:ShowAllianceLogo(state)
    self.allianceLogo:SetVisible(state)
end

function PvPTileAssetHUDConstructionBehavior:ShowTitle(state)
    self.goTitle:SetVisible(state)
end

function PvPTileAssetHUDConstructionBehavior:SetTitle(textKey, configID)
    self.textTitle.text = I18N.Get(textKey)
    local titleConfig = ConfigRefer.AdornmentTitle:Find(configID)
    if titleConfig then
        g_Game.SpriteManager:LoadSprite(titleConfig:TitleIcon(), self.imgIcon)
        g_Game.SpriteManager:LoadSprite(titleConfig:TitleBaseL(), self.imgTitle_l)
        g_Game.SpriteManager:LoadSprite(titleConfig:TitleBase(), self.imgTitle)
        g_Game.SpriteManager:LoadSprite(titleConfig:TitleBaseR(), self.imgTitle_r)
    end
end

---@param appear number
---@param pattern number
function PvPTileAssetHUDConstructionBehavior:SetAllianceLogo(appear, pattern)
    if appear and appear > 0 and pattern and pattern > 0 then
        ---@type AllianceLogo3DComponent
        local logo = self.allianceLogo.Instance
        logo:FeedDataValue(appear, pattern)
    end
end

function PvPTileAssetHUDConstructionBehavior:RefreshAll()
    self.sliderProgressNormal.spriteMesh:UpdateImmediate()
    self.textProgress:UpdateImmediate()
    self.textTroopQuantity:UpdateImmediate()
    self.textStateTime:UpdateImmediate()
    self.textTitle:UpdateImmediate()
    self.imgTitle:UpdateImmediate()
    self.imgStateIcon:UpdateImmediate()
end

function PvPTileAssetHUDConstructionBehavior:ResetAll()
    self.goDurability:SetVisible(false)
    self.textProgress:SetVisible(false)
    self.goTroopQuantity:SetVisible(false)
    self.goStateTime:SetVisible(false)
    self.allianceLogo:SetVisible(false)
    self.goTitle:SetVisible(false)
    g_Game.SpriteManager:LoadSpriteAsync(ManualResourceConst.sp_common_icon_time_01, self.imgStateIcon)
end

function PvPTileAssetHUDConstructionBehavior:LayoutVertical()
    self.verticalLayoutGroup:CalculateLayoutInputVertical()
end

return PvPTileAssetHUDConstructionBehavior
