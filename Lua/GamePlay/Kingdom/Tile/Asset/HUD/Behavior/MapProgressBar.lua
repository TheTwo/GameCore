---@prefabName:ui3d_bubble_map_progress
local Utils = require("Utils")

---@class MapProgressBar
---@field new fun():CityProgressBar
---@field root CS.UnityEngine.Transform
---@field icon CS.U2DSpriteMesh
---@field sprite CS.U2DSpriteMesh
---@field spriteB CS.U2DSpriteMesh
---@field trigger CS.DragonReborn.LuaBehaviour
---@field collider CS.UnityEngine.BoxCollider
---@field time CS.U2DTextMesh
---@field progress_root CS.UnityEngine.GameObject
---@field progress_action CS.UnityEngine.GameObject
---@field desc CS.U2DTextMesh
---@field smallRoot CS.UnityEngine.GameObject
---@field smallSprite CS.U2DSpriteMesh
---@field smallSpriteB CS.U2DSpriteMesh
---@field smallCollider CS.UnityEngine.BoxCollider
---@field p_btnCollection CS.UnityEngine.GameObject
---@field p_icon_foot CS.U2DSpriteMesh
local MapProgressBar = sealedClass("MapProgressBar")

function MapProgressBar:UseSmallState(flag)
    self.bigRoot:SetActive(not flag)
    self.smallRoot:SetActive(flag)
end

function MapProgressBar:UpdateIcon(path)
    g_Game.SpriteManager:LoadSprite(path, self.icon)
end

---@param progress number @range [0,1]
function MapProgressBar:UpdateProgress(progress)
    self.sprite.fillAmount = math.clamp01(progress)
    self.spriteB.fillAmount = math.clamp01(progress)
    self.smallSprite.fillAmount = math.clamp01(progress)
    self.smallSpriteB.fillAmount = math.clamp01(progress)
end

function MapProgressBar:DisplayRedBar(flag)
    if self.bigRoot.activeSelf then
        self.sprite.gameObject:SetActive(not flag)
        self.spriteB.gameObject:SetActive(flag)
    else
        self.smallSprite.gameObject:SetActive(not flag)
        self.smallSpriteB.gameObject:SetActive(flag)
    end
end

function MapProgressBar:UpdatePosition(offset)
    local up = self.root.up
    self.root.localPosition = up * offset
end

function MapProgressBar:EnableTrigger(flag)
    if self.bigRoot.activeSelf then
        self.collider.enabled = flag
        self.smallCollider.enabled = false
    else
        self.collider.enabled = false
        self.smallCollider.enabled = flag
    end
end

function MapProgressBar:SetTrigger(callback)
    if Utils.IsNull(self.trigger) then return end
    self.trigger.Instance:SetTrigger(callback)
end

function MapProgressBar:UpdateTime(timeStr)
    if Utils.IsNull(self.time) then return end
    self.time.gameObject:SetActive(true)
    self.time.text = timeStr
end

function MapProgressBar:UpdateLocalOffset(offset)
    self.root.localPosition = offset
end

function MapProgressBar:UpdateLocalRotation(eulerAngles)
    self.root.localEulerAngles = eulerAngles
end

function MapProgressBar:UpdateLocalScale(scale)
    self.root.localScale = scale
end

function MapProgressBar:ShowDesc(content)
    self.desc:SetVisible(true)
    self.desc.text = content
end

function MapProgressBar:HideDesc()
    self.desc:SetVisible(false)
end

function MapProgressBar:ShowFootIcon(icon)
    self.p_icon_foot:SetVisible(true)
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_foot)
end

function MapProgressBar:HideFootIcon()
    self.p_icon_foot:SetVisible(false)
end

function MapProgressBar:ShowProgress(show)
    if Utils.IsNotNull(self.progress_root) then
        self.progress_root:SetVisible(show)
    end
end

function MapProgressBar:ShowHighlightVfx(show)
    if Utils.IsNotNull(self.p_btnCollection) then
        self.p_btnCollection:SetActive(show)
    end
end

return MapProgressBar