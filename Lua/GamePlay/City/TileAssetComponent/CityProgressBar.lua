--- prefab:ui3d_bubble_progress

local Vector3 = CS.UnityEngine.Vector3
local Utils = require("Utils")

---@class CityProgressBar
---@field new fun():CityProgressBar
---@field root CS.UnityEngine.Transform
---@field p_position CS.UnityEngine.Transform
---@field icon CS.U2DSpriteMesh
---@field sprite CS.U2DSpriteMesh
---@field spriteB CS.U2DSpriteMesh
---@field trigger CS.DragonReborn.LuaBehaviour
---@field collider CS.UnityEngine.BoxCollider
---@field time CS.U2DTextMesh
---@field buffFlag CS.UnityEngine.GameObject
---@field deBuffFlag CS.UnityEngine.GameObject
---@field extraIconRoot CS.UnityEngine.GameObject
---@field extraIcon1 CS.U2DSpriteMesh
---@field extraIcon2 CS.U2DSpriteMesh
---@field quantityText CS.U2DTextMesh
---@field progress_root CS.UnityEngine.GameObject
---@field progress_root_icon CS.U2DSpriteMesh
---@field progress_action CS.UnityEngine.GameObject
---@field citizen_status_icon CS.U2DSpriteMesh
---@field pay_root CS.UnityEngine.GameObject
---@field pay_trigger CS.DragonReborn.LuaBehaviour
---@field pay_icon CS.U2DSpriteMesh
---@field pay_num CS.U2DTextMesh
---@field collect_effect CS.UnityEngine.GameObject
---@field collect_effect_full CS.UnityEngine.GameObject
---@field p_icon_pollution CS.UnityEngine.GameObject
---@field p_icon_danger CS.U2DSpriteMesh
---@field p_icon_creep CS.U2DSpriteMesh
---@field facingCamera CS.U2DFacingCamera
local CityProgressBar = sealedClass("CityProgressBar")
local UIHelper = require("UIHelper")

function CityProgressBar:UpdateIcon(path)
    g_Game.SpriteManager:LoadSpriteAsync(path, self.icon)
end

function CityProgressBar:UpdateIconBack(path)
    g_Game.SpriteManager:LoadSpriteAsync(path, self.progress_root_icon)
end

---@param progress number @range [0,1]
function CityProgressBar:UpdateProgress(progress)
    self.sprite.fillAmount = math.clamp01(progress)
    self.spriteB.fillAmount = math.clamp01(progress)
end

function CityProgressBar:DisplayRedBar(flag)
    self.sprite.gameObject:SetActive(not flag)
    self.spriteB.gameObject:SetActive(flag)
end

function CityProgressBar:HideAllProgressBar()
    self.sprite:SetVisible(false)
    self.spriteB:SetVisible(false)
end

---@param offset number
function CityProgressBar:UpdatePosition(offset)
    local up = self.root.up    
    self.root.localPosition = up * offset
end

function CityProgressBar:EnableTrigger(flag)
    self.collider.enabled = flag
end

---@param callback fun(trigger:CityTrigger):boolean
---@param tile CityTileBase|CityStaticObjectTile
function CityProgressBar:SetOnTrigger(callback, tile, blockRaycast)
    if Utils.IsNull(self.trigger) then return end
    self.trigger.Instance:SetOnTrigger(callback, tile, blockRaycast)
end

function CityProgressBar:ShowTime(flag)
    if Utils.IsNull(self.time) then return end
    self.time:SetVisible(flag)
end

function CityProgressBar:UpdateTime(timeStr)
    self.time.text = timeStr
end

function CityProgressBar:UpdateLocalOffset(offset)
    self.root.localPosition = offset
end

function CityProgressBar:UpdateLocalRotation(eulerAngles)
    self.root.localEulerAngles = eulerAngles
end

function CityProgressBar:UpdateLocalScale(scale)
    self.root.localScale = scale
end

function CityProgressBar:UpdatePPositionScale(scale)
    self.p_position.localScale = scale
end

function CityProgressBar:ShowProgress(show)
    if Utils.IsNotNull(self.progress_root) then
        self.progress_root:SetVisible(show)
    end
end

function CityProgressBar:ShowBuffFlag(showBuff, showDeBuff)
    if Utils.IsNotNull(self.buffFlag) then
        self.buffFlag:SetVisible(showBuff)
    end
    if Utils.IsNotNull(self.deBuffFlag) then
        self.deBuffFlag:SetVisible(showDeBuff)
    end
end

function CityProgressBar:ShowExtraIcon(...)
    local arg = {...}
    if #arg <= 0 then
        if Utils.IsNotNull(self.extraIconRoot) then
            self.extraIconRoot:SetVisible(false)
        end
    else
        if Utils.IsNotNull(self.extraIconRoot) then
            self.extraIconRoot:SetVisible(true)
        end
        if Utils.IsNotNull(self.extraIcon1) then
            local icon1 = arg[1]
            if icon1 then
                g_Game.SpriteManager:LoadSpriteAsync(icon1, self.extraIcon1)
                self.extraIcon1:SetVisible(true)
            else
                self.extraIcon1:SetVisible(false)
            end
        end
        if Utils.IsNotNull(self.extraIcon2) then
            local icon2 = arg[2]
            if icon2 then
                g_Game.SpriteManager:LoadSpriteAsync(icon2, self.extraIcon2)
                self.extraIcon2:SetVisible(true)
            else
                self.extraIcon2:SetVisible(false)
            end
        end
    end
end

function CityProgressBar:ShowProgressAction(show)
    if Utils.IsNotNull(self.progress_action) then
        self.progress_action:SetVisible(show)
    end
end

function CityProgressBar:SetCountText(text)
    if Utils.IsNotNull(self.quantityText) then
        self.quantityText:SetVisible(true)
        self.quantityText.text = text
    end
end

function CityProgressBar:ShowCollect(isFull)
    if Utils.IsNotNull(self.collect_effect) then
        self.collect_effect:SetVisible(not isFull)
    end
    if Utils.IsNotNull(self.collect_effect_full) then
        self.collect_effect_full:SetVisible(isFull)
    end
end

function CityProgressBar:ResetToNormal()
    if Utils.IsNotNull(self.buffFlag) then
        self.buffFlag:SetVisible(false)
    end
    if Utils.IsNotNull(self.deBuffFlag) then
        self.deBuffFlag:SetVisible(false)
    end
    if Utils.IsNotNull(self.extraIconRoot) then
        self.extraIconRoot:SetVisible(false)
    end
    if Utils.IsNotNull(self.quantityText) then
        self.quantityText:SetVisible(false)
    end
    if Utils.IsNotNull(self.progress_action) then
        self.progress_action:SetVisible(false)
    end
    if Utils.IsNotNull(self.citizen_status_icon) then
        self.citizen_status_icon:SetVisible(false)
    end
    if Utils.IsNotNull(self.collect_effect) then
        self.collect_effect:SetVisible(false)
    end
    if Utils.IsNotNull(self.collect_effect_full) then
        self.collect_effect_full:SetVisible(false)
    end
    if Utils.IsNotNull(self.p_icon_pollution) then
        self.p_icon_pollution:SetVisible(false)
    end
    self:UpdateIconBack("sp_city_bubble_base_02")
    self:ShowTime(false)
    self:HidePayButton()
    self:ShowProgress(true)
    self:DisplayRedBar(false)
    self:SetGray(false)
    self:UpdatePPositionScale(CS.UnityEngine.Vector3.one)
end

function CityProgressBar:ShowDanger()
    if Utils.IsNotNull(self.p_icon_pollution) then
        self.p_icon_pollution:SetVisible(true)
    end
    if Utils.IsNotNull(self.p_icon_danger) then
        self.p_icon_danger:SetVisible(true)
    end
    if Utils.IsNotNull(self.p_icon_creep) then
        self.p_icon_creep:SetVisible(false)
    end
end

function CityProgressBar:ShowCreep()
    if Utils.IsNotNull(self.p_icon_pollution) then
        self.p_icon_pollution:SetVisible(true)
    end
    if Utils.IsNotNull(self.p_icon_danger) then
        self.p_icon_danger:SetVisible(false)
    end
    if Utils.IsNotNull(self.p_icon_creep) then
        self.p_icon_creep:SetVisible(true)
    end
end

function CityProgressBar:SetGray(flag)
    if Utils.IsNotNull(self.progress_root) then
        UIHelper.SetGray(self.progress_root, flag)
    end
    UIHelper.SetGray(self.icon.gameObject, flag)
end

function CityProgressBar:HidePayButton()
    if Utils.IsNull(self.pay_root) then
        return
    end
    local be = self.pay_trigger:GetLuaBehaviour("CityTrigger")
    if Utils.IsNotNull(be) then
        ---@type CityTrigger
        local trigger = be.Instance
        if Utils.IsNotNull(trigger) then
            trigger:SetOnTrigger(nil, nil, false)
        end
    end
    self.pay_root:SetVisible(false)
end

---@param tile CityTileBase
function CityProgressBar:SetupPayButton(icon, text, textColor, onClick, tile)
    if Utils.IsNotNull(self.pay_root) then
        self.pay_root:SetVisible(true)
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.pay_icon)
        self.pay_num.text = text
        self.pay_num.color = textColor
        ---@type CityTrigger
        local trigger = self.pay_trigger:GetLuaBehaviour("CityTrigger").Instance
        trigger:SetOnTrigger(onClick, tile, true)
    end
end

function CityProgressBar:UpdatePayCount(text, textColor)
    if Utils.IsNotNull(self.pay_root) then
        self.pay_num.text = text
        self.pay_num.color = textColor
    end
end

function CityProgressBar:SetOrthographicScale(scale)
    self.facingCamera.OrthographicScale = scale
end

return CityProgressBar
