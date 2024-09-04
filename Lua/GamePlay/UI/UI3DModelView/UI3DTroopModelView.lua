---TODO: 这版本先不重构了，等后面有时间
local Utils = require('Utils')
local UIHelper = require('UIHelper')
local GoCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local UI3DAbstractView = require('UI3DAbstractView')
local UI3DViewConst = require('UI3DViewConst')
local UI3DTroopModelViewHelper = require('UI3DTroopModelViewHelper')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local UITroopConst = require('UITroopConst')
local EventConst = require('EventConst')
---@class UnitModelData
---@field path string
---@field model CS.UnityEngine.GameObject
---@field ring CS.UnityEngine.GameObject
---@field jobIcon CS.UnityEngine.GameObject
---@field loadState number
---@field modelInteractor UI3DTroopModelInteractor
---@field slotInteractor UI3DTroopSlotInteractor

---@class UI3DTroopModelView : UI3DAbstractView
---@field root UI3DRoot
---@field heroRoots_Single CS.UnityEngine.Transform[]
---@field petRoots_Single CS.UnityEngine.Transform[]
---@field heroRoots_L CS.UnityEngine.Transform[]
---@field petRoots_L CS.UnityEngine.Transform[]
---@field heroRoots_R CS.UnityEngine.Transform[]
---@field petRoots_R CS.UnityEngine.Transform[]
---@field leftRoot CS.UnityEngine.Transform
---@field rightRoot CS.UnityEngine.Transform
---@field singleRoot CS.UnityEngine.Transform
---@field lightTrans CS.UnityEngine.Transform
---@field litPosition CS.UnityEngine.Vector3
---@field litRotate CS.UnityEngine.Vector3
---@field rootFlag CS.UnityEngine.Transform
---@field envRoot CS.UnityEngine.Transform
---@field heroes_S UnitModelData[]
---@field pets_S UnitModelData[]
---@field heroes_L UnitModelData[]
---@field pets_L UnitModelData[]
---@field heroes_R UnitModelData[]
---@field pets_R UnitModelData[]
---@field virtualCam CS.Cinemachine.CinemachineVirtualCamera[]
---@field createHelper CS.DragonReborn.AssetTool.GameObjectCreateHelper
---@field initPosVfxGo  CS.UnityEngine.GameObject[]
---@field transPosVfxGo  CS.UnityEngine.GameObject[]
local UI3DTroopModelView = class('UI3DTroopModelView',UI3DAbstractView)
UI3DTroopModelView.AssetPath = 'ui3d_troop_model_view'
UI3DTroopModelView.DefaultAnimName = 'idle'
UI3DTroopModelView.MapMark = 10
UI3DTroopModelView.UI3DLayer = 17
UI3DTroopModelView.UI3DCharactor = 19

UI3DTroopModelView.HeroRingPrefabPath = {
    [0] = 'vfx_select_hero_grey',
    [1] = 'vfx_select_hero_grey',
    [2] = 'vfx_select_hero_blue',
    [3] = 'vfx_select_hero_purple',
    [4] = 'vfx_select_hero_orange',
}

UI3DTroopModelView.PetRingPrefabPath = {
    [0] = 'vfx_select_hero_grey',
    [1] = 'vfx_select_hero_grey',
    [2] = 'vfx_select_hero_blue',
    [3] = 'vfx_select_hero_purple',
    [4] = 'vfx_select_hero_orange',
}

UI3DTroopModelView.JobIconPrefabPath = {
    [1] = 'vfx_select_hero_defend',
    [2] = 'vfx_select_hero_attack',
    [3] = 'vfx_select_hero_doctor',
}


UI3DTroopModelView.InitPosVfxPath = "vfx_w_3dui_select_hero"
UI3DTroopModelView.TransPosVfxPath = "vfx_w_3dui_change_hero_middle"

local UnitLoadState = {
    None = 0,
    ModelLoaded = 1,
    RingLoaded = 2,
    JobIconLoaded = 4,
    AllLoaded = 7,
}

local UI3D_RENDERER_DATA_INDEX = 2
local MODEL_LAYER_MASK =  1 << UI3DTroopModelView.MapMark | 1 << UI3DTroopModelView.UI3DLayer | 1 << UI3DTroopModelView.UI3DCharactor
local EFFECT_LAYER_MASK = 1 << UI3DTroopModelView.MapMark | 1 << UI3DTroopModelView.UI3DLayer

local MaxPos = 3
---@param parent CS.UnityEngine.Transform
---@param callBack fun(go:CS.UnityEngine.GameObject)
function UI3DTroopModelView.CreateViewer(parent,callBack)
    local creater = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()
    creater:Create(UI3DTroopModelView.AssetPath,parent,callBack)
    return creater
end

function UI3DTroopModelView:GetType()
    return  UI3DViewConst.ViewType.TroopViewer
end

function UI3DTroopModelView:Awake()
end

function UI3DTroopModelView:Start()
end

function UI3DTroopModelView:OnEnable()
    self.createHelper = GoCreateHelper.Create()
    self.heroes_S = {}
    self.pets_S = {}
    self.heroes_L = {}
    self.pets_L = {}
    self.heroes_R = {}
    self.pets_R = {}
    self.leftRoot = self.behaviour.transform:Find('model_root/Left')
    self.rightRoot = self.behaviour.transform:Find('model_root/Right')
    self.singleRoot = self.behaviour.transform:Find('model_root/Single')
    self:ResetViewer()

    g_Game.EventManager:AddListener(EventConst.ON_DEPLOY_VFX_LOADED, Delegate.GetOrCreate(self, self.OnLoadDeployVfx))
    g_Game.EventManager:AddListener(EventConst.ON_LOCKED_SLOT_RING_LOADED, Delegate.GetOrCreate(self, self.OnLoadLockedSlotRing))
end

function UI3DTroopModelView:OnDestroy()
    self:Clear()

    g_Game.EventManager:RemoveListener(EventConst.ON_DEPLOY_VFX_LOADED, Delegate.GetOrCreate(self, self.OnLoadDeployVfx))
    g_Game.EventManager:RemoveListener(EventConst.ON_LOCKED_SLOT_RING_LOADED, Delegate.GetOrCreate(self, self.OnLoadLockedSlotRing))
end

---@param unitDatas UnitModelData[]
function UI3DTroopModelView.ClearUnitDatas(unitDatas)
    if unitDatas then
        for _, value in pairs(unitDatas) do
            if Utils.IsNotNull(value.model) then
                GoCreateHelper.DestroyGameObject(value.model)
                value.model = nil
            end
            if Utils.IsNotNull(value.ring) then
                GoCreateHelper.DestroyGameObject(value.ring)
                value.ring = nil
            end
            if Utils.IsNotNull(value.jobIcon) then
                GoCreateHelper.DestroyGameObject(value.jobIcon)
                value.jobIcon = nil
            end
        end
    end
end



function UI3DTroopModelView:Clear()
    UI3DTroopModelView.ClearUnitDatas(self.heroes_S)
    UI3DTroopModelView.ClearUnitDatas(self.pets_S)
    UI3DTroopModelView.ClearUnitDatas(self.heroes_L)
    UI3DTroopModelView.ClearUnitDatas(self.pets_L)
    UI3DTroopModelView.ClearUnitDatas(self.heroes_R)
    UI3DTroopModelView.ClearUnitDatas(self.pets_R)

    if Utils.IsNotNull(self.curEnvGo) then
        GoCreateHelper.DestroyGameObject(self.curEnvGo)
        self.curEnvGo = nil
    end

    self.curEnvPath = ''
    self.curEnvGo = nil
    self.heroes_L = {}
    self.pets_L = {}
    self.heroes_R = {}
    self.pets_R = {}
    self.createHelper:CancelAllCreate()
end

---@param root UI3DRoot
function UI3DTroopModelView:Init(root)
    self.root = root
end

---@param data UI3DViewerParam
function UI3DTroopModelView:FeedData(data)

    self.viewType = data.type or UI3DViewConst.TroopViewType.SingleTroop
    self:EnableVirtualCamera(self.viewType,true)
    if self.viewType == UI3DViewConst.TroopViewType.SingleTroop then
        self:SetVisible_Single(true)
        self:SetVisible_L(false)
        self:SetVisible_R(false)
    else
        self:SetVisible_Single(false)
        self:SetVisible_L(true)
        self:SetVisible_R(true)
    end

    if data.preCallback then
        data.preCallback(self)
    end

    if not data.envPath then
        if data.callback then
            data.callback(self)
        end
    else
        self:SetupEnv(data.envPath, function()
            if  data.callback then
                data.callback(self)
            end
        end)
    end
end

function UI3DTroopModelView:InitVirtualCameraSetting(cameraSettings)
end

function UI3DTroopModelView:EnableVirtualCamera(index,imm)
    index = index - 1
    local enableKey = nil
    if imm then
        if self.waiter  then
            self.waiter:Stop()
        end
       self.root:SetCamBrainBlendAsCut()
    end
    for key, value in pairs(self.virtualCam) do
        -- body
        if key == index then
            value.gameObject:SetActive(true)
            enableKey = key
        else
            value.gameObject:SetActive(false)
        end
    end
    if not enableKey then
        enableKey = 0
        self.virtualCam[0].gameObject:SetActive(true)
    end
    if imm then
        self.waiter = TimerUtility.DelayExecuteInFrame(function()
            self.root:SetCamBrainBlendAsLinear()
        end,2)
    end
end

function UI3DTroopModelView:EnableVirtualCameraOffset(enable)
    if enable then
        self:EnableVirtualCamera(self.viewType + 2)
    else
        self:EnableVirtualCamera(self.viewType)
    end
end

function UI3DTroopModelView:SetupEnv(path,callback)
    if self.curEnvPath == path then
        if callback then
            callback()
        end
        return false
    end
    local envLoadedState = 0
    self.createHelper:CancelAllCreate()
    self:CancelAllUnitsLoaded()
    if Utils.IsNotNull(self.curEnvGo) then
        GoCreateHelper.DestroyGameObject(self.curEnvGo)
        self.curEnvGo = nil
    end
    self.curEnvPath = path
    self.createHelper:Create(path,self.envRoot,function(go)
        self.curEnvGo = go
        go.transform.localPosition = CS.UnityEngine.Vector3.zero
        go.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
        go.transform.localScale = CS.UnityEngine.Vector3.one
        envLoadedState = envLoadedState + 1
        if envLoadedState == 3 then
            if callback then
                callback()
            end
        end
    end)
    self.lightTrans:SetVisible(false)
    if not self.initPosVfxGo then
        self.createHelper:Create(UI3DTroopModelView.InitPosVfxPath,self.envRoot,function(go)
            if go then
                go:SetActive(false)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                ---@type CS.UnityEngine.GameObject[]
                self.initPosVfxGo = {}
                self.initPosVfxGo[1] = go
                for i = 2, MaxPos do
                    self.initPosVfxGo[i] = CS.UnityEngine.GameObject.Instantiate(go)
                end
                for i = 1, MaxPos do
                    self.initPosVfxGo[i].transform:SetParent(self.envRoot.transform)
                    self.initPosVfxGo[i].transform.localPosition = CS.UnityEngine.Vector3.zero
                    self.initPosVfxGo[i].transform.localEulerAngles = CS.UnityEngine.Vector3.zero
                    self.initPosVfxGo[i].transform.localScale = CS.UnityEngine.Vector3.one
                end
            end
            envLoadedState = envLoadedState + 1
            if envLoadedState == 3 then
                if callback then
                    callback()
                end
            end
        end)
    else
        envLoadedState = envLoadedState + 1
        if envLoadedState == 3 then
            if callback then
                callback()
            end
        end
    end
    if not self.transPosVfxGo then
        self.createHelper:Create(UI3DTroopModelView.TransPosVfxPath,self.envRoot,function(go)
            if go then
                go:SetActive(false)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                ---@type CS.UnityEngine.GameObject[]
                self.transPosVfxGo = {}
                self.transPosVfxGo[1] = go
                for i = 2, MaxPos do
                    self.transPosVfxGo[i] = CS.UnityEngine.GameObject.Instantiate(go)
                end
                for i = 1, MaxPos do
                    self.transPosVfxGo[i].transform:SetParent(self.envRoot.transform)
                    self.transPosVfxGo[i].transform.localPosition = CS.UnityEngine.Vector3.zero
                    self.transPosVfxGo[i].transform.localEulerAngles = CS.UnityEngine.Vector3.zero
                    self.transPosVfxGo[i].transform.localScale = CS.UnityEngine.Vector3.one
                end
            end
            envLoadedState = envLoadedState + 1
            if envLoadedState == 3 then
                if callback then
                    callback()
                end
            end
        end)
    else
        envLoadedState = envLoadedState + 1
        if envLoadedState == 3 then
            if callback then
                callback()
            end
        end
    end
    return true
end

function UI3DTroopModelView:ResetViewer()
    self.lightTrans.localPosition = self.litPosition
    self.lightTrans.localEulerAngles = self.litRotate
end

---@param unitDatas UnitModelData[]
function UI3DTroopModelView.IsAllUnitLoadedFinish(unitDatas)
    if unitDatas == nil or #unitDatas == 0 then
        return true
    end
    local finish = true
    for i = 1, #unitDatas do
        if unitDatas[i].loadState < UnitLoadState.AllLoaded then
            finish = false
            break
        end
    end
    return finish
end

---@param data ModelSetupData
---@param pathes string[]
---@param ringTypes number[]
---@param jobTypes number[]
---@param unitDatas UnitModelData[]
---@param unitRoots CS.UnityEngine.Transform[]
---@param callback fun(result:boolean)
---@param depUnitDatas UnitModelData[]
function UI3DTroopModelView:SetupUnits(data, unitDatas, unitRoots, callback, depUnitDatas, isRight)
    if not unitDatas or not unitRoots then
        if callback then
            callback(false)
        end
        return
    end
    local isHero = data.isHero
    local pathes = data.pathes
    local ringTypes = data.ringTypes
    local scale = data.scale
    -- local jobTypes = data.jobTypes
    local anims = data.anims

    for key, value in pairs(unitRoots) do
        local index = key + 1
        local needReset = false
        local depUnitData = depUnitDatas and depUnitDatas[index] or nil

        local modelInteractor = (value.gameObject:GetLuaBehaviour("UI3DTroopModelInteractor") or {}).Instance

        if (not isHero and string.IsNullOrEmpty(pathes[index])) then
            ---宠物没有模型时，不显示
            if unitDatas[index] then
                unitDatas[index].path = nil
                if Utils.IsNotNull(unitDatas[index].model) then
                    if modelInteractor then
                        modelInteractor:UnbindModel()
                    end
                    GoCreateHelper.DestroyGameObject(unitDatas[index].model)
                    unitDatas[index].model = nil
                end
                if Utils.IsNotNull(unitDatas[index].ring) then
                    GoCreateHelper.DestroyGameObject(unitDatas[index].ring)
                    unitDatas[index].ring = nil
                end
                -- if Utils.IsNotNull(unitDatas[index].jobIcon) then
                --     GoCreateHelper.DestroyGameObject(unitDatas[index].jobIcon)
                --     unitDatas[index].jobIcon = nil
                -- end
                unitDatas[index].loadState = UnitLoadState.None
            end
        else
            if unitDatas[index] and unitDatas[index].path ~= pathes[index] then
                unitDatas[index].path = pathes[index]
                needReset = true
            elseif not unitDatas[index] then
                unitDatas[index] = {path = pathes[index]}
                needReset = true
            end

            if unitDatas[index].path == nil then
                needReset = true
            end
        end

        if not needReset then
            if anims and anims[index] and unitDatas[index] and unitDatas[index].model then
                ---@type CS.UnityEngine.Animator
                local animator = unitDatas[index].model:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
                if animator then
                    animator:Play(anims[index])
                end
            end
            goto continue
        end

        unitDatas[index].modelInteractor = modelInteractor

        if Utils.IsNotNull(unitDatas[index].model) then
            if modelInteractor then
                modelInteractor:UnbindModel()
            end
            GoCreateHelper.DestroyGameObject(unitDatas[index].model)
            unitDatas[index].model = nil
        end
        if Utils.IsNotNull(unitDatas[index].ring) then
            GoCreateHelper.DestroyGameObject(unitDatas[index].ring)
            unitDatas[index].ring = nil
        end
        if Utils.IsNotNull(unitDatas[index].jobIcon) then
            GoCreateHelper.DestroyGameObject(unitDatas[index].jobIcon)
            unitDatas[index].jobIcon = nil
        end
        unitDatas[index].loadState = UnitLoadState.None

        local modelPath = unitDatas[index].path
        if string.IsNullOrEmpty(modelPath) then
            unitDatas[index].loadState = UnitLoadState.ModelLoaded
        else
            self.createHelper:Create(modelPath,value,function(go)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                if go then
                    if go.transform.name ~= modelPath then
                        GoCreateHelper.DestroyGameObject(go)
                        return
                    end
                    unitDatas[index].model = go
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one * scale[index]
                    if anims and anims[index] then
                        ---@type CS.UnityEngine.Animator
                        local animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
                        if animator then
                            animator:Play(anims[index])
                        end
                    end
                    if modelInteractor then
                        modelInteractor:BindModel(go.transform)
                    end
                else
                    unitDatas[index].model = nil
                end
                unitDatas[index].loadState = unitDatas[index].loadState + UnitLoadState.ModelLoaded
                if UI3DTroopModelView.IsAllUnitLoadedFinish(unitDatas) then
                    if callback then
                        callback(true)
                    end
                end
            end)
        end

        local ringType = ringTypes[index] or 0
        if string.IsNullOrEmpty(modelPath) then
           ringType = 0
        end
        local ringPath = isHero and UI3DTroopModelView.HeroRingPrefabPath[ringType] or UI3DTroopModelView.PetRingPrefabPath[ringType]
        self.createHelper:Create(ringPath,value,function(go)
            UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
            if go then
                unitDatas[index].ring = go
                go.transform.localPosition = CS.UnityEngine.Vector3.zero
                go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
                go.transform.localScale = CS.UnityEngine.Vector3.one
            else
                unitDatas[index].ring = nil
            end
            unitDatas[index].loadState = unitDatas[index].loadState + UnitLoadState.RingLoaded
            if UI3DTroopModelView.IsAllUnitLoadedFinish(unitDatas) then
                if callback then
                    callback(true)
                end
            end
        end)

        if isHero and not unitDatas[index].jobIcon then
            ---不再显示职业图标，改为一直显示站位序号
            -- local jobType = jobTypes and jobTypes[index] or -1
            local jobPath = UI3DTroopModelView.JobIconPrefabPath[index]
            if false then -- 095不显示序号
                self.createHelper:Create(jobPath,value,function(go)
                    UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                    if go then
                        unitDatas[index].jobIcon = go
                        go.transform.localPosition = CS.UnityEngine.Vector3.zero
                        go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
                        go.transform.localScale = CS.UnityEngine.Vector3.one
                        -- slotInteractor:BindModel(go.transform)
                    else
                        unitDatas[index].jobIcon = nil
                    end
                    unitDatas[index].loadState = unitDatas[index].loadState + UnitLoadState.JobIconLoaded
                    if UI3DTroopModelView.IsAllUnitLoadedFinish(unitDatas) then
                        if callback then
                            callback(true)
                        end
                    end
                end)
            else
                unitDatas[index].loadState = unitDatas[index].loadState + UnitLoadState.JobIconLoaded
            end
        else
            unitDatas[index].loadState = unitDatas[index].loadState + UnitLoadState.JobIconLoaded
        end

        ::continue::
    end
end

---@param unitDatas UnitModelData[]
---@param index number
function UI3DTroopModelView:RemoveUnit(unitDatas, index)
    if Utils.IsNotNull(unitDatas[index].model) then
        if unitDatas[index].modelInteractor then
            unitDatas[index].modelInteractor:UnbindModel()
        end
        GoCreateHelper.DestroyGameObject(unitDatas[index].model)
        unitDatas[index].model = nil
    end
    if Utils.IsNotNull(unitDatas[index].ring) then
        GoCreateHelper.DestroyGameObject(unitDatas[index].ring)
        unitDatas[index].ring = nil
    end
    unitDatas[index].path = nil
    unitDatas[index].loadState = UnitLoadState.AllLoaded
end

---@param unitDatas UnitModelData[]
---@param indexT number
---@param model CS.UnityEngine.GameObject
---@param ring CS.UnityEngine.GameObject
---@param path string
---@return CS.UnityEngine.GameObject,CS.UnityEngine.GameObject,string
function UI3DTroopModelView:SetUnit(unitDatas,unitRoots, indexT,model,ring,path,isHero,isRight)
    local modelOld = nil
    local ringOld = nil
    local pathOld = nil
    if unitDatas[indexT] then
        modelOld = unitDatas[indexT].model
        ringOld = unitDatas[indexT].ring
        pathOld = unitDatas[indexT].path
    else
        unitDatas[indexT] = {}
    end

    unitDatas[indexT].model = model
    unitDatas[indexT].ring = ring
    unitDatas[indexT].path = path
    if unitDatas[indexT].modelInteractor and model then
        unitDatas[indexT].modelInteractor:BindModel(model.transform)
    end
    if not isHero or unitDatas[indexT].jobIcon then
        unitDatas[indexT].loadState = UnitLoadState.AllLoaded
    else
        unitDatas[indexT].loadState = UnitLoadState.ModelLoaded + UnitLoadState.RingLoaded
        local jobPath = UI3DTroopModelView.JobIconPrefabPath[indexT]
        if false then
            self.createHelper:Create(jobPath,unitRoots[indexT - 1],function(go)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                if go then
                    unitDatas[indexT].jobIcon = go
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one
                else
                    unitDatas[indexT].jobIcon = nil
                end
                unitDatas[indexT].loadState = unitDatas[indexT].loadState + UnitLoadState.JobIconLoaded
            end)
        else
            unitDatas[indexT].loadState = unitDatas[indexT].loadState + UnitLoadState.JobIconLoaded
        end
    end
    if model then
        model.transform:SetParent(unitRoots[indexT - 1],false)
    end
    if ring then
        ring.transform:SetParent(unitRoots[indexT - 1],false)
    end
    return modelOld,ringOld,pathOld
end

---@private
---@param unitDatas UnitModelData[]
---@param unitRoots CS.UnityEngine.Transform[]
---@param index number
---@param isHero boolean
---@param path string
---@param ringType number
---@param callback fun(result:boolean)
function UI3DTroopModelView:AddUnit(unitDatas,unitRoots, index, isHero, path,scale,anim ,ringType,isRight,playVfx, callback)
    local root = unitRoots[index - 1]

    if Utils.IsNull(root) then
        return
    end

    ---@type UnitModelData
    local data = unitDatas[index]
    if not data then
        data = {}
    end
    data.loadState = UnitLoadState.None
    --Model
    if data.path ~= path then
        if Utils.IsNotNull(data.model) then
            GoCreateHelper.DestroyGameObject(data.model)
            data.model = nil
        end
        data.path = path
        if string.IsNullOrEmpty(path) then
            data.loadState = data.loadState + UnitLoadState.ModelLoaded
        else
            self.createHelper:Create(path,root,function(go)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                if go then
                    if go.transform.name ~= path then
                        GoCreateHelper.DestroyGameObject(go)
                        return
                    end
                    data.model = go
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one * scale
                    if isHero and playVfx then
                        self:PlayHeroLoadedVfx(index,root)
                    end
                    if not string.IsNullOrEmpty(anim) then
                        ---@type CS.UnityEngine.Animator
                        local animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
                        if animator then
                            animator:Play(anim)
                        end
                    end
                    if data.modelInteractor then
                        data.modelInteractor:BindModel(go.transform)
                    end
                else
                    data.model = nil
                end
                data.loadState = data.loadState + UnitLoadState.ModelLoaded
                if data.loadState == UnitLoadState.AllLoaded then
                    if callback then
                        callback(true)
                    end
                end
            end)
        end
    end

    if string.IsNullOrEmpty(path) then
        ringType = 0
    end
    if Utils.IsNotNull(data.ring) then
        GoCreateHelper.DestroyGameObject(data.ring)
        data.ring = nil
    end
    local ringPath = isHero and UI3DTroopModelView.HeroRingPrefabPath[ringType] or UI3DTroopModelView.PetRingPrefabPath[ringType]
    self.createHelper:Create(ringPath,root,function(go)
        UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
        if go then
            data.ring = go
            go.transform.localPosition = CS.UnityEngine.Vector3.zero
            go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
            go.transform.localScale = CS.UnityEngine.Vector3.one
        else
            data.ring = nil
        end
        data.loadState = data.loadState + UnitLoadState.RingLoaded
        if data.loadState == UnitLoadState.AllLoaded then
            if callback then
                callback(true)
            end
        end
    end)
    if isHero and not data.jobIcon then
        local jobPath = UI3DTroopModelView.JobIconPrefabPath[index]
        if false then
            self.createHelper:Create(jobPath,root,function(go)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                if go then
                    data.jobIcon = go
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one
                else
                    data.jobIcon = nil
                end
                data.loadState = data.loadState + UnitLoadState.JobIconLoaded
                if data.loadState == UnitLoadState.AllLoaded then
                    if callback then
                        callback(true)
                    end
                end
            end)
        else
            data.loadState = data.loadState + UnitLoadState.JobIconLoaded
        end
    else
        data.loadState = data.loadState + UnitLoadState.JobIconLoaded
    end

    unitDatas[index] = data
end

function UI3DTroopModelView:ClearSlot(unitDatas,unitRoots, index, isHero)
    local root = unitRoots[index - 1]
    if Utils.IsNull(root) then
        return
    end
    ---@type UnitModelData
    local data = unitDatas[index]
    if not data then
        data = {}
    end
    data.loadState = UnitLoadState.AllLoaded
    if data.model then
        if data.modelInteractor then
            data.modelInteractor:UnbindModel()
        end
        GoCreateHelper.DestroyGameObject(data.model)
        data.model = nil
    end
    if data.ring then
        GoCreateHelper.DestroyGameObject(data.ring)
        data.ring = nil
    end
    if not isHero and data.jobIcon then
        GoCreateHelper.DestroyGameObject(data.jobIcon)
        data.jobIcon = nil
    end
end

---@private
---@param unitDatas UnitModelData[]
---@param unitRoots CS.UnityEngine.Transform[]
---@param index number
---@param isHero boolean
---@param path string
---@param ringType number
---@param callback fun(result:boolean)
function UI3DTroopModelView:SetEmptySlot(unitDatas,unitRoots, index, isHero, isRight, callback)
    local root = unitRoots[index - 1]

    if Utils.IsNull(root) then
        return
    end

    ---@type UnitModelData
    local data = unitDatas[index]
    if not data then
        data = {}
    end
    data.loadState = UnitLoadState.ModelLoaded
    local ringType = 0
    local ringPath = isHero and UI3DTroopModelView.HeroRingPrefabPath[ringType] or UI3DTroopModelView.PetRingPrefabPath[ringType]
    self.createHelper:Create(ringPath,root,function(go)
        UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
        if go then
            if Utils.IsNotNull(data.ring) then
                GoCreateHelper.DestroyGameObject(data.ring)
                data.ring = nil
            end
            data.ring = go
            go.transform.localPosition = CS.UnityEngine.Vector3.zero
            go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
            go.transform.localScale = CS.UnityEngine.Vector3.one
        else
            data.ring = nil
        end
        data.loadState = data.loadState + UnitLoadState.RingLoaded
        if data.loadState == UnitLoadState.AllLoaded then
            if callback then
                callback(true)
            end
        end
    end)
    if isHero and not data.jobIcon then
        local jobPath = UI3DTroopModelView.JobIconPrefabPath[index]
        if false then
            self.createHelper:Create(jobPath,root,function(go)
                UIHelper.SetLayer(go,UI3DTroopModelView.UI3DCharactor)
                if go then
                    if Utils.IsNotNull(data.jobIcon) then
                        GoCreateHelper.DestroyGameObject(data.jobIcon)
                        data.jobIcon = nil
                    end
                    data.jobIcon = go
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localEulerAngles = isRight and CS.UnityEngine.Vector3(0,180,0) or CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one
                else
                    data.jobIcon = nil
                end
                data.loadState = data.loadState + UnitLoadState.JobIconLoaded
                if data.loadState == UnitLoadState.AllLoaded then
                    if callback then
                        callback(true)
                    end
                end
            end)
        else
            data.loadState = data.loadState + UnitLoadState.JobIconLoaded
        end
    else
        data.loadState = data.loadState + UnitLoadState.JobIconLoaded
    end

    unitDatas[index] = data
end

---@param unitDatas UnitModelData[]
---@param unitRoots CS.UnityEngine.Transform[]
---@param index number
---@param isHero boolean
---@param path string
---@param ringType number
---@param callback fun(result:boolean)
function UI3DTroopModelView:CheckAndAddUnit(unitDatas,unitRoots, index, isHero, path,scale,anim ,ringType,isRight,playVfx, callback)
    local root = unitRoots[index - 1]

    if Utils.IsNull(root) then
        return
    end

    if string.IsNullOrEmpty(path) and not scale then
        if  not unitDatas[index] or string.IsNullOrEmpty(unitDatas[index].path ) then
            if isHero then
            --setup empty ring
                self:SetEmptySlot(unitDatas,unitRoots, index, isHero, isRight, callback)
            else
                self:ClearSlot(unitDatas,unitRoots, index, isHero)
            end
        end
    else
       self:AddUnit(unitDatas,unitRoots, index, isHero, path,scale,anim ,ringType,isRight,playVfx, callback)
    end
end


---@param data ModelViewData
function UI3DTroopModelView:SetupHeros_S(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Hero)
    self:SetupUnits(viewData,self.heroes_S,self.heroRoots_Single,callback)
end
---@param data ModelViewData
function UI3DTroopModelView:SetupPets_S(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Pet)
    self:SetupUnits(viewData,self.pets_S,self.petRoots_Single,callback,self.heroes_S)
end
---@param data ModelViewData
function UI3DTroopModelView:SetupHeros_L(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Hero)
    self:SetupUnits(viewData,self.heroes_L,self.heroRoots_L,callback)
end
---@param data ModelViewData
function UI3DTroopModelView:SetupPets_L(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Pet)
    self:SetupUnits(viewData,self.pets_L,self.petRoots_L,callback,self.heroes_L)
end
---@param data ModelViewData
function UI3DTroopModelView:SetupHeros_R(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Hero)
    self:SetupUnits(viewData,self.heroes_R,self.heroRoots_R,callback,nil,true)
end

---@param data ModelViewData
function UI3DTroopModelView:SetupPets_R(data,callback)
    local viewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Pet)
    self:SetupUnits(viewData,self.pets_R,self.petRoots_R,callback,self.heroes_R,true)
end

---@param transform CS.UnityEngine.Transform
---@return CS.UnityEngine.Transform | nil
function UI3DTroopModelView:RootTransforms_Single(transform)
    if not transform then
        return self.singleRoot
    end
    self.singleRoot = transform
end

---@param transform CS.UnityEngine.Transform
function UI3DTroopModelView:RootTransforms_L(transform)
    if not transform then
        return self.leftRoot
    end
    self.leftRoot = transform
end

---@param transform CS.UnityEngine.Transform
function UI3DTroopModelView:RootTransforms_R(transform)
    if not transform then
        return self.rightRoot
    end
    self.rightRoot = transform
end

---@param i number
---@param delta CS.UnityEngine.Transform
function UI3DTroopModelView:UpdateTransform_Single(i, delta)
    
end

---是否显示左边
---@param isVisible boolean
function UI3DTroopModelView:SetVisible_L(isVisible)
    if self.leftRoot then
        self.leftRoot.gameObject:SetActive(isVisible)
    end
end

---是否显示右边
---@param isVisible boolean
function UI3DTroopModelView:SetVisible_R(isVisible)
    if self.rightRoot then
        self.rightRoot.gameObject:SetActive(isVisible)
    end
end

function UI3DTroopModelView:SetVisible_Single(isVisible)
    if self.singleRoot then
        self.singleRoot.gameObject:SetActive(isVisible)
    end
end

---@param unitDatas UnitModelData[]
function UI3DTroopModelView.CancelUnitsLoaded(unitDatas)
    if not unitDatas then
        return
    end
    for _, value in pairs(unitDatas) do
        if value.loadState > UnitLoadState.None and value.loadState < UnitLoadState.AllLoaded then
            if Utils.IsNotNull(value.model) then
                GoCreateHelper.DestroyGameObject(value.model)
                value.model = nil
            end
            if Utils.IsNotNull(value.ring) then
                GoCreateHelper.DestroyGameObject(value.ring)
                value.ring = nil
            end
            if Utils.IsNotNull(value.jobIcon) then
                GoCreateHelper.DestroyGameObject(value.jobIcon)
                value.jobIcon = nil
            end
            value.path = nil
            value.loadState = UnitLoadState.None
        end
    end
end

function UI3DTroopModelView:OnStartLoadUnit()
    self.createHelper:CancelAllCreate()
    self:CancelAllUnitsLoaded()
    if self.switchWaiter then
        self.switchWaiter:Stop()
    end
end

function UI3DTroopModelView:CancelAllUnitsLoaded()
    UI3DTroopModelView.CancelUnitsLoaded(self.heroes_S)
    UI3DTroopModelView.CancelUnitsLoaded(self.pets_S)
    UI3DTroopModelView.CancelUnitsLoaded(self.heroes_L)
    UI3DTroopModelView.CancelUnitsLoaded(self.pets_L)
    UI3DTroopModelView.CancelUnitsLoaded(self.heroes_R)
    UI3DTroopModelView.CancelUnitsLoaded(self.pets_R)
end

---@return CS.UnityEngine.Vector3[],CS.UnityEngine.Vector3[]
function UI3DTroopModelView.GetHeroAndPetPos(heroes,pets)
    local heroPos = {}
    local petPos = {}
    if heroes then
        for key, value in pairs(heroes) do
            heroPos[key+1] = value.position
        end
    end
    if pets then
        for key, value in pairs(pets) do
            petPos[key+1] = value.position
        end
    end
    return heroPos,petPos
end
---@return CS.UnityEngine.Vector3[],CS.UnityEngine.Vector3[]
function UI3DTroopModelView:GetHeroAndPetPos_S()
    return UI3DTroopModelView.GetHeroAndPetPos(self.heroRoots_Single,self.petRoots_Single)
end
---@return CS.UnityEngine.Vector3[],CS.UnityEngine.Vector3[]
function UI3DTroopModelView:GetHeroAndPetPos_L()
    return UI3DTroopModelView.GetHeroAndPetPos(self.heroRoots_L,self.petRoots_L)
end
---@return CS.UnityEngine.Vector3[],CS.UnityEngine.Vector3[]
function UI3DTroopModelView:GetHeroAndPetPos_R()
    return UI3DTroopModelView.GetHeroAndPetPos(self.heroRoots_R,self.petRoots_R)
end

function UI3DTroopModelView:PlayHeroLoadedVfx(posIndex,root)
    local pos = root and root.position or nil

    if pos then
        self.initPosVfxGo[posIndex].transform.position = pos
        self.initPosVfxGo[posIndex]:SetActive(false)
        self.initPosVfxGo[posIndex]:SetActive(true)
    end
end

function UI3DTroopModelView:PlayTransVfx(posIndex, root,lastRoot)
    local pos = root and root.position or nil
    local lastPos = lastRoot and lastRoot.position or nil

    if pos and lastPos then
        self.transPosVfxGo[posIndex].transform.position = pos
        self.transPosVfxGo[posIndex].transform.forward =lastPos - pos
        self.transPosVfxGo[posIndex]:SetActive(false)
        self.transPosVfxGo[posIndex]:SetActive(true)
    end
end

---@param data ModelViewData
---@param type number
function UI3DTroopModelView:PlayChangePosSequence(data,type,switchDuration,playVfx,callback)
    local newHeroViewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Hero)
    local newPetViewData = UI3DTroopModelViewHelper.GenModelData(data,UI3DTroopModelViewHelper.ViewType.Pet)
    ---@type UnitModelData[]
    local heroUnitData = nil
    ---@type UnitModelData[]
    local petUnitData = nil
    ---@type CS.UnityEngine.Transform[]
    local heroRoot = nil
    ---@type CS.UnityEngine.Transform[]
    local petRoot = nil
    if type == 1 then
        heroUnitData = self.heroes_S
        petUnitData = self.pets_S
        heroRoot = self.heroRoots_Single
        petRoot = self.petRoots_Single
    elseif type == 2 then
        heroUnitData = self.heroes_L
        petUnitData = self.pets_L
        heroRoot = self.heroRoots_L
        petRoot = self.petRoots_L
    elseif type == 3 then
        heroUnitData = self.heroes_R
        petUnitData = self.pets_R
        heroRoot = self.heroRoots_R
        petRoot = self.petRoots_R
    end

    ---Make data
    local removePosH = {}
    local removePosP = {}
    local switchPos = {}
    local addPosH = {}
    local addPosP = {}

    local heroPos = {}
    local petPos = {}
    local newHeroPos = {}
    local newPetPos = {}

    for i = 1, MaxPos do
        if heroUnitData[i] and heroUnitData[i].path then
            heroPos[heroUnitData[i].path] = i
        end
        if petUnitData[i] and petUnitData[i].path then
            petPos[petUnitData[i].path] = i
        end
    end

    for i = 1, MaxPos do
        if newHeroViewData.pathes[i] then
            newHeroPos[newHeroViewData.pathes[i]] = i
        end
        if newPetViewData.pathes[i] then
            newPetPos[newPetViewData.pathes[i]] = i
        end
    end

    for i = 1, MaxPos do
        local path = newHeroViewData.pathes[i]
        if not string.IsNullOrEmpty(path) then
            local oldIndex = heroPos[path]
            if not oldIndex then
                addPosH[i] = path
            elseif oldIndex ~= i then
                switchPos[i] = oldIndex
            end
        end
        path = newPetViewData.pathes[i]
        if not string.IsNullOrEmpty(path) then
            if not petPos[path] then
                addPosP[i] = path
            end
        end

        path = heroUnitData[i] and heroUnitData[i].path or nil
        if not string.IsNullOrEmpty(path) then
            if not newHeroPos[path] then
                removePosH[i] = path
            end
        end

        path = petUnitData[i] and petUnitData[i].path or nil
        if not string.IsNullOrEmpty(path) then
            if not newPetPos[path] then
                removePosP[i] = path
            end
        end
    end

    --Remove
    for index, _ in pairs(removePosH) do
        self:RemoveUnit(heroUnitData,index)
    end

    for index, _ in pairs(removePosP) do
        self:RemoveUnit(petUnitData,index)
    end


    --switch
    local oldAssetCache = {
        H = {},
        P = {}
    }
    for toI, fromI in pairs(switchPos) do
        local modelH   =nil
        local ringH     =nil
        local pathH     =nil
        if oldAssetCache.H[fromI] then
            modelH = oldAssetCache.H[fromI].model
            ringH = oldAssetCache.H[fromI].ring
            pathH = oldAssetCache.H[fromI].path
            oldAssetCache.H[fromI] = nil
        elseif heroUnitData[fromI] then
            modelH = heroUnitData[fromI].model
            ringH = heroUnitData[fromI].ring
            pathH = heroUnitData[fromI].path
            heroUnitData[fromI].model = nil
            heroUnitData[fromI].ring = nil
            heroUnitData[fromI].path = nil
        end
        local modelOld,ringOld,pathOld = self:SetUnit(heroUnitData,heroRoot,toI,modelH,ringH,pathH,true,false)
        if modelOld or ringOld then
            oldAssetCache.H[toI] = {model = modelOld,ring = ringOld,path = pathOld}
        end
        if playVfx then
            self:PlayTransVfx(toI,heroRoot[toI - 1],heroRoot[fromI - 1])
        end

        local modelP = nil
        local ringP = nil
        local pathP = nil
        if oldAssetCache.P[fromI] then
            modelP = oldAssetCache.P[fromI].model
            ringP =  oldAssetCache.P[fromI].ring
            pathP =  oldAssetCache.P[fromI].path
            oldAssetCache.P[fromI] = nil
        elseif petUnitData[fromI] then
            modelP = petUnitData[fromI].model
            ringP = petUnitData[fromI].ring
            pathP = petUnitData[fromI].path
            petUnitData[fromI].model = nil
            petUnitData[fromI].ring = nil
            petUnitData[fromI].path = nil
        end

        modelOld,ringOld,pathOld = self:SetUnit(petUnitData,petRoot,toI,modelP,ringP,pathP,false,false)
        if modelOld then
            oldAssetCache.P[toI] = {model = modelOld,ring = ringOld,path = pathOld}
        end
    end
    if oldAssetCache.H then
        for index, value in pairs(oldAssetCache.H) do
            if value.model then
                GoCreateHelper.DestroyGameObject(value.model)
            end
            if value.ring then
                GoCreateHelper.DestroyGameObject(value.ring)
            end
        end
    end
    if oldAssetCache.P then
        for index, value in pairs(oldAssetCache.P) do
            if value.model then
                GoCreateHelper.DestroyGameObject(value.model)
            end
            if value.ring then
                GoCreateHelper.DestroyGameObject(value.ring)
            end
        end
    end

    local onUnitsLoadedFin = function()
        if UI3DTroopModelView.IsAllUnitLoadedFinish(heroUnitData) then
            if callback then
                callback()
            end
        end
    end

    local SetupUnits = function()
        for index = 1, MaxPos do
            if addPosH[index] then
                self:CheckAndAddUnit(heroUnitData,heroRoot,index,true,
                    newHeroViewData.pathes[index],newHeroViewData.scale[index],
                    newHeroViewData.anims and newHeroViewData.anims[index] or nil,
                    newHeroViewData.ringTypes[index],false,playVfx,onUnitsLoadedFin)
            else
                self:CheckAndAddUnit(heroUnitData,heroRoot,index,true,nil,nil,nil,nil,false,playVfx,onUnitsLoadedFin)
            end
            if addPosP[index] then
                self:CheckAndAddUnit(petUnitData,petRoot,index,false,
                newPetViewData.pathes[index],newPetViewData.scale[index],
                nil,newPetViewData.ringTypes[index],false,onUnitsLoadedFin)
            else
                self:CheckAndAddUnit(petUnitData,petRoot,index,false,nil,nil,nil,nil,false,playVfx,onUnitsLoadedFin)
            end
        end
    end

    if switchDuration  and switchDuration > 0 then
        if self.switchWaiter then
            self.switchWaiter:Stop()
        end

        self.switchWaiter = TimerUtility.DelayExecute(function()
            self.switchWaiter = nil
            --Add
            SetupUnits()
            onUnitsLoadedFin()

        end,switchDuration)
    else
        SetupUnits()
        onUnitsLoadedFin()
    end
end

function UI3DTroopModelView:LoadFlagModel(presetIndex)
    if self.flagModel then
        GoCreateHelper.DestroyGameObject(self.flagModel)
        self.flagModel = nil
    end
    local path = UI3DViewConst.TroopFlagModelPathes[presetIndex]
    self.createHelper:Create(path, self.rootFlag, Delegate.GetOrCreate(self, self.OnLoadFlagModel))
end

function UI3DTroopModelView:OnLoadFlagModel(go)
    UIHelper.SetLayer(go, UI3DTroopModelView.UI3DLayer)
    if go then
        self.flagModel = go
    else
        self.flagModel = nil
    end
end

function UI3DTroopModelView:LoadSlotHoldingVfx(slotIndex, slotType)
    if self.slotHoldingVfx then
        GoCreateHelper.DestroyGameObject(self.slotHoldingVfx)
        self.slotHoldingVfx = nil
    end
    local path = UI3DViewConst.TroopSlotHoldingVfxPath
    if slotType == UITroopConst.TroopSlotType.Hero then
        self.createHelper:Create(path, self.heroRoots_Single[slotIndex - 1], Delegate.GetOrCreate(self, self.OnLoadSlotHoldingVfx))
    else
        self.createHelper:Create(path, self.petRoots_Single[slotIndex - 1], Delegate.GetOrCreate(self, self.OnLoadSlotHoldingVfx))
    end
end

function UI3DTroopModelView:OnLoadSlotHoldingVfx(go)
    UIHelper.SetLayer(go, UI3DTroopModelView.UI3DLayer)
    if go then
        self.slotHoldingVfx = go
    else
        self.slotHoldingVfx = nil
    end
end

function UI3DTroopModelView:UnloadSlotHoldingVfx()
    if self.slotHoldingVfx then
        GoCreateHelper.DestroyGameObject(self.slotHoldingVfx)
        self.slotHoldingVfx = nil
    end
end

function UI3DTroopModelView:LoadDeployVfx(slotIndex, slotType)
    if not self.deployVfxs then
        self.deployVfxs = {}
        self.deployVfxs[UITroopConst.TroopSlotType.Hero] = {}
        self.deployVfxs[UITroopConst.TroopSlotType.Pet] = {}
    end
    if self.deployVfxs[slotType][slotIndex] then
        GoCreateHelper.DestroyGameObject(self.deployVfxs[slotType][slotIndex])
        self.deployVfxs[slotType][slotIndex] = nil
    end
    local path = UI3DViewConst.TroopDeployVfxPath
    if slotType == UITroopConst.TroopSlotType.Hero then
        self.createHelper:Create(path, self.heroRoots_Single[slotIndex - 1], function(go)
            g_Game.EventManager:TriggerEvent(EventConst.ON_DEPLOY_VFX_LOADED, go, slotType, slotIndex)
        end)
    else
        self.createHelper:Create(path, self.petRoots_Single[slotIndex - 1], function(go)
            g_Game.EventManager:TriggerEvent(EventConst.ON_DEPLOY_VFX_LOADED, go, slotType, slotIndex)
        end)
    end
end

function UI3DTroopModelView:OnLoadDeployVfx(go, type, index)
    UIHelper.SetLayer(go, UI3DTroopModelView.UI3DLayer)
    if go then
        self.deployVfxs[type][index] = go
    else
        self.deployVfxs[type][index] = nil
    end
end

function UI3DTroopModelView:LoadLockedSlotRing(slotIndex, slotType)
    if not self.lockedSlotRings then
        self.lockedSlotRings = {}
        self.lockedSlotRings[UITroopConst.TroopSlotType.Hero] = {}
        self.lockedSlotRings[UITroopConst.TroopSlotType.Pet] = {}
    end
    if self.lockedSlotRings[slotType][slotIndex] then
        GoCreateHelper.DestroyGameObject(self.lockedSlotRings[slotType][slotIndex])
        self.lockedSlotRings[slotType][slotIndex] = nil
    end
    local path = UI3DViewConst.TroopLockedSlotRingPath
    if slotType == UITroopConst.TroopSlotType.Hero then
        self.createHelper:Create(path, self.heroRoots_Single[slotIndex - 1], function(go)
            g_Game.EventManager:TriggerEvent(EventConst.ON_LOCKED_SLOT_RING_LOADED, go, slotType, slotIndex)
        end)
    else
        self.createHelper:Create(path, self.petRoots_Single[slotIndex - 1], function(go)
            g_Game.EventManager:TriggerEvent(EventConst.ON_LOCKED_SLOT_RING_LOADED, go, slotType, slotIndex)
        end)
    end
end

---@param go CS.UnityEngine.GameObject
---@param type number
---@param index number
function UI3DTroopModelView:OnLoadLockedSlotRing(go, type, index)
    UIHelper.SetLayer(go, UI3DTroopModelView.UI3DLayer)
    if go then
        go.transform.localPosition = CS.UnityEngine.Vector3(go.transform.localPosition.x, go.transform.localPosition.y + 0.1, go.transform.localPosition.z)
        self.lockedSlotRings[type][index] = go
    else
        self.lockedSlotRings[type][index] = nil
    end
end

function UI3DTroopModelView:ClearLockedSlotRing()
    for _, rings in pairs(self.lockedSlotRings or {}) do
        for _, ring in pairs(rings) do
            if ring then
                GoCreateHelper.DestroyGameObject(ring)
            end
        end
    end
end

return UI3DTroopModelView