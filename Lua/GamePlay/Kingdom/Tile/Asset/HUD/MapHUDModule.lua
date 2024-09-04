local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local KingdomConstant = require("KingdomConstant")
local MapHUDFadeDefine = require("MapHUDFadeDefine")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local ColorConsts = require("ColorConsts")


local Object = CS.UnityEngine.Object

local ColorId = CS.RenderExtension.ShaderConst._BaseColorId

---@class MapHUDModule : BaseModule
---@field settings CS.Kingdom.MapHUDSettings
---@field spriteMaterial CS.UnityEngine.Material
---@field textMaterial CS.UnityEngine.Material
---@field hideSpriteMaterial CS.UnityEngine.Material
---@field hideTextMaterial CS.UnityEngine.Material
---@field hideSpriteECSMaterial CS.UnityEngine.Material
---@field hideTextECSMaterial CS.UnityEngine.Material
---@field fadeInSpriteMaterial CS.UnityEngine.Material
---@field fadeOutSpriteMaterial CS.UnityEngine.Material
---@field fadeInTextMaterial CS.UnityEngine.Material
---@field fadeOutTextMaterial CS.UnityEngine.Material
---@field spriteECSMaterial CS.UnityEngine.Material
---@field textECSMaterial CS.UnityEngine.Material
---@field fadeInSpriteECSMaterial CS.UnityEngine.Material
---@field fadeOutSpriteECSMaterial CS.UnityEngine.Material
---@field fadeInTextECSMaterial CS.UnityEngine.Material
---@field fadeOutTextECSMaterial CS.UnityEngine.Material
---@field t number
---@field colorSelf CS.UnityEngine.Color
---@field colorFriendly CS.UnityEngine.Color
---@field colorNeutral CS.UnityEngine.Color
---@field colorHostile CS.UnityEngine.Color
---@field 
local MapHUDModule = class("MapHUDModule", BaseModule)

function MapHUDModule:ctor()
    self.fadeDuration = 0
end

function MapHUDModule:Setup()
    self.settings = KingdomMapUtils.GetKingdomScene().mediator:GetEnvironmentSettings(typeof(CS.Kingdom.MapHUDSettings))
    self.spriteMaterial = self.settings.SpriteMeshMaterial
    self.textMaterial = self.settings.TextMeshMaterial
    
    self.hideSpriteMaterial = Object.Instantiate(self.spriteMaterial)
    self.hideSpriteMaterial.name = "mat_u2d_sprite_hide"
    self.hideSpriteMaterial:SetColor(ColorId, CS.UnityEngine.Color.clear)
    self.hideTextMaterial = Object.Instantiate(self.textMaterial)
    self.hideTextMaterial.name = "mat_u2d_sprite_hide"
    self.hideTextMaterial:SetColor(ColorId, CS.UnityEngine.Color.clear)

    self.fadeInSpriteMaterial = Object.Instantiate(self.spriteMaterial)
    self.fadeInSpriteMaterial.name = "mat_u2d_sprite_fade_in"
    self.fadeOutSpriteMaterial = Object.Instantiate(self.spriteMaterial)
    self.fadeOutSpriteMaterial.name = "mat_u2d_sprite_fade_out"
    
    self.fadeInTextMaterial = Object.Instantiate(self.textMaterial)
    self.fadeInTextMaterial.name = "mat_u2d_text_fade_in"
    self.fadeOutTextMaterial = Object.Instantiate(self.textMaterial)
    self.fadeOutTextMaterial.name = "mat_u2d_text_fade_out"

    self.spriteECSMaterial = self.settings.SpriteMeshECSMaterial
    self.textECSMaterial = self.settings.TextMeshECSMaterial

    self.hideSpriteECSMaterial = Object.Instantiate(self.spriteECSMaterial)
    self.hideSpriteECSMaterial.name = "mat_u2d_sprite_hide_ECS"
    self.hideSpriteECSMaterial:SetColor(ColorId, CS.UnityEngine.Color.clear)
    self.hideTextECSMaterial = Object.Instantiate(self.textECSMaterial)
    self.hideTextECSMaterial.name = "mat_u2d_sprite_hide_ECS"
    self.hideTextECSMaterial:SetColor(ColorId, CS.UnityEngine.Color.clear)

    self.fadeInSpriteECSMaterial = Object.Instantiate(self.spriteECSMaterial)
    self.fadeInSpriteECSMaterial.name = "mat_u2d_sprite_fade_in_ECS"
    self.fadeOutSpriteECSMaterial = Object.Instantiate(self.spriteECSMaterial)
    self.fadeOutSpriteECSMaterial.name = "mat_u2d_sprite_fade_out_ECS"
    
    self.fadeInTextECSMaterial = Object.Instantiate(self.textECSMaterial)
    self.fadeInTextECSMaterial.name = "mat_u2d_text_fade_in_ECS"
    self.fadeOutTextECSMaterial = Object.Instantiate(self.textECSMaterial)
    self.fadeOutTextECSMaterial.name = "mat_u2d_text_fade_out_ECS"
    
    
    self.fadeDuration = self.settings.FadeDuration

    self.colorSelf = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(ConfigRefer.ConstBigWorld:ColorSelf()):ColorStr())
    self.colorFriendly = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(ConfigRefer.ConstBigWorld:ColorFriendly()):ColorStr())
    self.colorNeutral = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(ConfigRefer.ConstBigWorld:ColorNeutral()):ColorStr())
    self.colorHostile = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(ConfigRefer.ConstBigWorld:ColorHostile()):ColorStr())

    self.colorSelfWhiteBack = UIHelper.TryParseHtmlString(ColorConsts.quality_green)
    self.colorFriendlyWhiteBack = UIHelper.TryParseHtmlString(ColorConsts.quality_blue)
    self.colorNeutralWhiteBack = UIHelper.TryParseHtmlString(ColorConsts.quality_white)
    self.colorHostileWhiteBack = UIHelper.TryParseHtmlString(ColorConsts.army_red)

    self:InitializeMaterialStates()
    self.t = -1

    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick), 1)
end

function MapHUDModule:GetColorFromHexString(colorStr)
    return UIHelper.TryParseHtmlString()
end

function MapHUDModule:ShutDown()
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))

    self.spriteMaterial = nil
    self.textMaterial = nil
    
    if Utils.IsNotNull(self.fadeInSpriteMaterial) then
        Object.Destroy(self.fadeInSpriteMaterial)
        self.fadeInSpriteMaterial = nil
    end
    if Utils.IsNotNull(self.fadeOutSpriteMaterial) then
        Object.Destroy(self.fadeOutSpriteMaterial)
        self.fadeOutSpriteMaterial = nil
    end
    if Utils.IsNotNull(self.fadeInTextMaterial) then
        Object.Destroy(self.fadeInTextMaterial)
        self.fadeInTextMaterial = nil
    end
    if Utils.IsNotNull(self.fadeOutTextMaterial) then
        Object.Destroy(self.fadeOutTextMaterial)
        self.fadeOutTextMaterial = nil
    end
    if Utils.IsNotNull(self.hideSpriteMaterial) then
        Object.Destroy(self.hideSpriteMaterial)
        self.hideSpriteMaterial = nil
    end
    if Utils.IsNotNull(self.hideTextMaterial) then
        Object.Destroy(self.hideTextMaterial)
        self.hideTextMaterial = nil
    end

    if Utils.IsNotNull(self.fadeInSpriteECSMaterial) then
        Object.Destroy(self.fadeInSpriteECSMaterial)
        self.fadeInSpriteECSMaterial = nil
    end
    if Utils.IsNotNull(self.fadeOutSpriteECSMaterial) then
        Object.Destroy(self.fadeOutSpriteECSMaterial)
        self.fadeOutSpriteECSMaterial = nil
    end
    if Utils.IsNotNull(self.fadeInTextECSMaterial) then
        Object.Destroy(self.fadeInTextECSMaterial)
        self.fadeInTextECSMaterial = nil
    end
    if Utils.IsNotNull(self.fadeOutTextECSMaterial) then
        Object.Destroy(self.fadeOutTextECSMaterial)
        self.fadeOutTextECSMaterial = nil
    end
    if Utils.IsNotNull(self.hideSpriteECSMaterial) then
        Object.Destroy(self.hideSpriteECSMaterial)
        self.hideSpriteECSMaterial = nil
    end
    if Utils.IsNotNull(self.hideTextECSMaterial) then
        Object.Destroy(self.hideTextECSMaterial)
        self.hideTextECSMaterial = nil
    end

    self.settings = nil
    self.lastLod = nil
    self.currentLod = nil
end

---@return boolean
function MapHUDModule:IsEnable()
    return Utils.IsNotNull(self.settings)
end

---@return number
function MapHUDModule:GetFadeDuration()
    return self.fadeDuration
end

function MapHUDModule:Tick(dt)
    local t = self.t
    if t >= 0 then
        t = t + dt / self.fadeDuration
        t = math.clamp01(t)
        self:RefreshMaterialStates(t)
        if t >= 1 then
            t = -1
        end
    end
    self.t = t
end

function MapHUDModule:OnLodChanged(oldLod, newLod)
    if self:IsEnable() then
        self:InitializeMaterialStates()
    end

    local oldHigh = oldLod >= KingdomConstant.HighLod
    local newHigh = newLod >= KingdomConstant.HighLod
    if newHigh and not oldHigh then
        self:ShowHud()
    elseif not newHigh and oldHigh then
        self:HideHud()    
    end
end

function MapHUDModule:InitializeMaterialStates()
    self.t = 0
    self:RefreshMaterialStates(self.t)
end

function MapHUDModule:RefreshMaterialStates(t)
    if Utils.IsNotNull(self.spriteMaterial) and Utils.IsNotNull(self.textMaterial) then
        local fadeInColor = CS.UnityEngine.Color(1, 1, 1, t)
        self.fadeInSpriteMaterial:SetColor(ColorId, fadeInColor)
        self.fadeInTextMaterial:SetColor(ColorId, fadeInColor)
        self.fadeInSpriteECSMaterial:SetColor(ColorId, fadeInColor)
        self.fadeInTextECSMaterial:SetColor(ColorId, fadeInColor)
        
        local fadeOutColor = CS.UnityEngine.Color(1, 1, 1, 1 - t)
        self.fadeOutSpriteMaterial:SetColor(ColorId, fadeOutColor)
        self.fadeOutTextMaterial:SetColor(ColorId, fadeOutColor)
        self.fadeOutSpriteECSMaterial:SetColor(ColorId, fadeOutColor)
        self.fadeOutTextECSMaterial:SetColor(ColorId, fadeOutColor)
    end
end

---@param setter CS.Lod.U2DWidgetMaterialSetter
---@param show boolean
function MapHUDModule:InitHUDFade(setter, show)
    if Utils.IsNull(setter) then        
        return
    end

    if not self:IsEnable() then
        setter:ResetMaterial()
        return
    end

    if show then
        setter:Set(self.spriteMaterial, self.textMaterial)
    else
        setter:Set(self.hideSpriteMaterial, self.hideTextMaterial)
    end
end

---@param setter CS.Lod.U2DWidgetMaterialSetter
---@param fade number
function MapHUDModule:UpdateHUDFade(setter, fade)
    if Utils.IsNull(setter) or not self:IsEnable() then
        return
    end
        
    if fade == MapHUDFadeDefine.FadeIn then
        setter:Set(self.fadeInSpriteMaterial, self.fadeInTextMaterial)
    elseif fade == MapHUDFadeDefine.FadeOut then
        setter:Set(self.fadeOutSpriteMaterial, self.fadeOutTextMaterial)
    elseif fade == MapHUDFadeDefine.Show or fade == MapHUDFadeDefine.Stay then
        setter:Set(self.spriteMaterial, self.textMaterial)
    else
        setter:Set(self.hideSpriteMaterial, self.hideTextMaterial)
    end
end

function MapHUDModule:GetColor(owner, isWhiteBackground)
    if ModuleRefer.PlayerModule:IsMine(owner) then
        return isWhiteBackground and self.colorSelfWhiteBack or self.colorSelf
    elseif ModuleRefer.PlayerModule:IsFriendly(owner) then
        return isWhiteBackground and self.colorFriendlyWhiteBack or self.colorFriendly
    --elseif ModuleRefer.PlayerModule:IsNeutral(owner.AllianceID) then
    --    return isWhiteBackground and self.colorNeutralWhiteBack or self.colorNeutral
    else
        return isWhiteBackground and self.colorHostileWhiteBack or self.colorHostile
    end
    return CS.UnityEngine.Color.white
end

function MapHUDModule:ShowHud()
    KingdomMapUtils.SwitchRenderFeature(typeof(CS.ECS.U2D.WidgetRenderFeature), "WidgetRenderFeature", true)
    CS.Grid.MapUtils.EnableWidgetMeshRenderingSystem(true)
end

function MapHUDModule:HideHud()
    KingdomMapUtils.SwitchRenderFeature(typeof(CS.ECS.U2D.WidgetRenderFeature), "WidgetRenderFeature", false)
    CS.Grid.MapUtils.EnableWidgetMeshRenderingSystem(false)
end


return MapHUDModule