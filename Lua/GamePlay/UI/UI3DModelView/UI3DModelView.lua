local Utils = require('Utils')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
local AssetManager = CS.DragonReborn.AssetTool.AssetManager.Instance
local GoCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local UI3DAbstractView = require('UI3DAbstractView')
local UI3DViewConst = require('UI3DViewConst')
---@class UI3DModelView : UI3DAbstractView
---@field root UI3DRoot
---@field moduleRoot CS.UnityEngine.Transform
---@field moduleRootPosition CS.UnityEngine.Vector3
---@field moduleRootRotate CS.UnityEngine.Vector3
---@field moduleRootScale number
---@field lightTrans CS.UnityEngine.Transform
---@field litPosition CS.UnityEngine.Vector3
---@field litRotate CS.UnityEngine.Vector3
---@field envRoot CS.UnityEngine.Transform
---@field defaultBack CS.UnityEngine.MeshRenderer
---@field createHelper CS.DragonReborn.AssetTool.GameObjectCreateHelper
local UI3DModelView = class('UI3DModelView',UI3DAbstractView)
UI3DModelView.AssetPath = 'ui3d_model_view'
UI3DModelView.DefaultAnimName = 'idle'
UI3DModelView.MapMark = 10
UI3DModelView.UI3DLayer = 17
UI3DModelView.UI3DCharactor = 19
UI3DModelView.RigPrefabPath = 'HeadAimRig'
local UI3D_RENDERER_DATA_INDEX = 2
local MODEL_LAYER_MASK =  1 << UI3DModelView.MapMark | 1 << UI3DModelView.UI3DLayer | 1 << UI3DModelView.UI3DCharactor
local EFFECT_LAYER_MASK = 1 << UI3DModelView.MapMark | 1 << UI3DModelView.UI3DLayer
---@param parent CS.UnityEngine.Transform
---@param callBack fun(go:CS.UnityEngine.GameObject)
function UI3DModelView.CreateViewer(parent,callBack)
    local creater = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()
    creater:Create(UI3DModelView.AssetPath,parent,callBack)
    return creater
end

function UI3DModelView:GetType()
    return  UI3DViewConst.ViewType.ModelViewer
end

function UI3DModelView:Awake()
    self.defaultBack.gameObject:SetActive(false)
    ---@type UI3DUnitShadowPiece
    self.unitShadowBehaviour = self.unitShadow.gameObject:GetLuaBehaviour("UI3DUnitShadowPiece").Instance
end

function UI3DModelView:Start()
end

function UI3DModelView:OnEnable()
    self.createHelper = GoCreateHelper.Create()
    self.curVfxPath = {}
    self.curVfxGo = {}
    self.isLoadingVfx = {}
    self:ResetViewer()
end

function UI3DModelView:OnDestroy()
    self:Clear()
    self.moduleRoot = nil
    self.virtualCam1 = nil
    self.virtualCam2 = nil
    self.lightTrans = nil
    self.defaultBack = nil

	Utils.FullGC()
end

function UI3DModelView:Clear()
    if Utils.IsNotNull(self.curModelGo) then
        GoCreateHelper.DestroyGameObject(self.curModelGo)
    end
    if Utils.IsNotNull(self.curEnvGo) then
        GoCreateHelper.DestroyGameObject(self.curEnvGo)
    end
    for _, vfxGo in ipairs(self.curVfxGo) do
        if Utils.IsNotNull(vfxGo) then
            GoCreateHelper.DestroyGameObject(vfxGo)
        end
    end
    for i = 0, self.moduleRoot.transform.childCount - 1 do
        GoCreateHelper.DestroyGameObject(self.moduleRoot.transform:GetChild(i).gameObject)
    end
    if Utils.IsNotNull(self.curOtherModelGo) then
        GoCreateHelper.DestroyGameObject(self.curOtherModelGo)
    end
    self.curVfxPath = {}
    self.curVfxGo = {}
    self.isLoadingVfx = {}
    self.curModelPath = ''
    self.curModelGo = nil
    self.curEnvPath = ''
    self.curEnvGo = nil
    self.curOtherModelPath = ''
    self.curOtherModelGo = nil
    self:StopRotateTimer()
    self.createHelper:CancelAllCreate()
    self.virtualCam1.transform.gameObject:SetActive(false)
    self.virtualCam2.transform.gameObject:SetActive(false)
    self.unitShadowBehaviour:UnbindModel()
    self.unitShadowBehaviour:Disable()
end

---@param root UI3DRoot
function UI3DModelView:Init(root)
    self.root = root
end

---@param data UI3DViewerParam
function UI3DModelView:FeedData(data)
    self:Clear()
    if data.preCallback then
        data.preCallback(self)
    end
    
    if not data.envPath then
        self:SetupDefaultBack(data.backgroundTexName)
        self:SetupModel(data.modelPath, data.callback)
    else
        self:SetupEnv(data.envPath, function()
            self:SetupModel(data.modelPath, data.callback)
        end)
    end
end

function UI3DModelView:UseShadowPiece(use)
    if use then
        self.unitShadowBehaviour:Enable()
    else
        self.unitShadowBehaviour:Disable()
    end
end

function UI3DModelView:InitVirtualCameraSetting(cameraSettings)
    local camera1 = cameraSettings[1]
    local lens1 = self.virtualCam1.m_Lens
    if camera1.fov then
        lens1.FieldOfView = camera1.fov
    end
    if camera1.nearCp then
        lens1.NearClipPlane = camera1.nearCp
    end
    if camera1.farCp then
        lens1.FarClipPlane = camera1.farCp
    end
    self.virtualCam1.m_Lens = lens1
    if  camera1.localPos then
        self.virtualCam1.transform.localPosition = camera1.localPos
    end
    if camera1.rotation then
        self.virtualCam1.transform.localEulerAngles = camera1.rotation
    else
        self.virtualCam1.transform.localEulerAngles = CS.UnityEngine.Vector3(5, 0, 0)
    end
    self.virtualCam1.transform.gameObject:SetActive(true)
    local camera2 = cameraSettings[2]
    if camera2 then
        local lens2 = self.virtualCam2.m_Lens
        lens2.FieldOfView = camera2.fov
        lens2.NearClipPlane = camera2.nearCp
        lens2.FarClipPlane = camera2.farCp
        self.virtualCam2.m_Lens = lens2
        self.virtualCam2.Priority = self.virtualCam1.Priority + 1
        self.virtualCam2.transform.localPosition = camera2.localPos
        if camera1.rotation then
            self.virtualCam2.transform.localEulerAngles = camera1.rotation
        else
            self.virtualCam2.transform.localEulerAngles = CS.UnityEngine.Vector3(5, 0, 0)
        end
        self.virtualCam2.transform.gameObject:SetActive(false)
    end
end

function UI3DModelView:InitVirtualCamera()   
    self.root:SetCamBrainBlendAsCut()    
    self.virtualCam1.transform.gameObject:SetActive(true)
    self.virtualCam2.transform.gameObject:SetActive(false)     
            
end

function UI3DModelView:EnableVirtualCamera(index)
    if index == 1 then
        self.virtualCam1.transform.gameObject:SetActive(true)
        self.virtualCam2.transform.gameObject:SetActive(false)
    else
        self.virtualCam1.transform.gameObject:SetActive(false)
        self.virtualCam2.transform.gameObject:SetActive(true)
    end
end

function UI3DModelView:ChangeModelState(isShow)
    if Utils.IsNotNull(self.curModelGo) then
        self.curModelGo:SetActive(isShow)
    end
end

function UI3DModelView:GetModelGo()
    return self.curModelGo
end

function UI3DModelView:BindShadowPieceModel(model)
    self.unitShadowBehaviour:BindModel(model)
end

function UI3DModelView:UnbindShadowPieceModel()
    self.unitShadowBehaviour:UnbindModel()
end

---@param path string
function UI3DModelView:SetupModel(path, callback)
    if self.curModelPath == path then
        if callback then
            callback()
        end
        return
    end
    self:InitVirtualCamera()
    self.createHelper:CancelAllCreate()
    if Utils.IsNotNull(self.curModelGo) then
        self:UnbindShadowPieceModel()
        GoCreateHelper.DestroyGameObject(self.curModelGo)
    end
    self.curModelPath = path
    if string.IsNullOrEmpty(path) then
        if callback then
            callback(self)
        end
        return
    end
    self.createHelper:Create(path,self.moduleRoot,function(go)
        UIHelper.SetLayer(go,UI3DModelView.UI3DCharactor)
        if go then
            if go.transform.name ~= self.curModelPath then
                GoCreateHelper.DestroyGameObject(go)
                return
            end
            self.curModelGo = go
            self.curModelGo.transform.localPosition = CS.UnityEngine.Vector3.zero
            self.curModelGo.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
            self.curModelGo.transform.localScale = CS.UnityEngine.Vector3.one
            ---@type CS.UnityEngine.Animator
            self.modelAnim = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
            self:BindShadowPieceModel(go)
        else
            self.curModelGo = nil
        end
        self:ResetModel()
        if callback then
            callback(self)
        end
    end)
    
    self.root:SetCamBrainBlendAsLinear()    
    return true
end

function UI3DModelView:ChangeEnvState(state)
    self.envRoot.gameObject:SetActive(state)
end

function UI3DModelView:SetupOtherModel(path, callback)
    if self.curOtherModelPath == path then
        return
    end
    self.createHelper:CancelAllCreate()
    if Utils.IsNotNull(self.curOtherModelGo) then
        GoCreateHelper.DestroyGameObject(self.curOtherModelGo)
    end
    self.curOtherModelPath = path
    self.createHelper:Create(path,self.moduleRoot,function(go)
        UIHelper.SetLayer(go,UI3DModelView.UI3DCharactor)
        if go then
            self.curOtherModelGo = go
            self.curOtherModelGo.transform.localPosition = CS.UnityEngine.Vector3.zero
            self.curOtherModelGo.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
            self.curOtherModelGo.transform.localScale = CS.UnityEngine.Vector3.one
            ---@type CS.UnityEngine.Animator
            self.otherModelAnim = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
        else
            self.curOtherModelGo = nil
        end
        self.otherModelAnim:Play(UI3DModelView.DefaultAnimName, 0)
        if callback then
            callback(self)
        end
    end)
end

function UI3DModelView:SetupVfx(path, index, rtsParam)
    if not index then
        index = 1
    end
    if self.curVfxPath[index] == path then
        if rtsParam.localPos then
            self.curVfxGo[index].transform.localPosition = rtsParam.localPos
        end
        if rtsParam.localRot then
            self.curVfxGo[index].transform.localEulerAngles = rtsParam.localRot
        end
        if rtsParam.localScale then
            self.curVfxGo[index].transform.localScale = rtsParam.localScale
        end
        return
    end
    if self.isLoadingVfx[index] then
        self.createHelper:CancelAllCreate()
    end
    if Utils.IsNotNull(self.curVfxGo[index]) then
        GoCreateHelper.DestroyGameObject(self.curVfxGo[index])
    end
    self.curVfxPath[index] = path
    self.isLoadingVfx[index] = true
    self.createHelper:Create(path,self.moduleRoot,function(go)
        UIHelper.SetLayer(go,UI3DModelView.UI3DLayer)
        self.curVfxGo[index]= go
        if rtsParam == nil then
            self.curVfxGo[index].transform.localPosition = CS.UnityEngine.Vector3(0, 0, 0)
            self.curVfxGo[index].transform.localEulerAngles = CS.UnityEngine.Vector3.zero
            self.curVfxGo[index].transform.localScale = CS.UnityEngine.Vector3.one
        else
            if rtsParam.localPos then
                self.curVfxGo[index].transform.localPosition = rtsParam.localPos
            end
            if rtsParam.localRot then
                self.curVfxGo[index].transform.localEulerAngles = rtsParam.localRot
            end
            if rtsParam.localScale then
                self.curVfxGo[index].transform.localScale = rtsParam.localScale
            end
        end
        self.isLoadingVfx[index] = false
    end)
    return true
end

function UI3DModelView:PlayVfx()
    for _,  vfxGo in ipairs(self.curVfxGo) do
        if vfxGo then
            vfxGo:SetActive(false)
            vfxGo:SetActive(true)
        end
    end
end

function UI3DModelView:PlayVfxByIndex(index)
    for i,  vfxGo in ipairs(self.curVfxGo) do
        if vfxGo and i == index then
            vfxGo:SetActive(false)
            vfxGo:SetActive(true)
        end
    end
end

function UI3DModelView:HideVfx()
    for _,  vfxGo in ipairs(self.curVfxGo) do
        if vfxGo then
            vfxGo:SetActive(false)
        end
    end
end


function UI3DModelView:SetupBackgroundTransform()
    local backBounds = g_Game.UIManager.ui3DViewManager:GetBackgroundBounds(self.defaultBack.gameObject)
    self.defaultBack.transform.localScale = backBounds.size
    self.defaultBack.transform.localPosition = backBounds.center
end

function UI3DModelView:ChangeCameraOpaqueState(isShow)
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:ChangeCameraOpaqueState(isShow)
end

function UI3DModelView:GetCinemachineBrain()
    return g_Game.UIManager.ui3DViewManager:UICam3D():GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
end

function UI3DModelView:ChangeCinemachineBlend(blendTime)
    local brain = self:GetCinemachineBrain()
    brain.m_DefaultBlend = CS.Cinemachine.CinemachineBlendDefinition(CS.Cinemachine.CinemachineBlendDefinition.Style.Linear, blendTime)
end

function UI3DModelView:ChangeRenderMaterial(renderName, materialName)
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:ChangeRenderMaterial(renderName, materialName)
end

function UI3DModelView:PlayCameraShake(move, speed, duration)
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:PlayCameraShake(move, speed, duration)
end

--开启halftone效果
function UI3DModelView:ChangeCameraRenderer2HalfTone()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:SetRenderObjectsEnable("EnhanceOutline", true)
    camera:SetRenderObjectsEnable("EnhanceHalfTone", true)
    --处理halftone效果毛发bug
    camera:SetRenderObjectsEnable("Fur", false)
    camera:ChangeRenderFilter(UI3D_RENDERER_DATA_INDEX, EFFECT_LAYER_MASK)
end

--开启halftone效果
function UI3DModelView:ChangeCameraRenderer2Normal()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:SetRenderObjectsEnable("EnhanceOutline", false)
    camera:SetRenderObjectsEnable("EnhanceHalfTone", false)
    --处理halftone效果毛发bug
    camera:SetRenderObjectsEnable("Fur", true)
    camera:ChangeRenderFilter(UI3D_RENDERER_DATA_INDEX, MODEL_LAYER_MASK)
end

function UI3DModelView:ClearMaterial()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera:ClearRenderMaterial("EnhanceOutline")
    camera:ClearRenderMaterial("EnhanceHalfTone")
end

function UI3DModelView:ChangeCameraState(isEnable)
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera.enabled = isEnable
end

function UI3DModelView:ChangeCameraRender(render)
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    local cameraData = camera:GetUniversalAdditionalCameraData()
    cameraData:SetRenderer(render)
end

function UI3DModelView:SetupEnvTransform()
end

function UI3DModelView:RefreshEnv()
    if self.curEnvGo then
        self:SetupEnvTransform()
    else
        self:SetupBackgroundTransform()
    end
end

function UI3DModelView:SetupDefaultBack(texName)
    self.defaultBack.gameObject:SetActive(true)

    self:SetupBackgroundTransform()

    self.defaultBack.enabled = false
    if not texName then
        texName = 'sp_hero_base_model'
    end

    AssetManager:LoadAssetAsync(texName,function(success,assetHandle)
        if not success or  Utils.IsNull(assetHandle.Asset) then
            return
        end
        self.defaultBack.enabled = true
        local rpb = CS.UnityEngine.MaterialPropertyBlock()
        self.defaultBack:GetPropertyBlock(rpb)
        rpb:SetTexture('_BaseMap',assetHandle.Asset)
        self.defaultBack:SetPropertyBlock(rpb)
    end,false)

    if Utils.IsNotNull(self.curEnvGo) then
        GoCreateHelper.DestroyGameObject(self.curEnvGo)
        self.curEnvGo = nil
        self.curEnvPath = nil
    end
    self.lightTrans:SetVisible(true)
end

function UI3DModelView:SetupEnv(path,callback)
    if self.curEnvPath == path and self.curEnvGo then
        if callback then
            callback()
        end
        return false
    end
    self.createHelper:CancelAllCreate()
    if Utils.IsNotNull(self.curEnvGo) then
        GoCreateHelper.DestroyGameObject(self.curEnvGo)
    end
    self.curEnvPath = path
    self.createHelper:Create(path,self.envRoot,function(go)
        -- UIHelper.SetLayer(go,UI3DModelView.UI3DLayer)
        -- DRUtils.SetLightsLayerMask(go,UI3DModelView.UI3DLayer)
        -- DRUtils.AddLightLayerMask(go,UI3DModelView.UI3DCharactor)
        self.curEnvGo = go
        self.defaultBack.gameObject:SetActive(false)
        if callback then
            callback()
        end
    end)
    self.lightTrans:SetVisible(false)
    return true
end

function UI3DModelView:PlayAnim(animName)
    if not self.modelAnim then
        g_Logger.Error("UI3DModelView PlayAnim modelAnim is null")
        return
    end
    g_Logger.Log("UI3DModelView PlayAnim modelAnim :" .. animName)
    self.modelAnim:Play(animName, 0)
end

function UI3DModelView:CrossFade(animName)
    if not self.modelAnim then
        g_Logger.Error("UI3DModelView PlayAnim modelAnim is null")
        return
    end
    self.modelAnim:CrossFade(animName, 0.2)
end

function UI3DModelView:ResetModel()
    g_Logger.Log("UI3DModelView ResetModel")
    self:PlayAnim(UI3DModelView.DefaultAnimName)
    self:ResetViewer()
end

function UI3DModelView:ResetViewer()
    if not self.moduleRoot then
        g_Logger.Error("UI3DModelView ResetViewer moduleRoot is null")
        return
    end
    self.moduleRoot.localPosition = self.moduleRootPosition
    self.moduleRoot.localEulerAngles = self.moduleRootRotate
    self.moduleRoot.localScale = CS.UnityEngine.Vector3.one * self.moduleRootScale

    self.lightTrans.localPosition = self.litPosition
    self.lightTrans.localEulerAngles = self.litRotate
    for _,  vfxGo in ipairs(self.curVfxGo) do
        if vfxGo then
            vfxGo:SetActive(false)
        end
    end
end

function UI3DModelView:SetModelAngles(eulerAngles)
    self.moduleRoot.localEulerAngles = eulerAngles
end

function UI3DModelView:SetModelPosition(localPos)
    self.moduleRoot.localPosition = localPos
end

function UI3DModelView:SetModelScale(scale)
    self.moduleRoot.localScale = scale
end

function UI3DModelView:SetLitAngle(eulerAngles)
    self.lightTrans.localEulerAngles = eulerAngles
end

function UI3DModelView:SetEnvTransform(pos,angle)
    self.envRoot.localPosition = pos
    self.envRoot.localEulerAngles = angle
end

---@param x number
---@param y number
function UI3DModelView:SetScreenCenter(x,y)
   self.root:SetupCameraCenter(x,y)
end


function UI3DModelView:RotateModelY(delta)
    local angles = self.moduleRoot.localEulerAngles
    angles.y =  angles.y + delta
    if angles.y > 360 then
        angles.y = angles.y - 360
    elseif angles.y < 0 then
        angles.y = angles.y + 360
    end
    self.moduleRoot.localEulerAngles = angles
end

function UI3DModelView:GetModelRotateY()
    return self.moduleRoot.localEulerAngles.y
end

function UI3DModelView:AddHeroAimRig()
    if Utils.IsNotNull(self.curModelGo) then
        local characterInfo = self.curModelGo:GetComponent(typeof(CS.Lod0CharacterInfo))
        if Utils.IsNotNull(characterInfo) then
            local animationRoot = characterInfo.AnimatorRoot
            if Utils.IsNotNull(animationRoot) then
                self.createHelper:Create(UI3DModelView.RigPrefabPath,animationRoot.transform,function(go)
                    animationRoot:AddRigBuilderLayer(go)
                    go.transform.localPosition = CS.UnityEngine.Vector3(0,0,3)
                    local animConstrain = go.transform:Find("HeadAim"):GetComponent(typeof(CS.UnityEngine.Animations.Rigging.MultiAimConstraint))
                    self.headAimGo =  go.transform:Find("HeadAim")
                    self.aimGo = go.transform:Find("HeadAim/Aim")
                    animConstrain:AddMultiAimConstraintObject(characterInfo.HeadBone.transform)
                    self:ChangeRigBuilderState(false)
                    self:RecordAimOriginPos()
                end)
            end
        end
    end
end

function UI3DModelView:ChangeRigBuilderState(state)
    if Utils.IsNotNull(self.curModelGo) then
        local characterInfo = self.curModelGo:GetComponent(typeof(CS.Lod0CharacterInfo))
        if Utils.IsNotNull(characterInfo) then
            local animationRoot = characterInfo.AnimatorRoot
            if Utils.IsNotNull(animationRoot) then
                animationRoot:ChangeRigBuilderState(state)
            end
        end
    end
end

function UI3DModelView:RecordAimOriginPos()
    if Utils.IsNotNull( self.aimGo) then
        self.aimOriginPos = self.aimGo.transform.position
        self.aimOriginLocalPos = self.aimGo.transform.localPosition
    end
end

function UI3DModelView:ResetAimOriginLocalPos()
    if Utils.IsNotNull(self.aimGo) then
        if self.rotateTimer then
            return
        end
        self.aimGo.transform.localPosition = self.aimOriginLocalPos
    end
end

function UI3DModelView:ResetAimOriginPos()
    if Utils.IsNotNull(self.aimGo) then
        if self.rotateTimer then
            return
        end
        self.aimGo.transform.position = self.aimOriginPos
    end
end

function UI3DModelView:GetOriginPos()
    return self.aimOriginPos
end

function UI3DModelView:StopRotateTimer()
    if self.rotateTimer then
        TimerUtility.StopAndRecycle(self.rotateTimer)
        self.rotateTimer = nil
    end
end

function UI3DModelView:RotateAimGo(angle, targetPosition)
    if Utils.IsNotNull(self.aimGo) then
        self.angle = angle
        self.resetAimLocal = false
        if not targetPosition then
            self.resetAimLocal = true
            targetPosition = self.headAimGo.transform.position
        end
        self.targetPosition = targetPosition
        local targetDir = self.targetPosition - self.moduleRoot.transform.position
        local aimDir = self.aimGo.transform.position - self.moduleRoot.transform.position
        local crossPro = Vector3.Cross(aimDir, targetDir)
        if crossPro.y < 0 then
            self.angle = -self.angle
        end
        self:StopRotateTimer()
        self.rotateTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnRotate), 1, -1)
    end
end

function UI3DModelView:OnRotate()
    if Utils.IsNotNull(self.aimGo) then
        local rotation = Quaternion.AngleAxis(self.angle, Vector3.up)
        self.aimGo.transform.position = rotation * (self.aimGo.transform.position - self.moduleRoot.transform.position) + self.moduleRoot.transform.position
        if math.abs(Vector3.Distance(self.aimGo.transform.position, self.targetPosition)) <= 0.2 then
            self:StopRotateTimer()
            if self.resetAimLocal then
                self:ResetAimOriginLocalPos()
            end
        end
    end
end

return UI3DModelView
