local Utils = require('Utils')

---@class UI3DRoot
---@field UICam3D CS.UnityEngine.Camera
---@field camBrain CS.Cinemachine.CinemachineBrain
local UI3DRoot = class('UI3DRoot')

function UI3DRoot:Awake()
    ---@type CS.UI3DRoot
    self.ui3DRoot = self.behaviour.gameObject:GetComponent(typeof(CS.UI3DRoot))
    self.camBrain = self.UICam3D.gameObject:GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
end

function UI3DRoot:Start()
    self.UICam3D:SetVisible(false)
end

---@return CS.UnityEngine.Bounds
function UI3DRoot:GetBackgroundBounds(gameObject)
    return self.ui3DRoot:GetBackgroundBounds(gameObject)
end

function UI3DRoot:SetupCameraCenter(x,y)
    self.ui3DRoot:SetupCameraCenter(x,y)
end

function UI3DRoot:Transform()
    return self.behaviour.transform
end

function UI3DRoot:GameObject()
    if Utils.IsNotNull(self.behaviour) then
        return self.behaviour.gameObject
    else
        return nil
    end

end

function UI3DRoot:Enable()
    self.UICam3D:SetVisible(true)
end

function UI3DRoot:Disable()
    self.UICam3D:SetVisible(false)
end

function UI3DRoot:IsEnabled()
    return self.UICam3D.gameObject.activeInHierarchy
end

function UI3DRoot:SetCamBrainBlendAsCut()
    if not self.camBrain then
        return
    end
    self.camBrain.m_DefaultBlend = CS.Cinemachine.CinemachineBlendDefinition(CS.Cinemachine.CinemachineBlendDefinition.Style.Cut, 0)
end

function UI3DRoot:SetCamBrainBlendAsLinear()
    if not self.camBrain then
        return
    end
    self.camBrain.m_DefaultBlend = CS.Cinemachine.CinemachineBlendDefinition(CS.Cinemachine.CinemachineBlendDefinition.Style.Linear, 0.5)
end

return UI3DRoot