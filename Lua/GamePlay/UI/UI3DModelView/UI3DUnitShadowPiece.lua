---@class UI3DUnitShadowPiece
---@field root CS.UnityEngine.Transform
local UI3DUnitShadowPiece = class("UI3DUnitShadowPiece")

function UI3DUnitShadowPiece:ctor()
    ---@type CS.UnityEngine.GameObject
    self._trackingModel = nil
    ---@type CS.UnityEngine.Transform
    self._trackingBone = nil
    ---@type CS.UnityEngine.Animator
    self._animator = nil
    ---@type boolean
    self._enabled = false
end

---@param model CS.UnityEngine.GameObject
function UI3DUnitShadowPiece:BindModel(model)
    self._trackingModel = model
    self._trackingBone = (model:GetComponentInChildren(typeof(CS.Lod0CharacterInfo)) or {}).HeadBone
end

function UI3DUnitShadowPiece:UnbindModel()
    self._trackingModel = nil
    self._trackingBone = nil
end

function UI3DUnitShadowPiece:Disable()
    self._enabled = false
    self.root.gameObject:SetActive(false)
end

function UI3DUnitShadowPiece:Enable()
    self._enabled = true
    self.root.gameObject:SetActive(true)
end

function UI3DUnitShadowPiece:Awake()
    self:Disable()
end

function UI3DUnitShadowPiece:Update()
    if not self._enabled then
        return
    end

    if self._trackingModel == nil or self._trackingBone == nil then
        return
    end

    local newPos = self._trackingBone.transform.position
    newPos.y = self.fixedPosY

    self.root.position = newPos
end

return UI3DUnitShadowPiece