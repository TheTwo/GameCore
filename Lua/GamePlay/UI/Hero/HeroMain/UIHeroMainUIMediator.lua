local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local UIHeroLocalData = require('UIHeroLocalData')
local ConfigRefer = require("ConfigRefer")
local Utils = require('Utils')
local I18N = require('I18N')
local HeroType = require("HeroType")
local TimerUtility = require('TimerUtility')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local AudioConsts = require("AudioConsts")
local UI3DViewConst = require('UI3DViewConst')

---@class UIHeroMainUIMediator : BaseUIMediator
---@field module HeroModule
---@field selectedHero HeroConfigCache
---@field heroList table<number,HeroConfigCache>
---@field curTab number @ 1:HeroInfo 2:HeroStrength 3:HeroSkill
---@field curPage number @ 1:HeroBaseInfo 2:HeroBreakPage 3:HeroBreakSucceed
local UIHeroMainUIMediator = class('UIHeroMainUIMediator', BaseUIMediator)

local MIN_LOOKAT = 120
local MAX_LOOKAT = 240

local GeneratorNodeName = 'p_status'

function UIHeroMainUIMediator:ctor()
    self.module = ModuleRefer.HeroModule
    self.pointerClickBlocker = false
    ---@type table<string, BaseUIComponent>
    self.createdComps = {}
    ---@type table<string, CS.UnityEngine.GameObject>
    self.createdGo = {}
    ---@type table<number, boolean>
    self.inLoadingMap = {}
    ---@type table<string, fun(...)[]>
    self.waitLoadingFuncMap = {}
end

function UIHeroMainUIMediator:OnCreate()
    --sub components
    self.goStatus                   = self:GameObject('p_status')
    self.compChildCommonBack        = self:LuaObject('child_common_btn_back')

    self.aniTrigger = self:AnimTrigger('vx_trigger')

    self:PreloadUI3DView()
end

function UIHeroMainUIMediator:UseComp(name, func)
    if self.createdComps[name] then
        if func then
            func(self.createdComps[name])
        end
    else
        if not self.inLoadingMap[name] then
            self.inLoadingMap[name] = true
            CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetCSUIMediator(), name, GeneratorNodeName, function(go)
                self.createdComps[name] = self:LuaObject(name)
                self.createdGo[name] = go
                if func then
                    func(self.createdComps[name])
                end
                self.inLoadingMap[name] = false
                if self.waitLoadingFuncMap[name] then
                    for _, f in ipairs(self.waitLoadingFuncMap[name]) do
                        f(self.createdComps[name])
                    end
                    self.waitLoadingFuncMap[name] = nil
                end
            end, false)
        elseif func then
            self.waitLoadingFuncMap[name] = self.waitLoadingFuncMap[name] or {}
            table.insert(self.waitLoadingFuncMap[name], func)
        end
    end
end

function UIHeroMainUIMediator:IsCompActive(name)
    if self.createdGo[name] then
        return self.createdGo[name].activeSelf
    end
    return false
end

function UIHeroMainUIMediator:SetCompVisible(name, visible)
    if self.createdComps[name] then
        self.createdComps[name]:SetVisible(visible)
    elseif visible then
        self:UseComp(name, function(comp)
            comp:SetVisible(true)
        end)
    end
end

function UIHeroMainUIMediator:PreloadUI3DView()
	self:SetAsyncLoadFlag()
	---@type UI3DViewerParam
	local data = {}
	data.envPath = "mdl_ui3d_background1"
    local cameraSettings = self:GetShowCameraSetting()
    g_Game.UIManager.ui3DViewManager:InitCameraTransform(cameraSettings[1])
	data.callback = function(viewer)
		self:RemoveAsyncLoadFlag()
	end
	g_Game.UIManager:SetupUI3DView(self:GetRuntimeId(), UI3DViewConst.ViewType.ModelViewer, data)
end

function UIHeroMainUIMediator:OnShow()
    if self.selectedHero and self.selectedHero[HeroType.Heros] then
        self.loadHeroModelId = nil
        self:LoadHeroModel(self.selectedHero[HeroType.Heros])
    end
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, false)
end

function UIHeroMainUIMediator:OnHide()
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, true)
end

function UIHeroMainUIMediator:OnOpened(params)
    -- g_Game.UIManager:SetZBlurVisible(false)
    if params then
        self.outSelectHeroId = params.id
        local selectType = params.type or HeroType.Heros
        ModuleRefer.HeroModule:SetHeroSelectType(selectType)
        ModuleRefer.HeroModule:SetHeroOutList(params.outList)
        self.isPvP = params.isPvP
        self.onPetModified = params.onPetModified
    else
        ModuleRefer.HeroModule:SetHeroSelectType(HeroType.Heros)
        ModuleRefer.HeroModule:SetHeroOutList(nil)
    end
    self.isPlayOpenAnim = false
    g_Game.EventManager:AddListener(EventConst.HERO_SELECT_HERO,Delegate.GetOrCreate(self,self.OnSelectHero))
    g_Game.EventManager:AddListener(EventConst.HERO_SELECT_MAINPAGE,Delegate.GetOrCreate(self,self.OnSelectMainPage))
    g_Game.EventManager:AddListener(EventConst.HERO_BREAK_THROUGH,Delegate.GetOrCreate(self,self.OnHeroBreakThrough))
    g_Game.EventManager:AddListener(EventConst.HERO_UPGREADE_SKILL,Delegate.GetOrCreate(self,self.OnSkillUpgrade))
    g_Game.EventManager:AddListener(EventConst.HERO_DATA_UPDATE,Delegate.GetOrCreate(self,self.RefreshComponent))
    g_Game.EventManager:AddListener(EventConst.HERO_LEVEL_UP,Delegate.GetOrCreate(self,self.OnHeroLevelUp))
    g_Game.EventManager:AddListener(EventConst.HERO_STRENGTH_LEVEL_UP,Delegate.GetOrCreate(self,self.OnHeroStrengthLevelUp))
    g_Game.EventManager:AddListener(EventConst.HERO_UI_CHANGE_CAMERA,Delegate.GetOrCreate(self,self.ChangeVirtualCamera))
    g_Game.EventManager:AddListener(EventConst.HERO_GET_NEW, Delegate.GetOrCreate(self, self.RefreshHeroList))
    self.sHeroDB = nil
    self.curTab = UIHeroLocalData.MainUITabType.INFO
    self.curPage = UIHeroLocalData.MainUIPageType.MAIN_PAGE
    self.aniName = nil
    self.selectedHero = {}
    self:UpdateComponents()
    self.compChildCommonBack:FeedData({title = I18N.Get("hero_hero"), onClose = Delegate.GetOrCreate(self,self.OnBackBtnClick)})
    self:DragEvent("hero_base", nil, Delegate.GetOrCreate(self, self.OnDragHero), Delegate.GetOrCreate(self, self.OnDragHeroEnd), false)
    self:PointerClick("hero_base", Delegate.GetOrCreate(self, self.OnClickHero))
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_OPEN_HERO_MEDIATOR_PENDING_RANDOM_VOICE, true)
    g_Game.EventManager:TriggerEvent(EventConst.OPEN_3D_SHOW_UI)
    self:RefreshHeroList()
end

function UIHeroMainUIMediator:OnClose()
    ModuleRefer.HeroModule:SetHeroOutList(nil)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_OPEN_HERO_MEDIATOR_PENDING_RANDOM_VOICE, false)
    g_Game.EventManager:TriggerEvent(EventConst.CLOSE_3D_SHOW_UI)
    if self.changeTimer then
        TimerUtility.StopAndRecycle(self.changeTimer)
        self.changeTimer = nil
    end
    if self.aniTimer then
        TimerUtility.StopAndRecycle(self.aniTimer)
        self.aniTimer = nil
    end
    if self.clickAniTimer then
        TimerUtility.StopAndRecycle(self.clickAniTimer)
        self.clickAniTimer = nil
    end
    if self.delayRigTimer then
        TimerUtility.StopAndRecycle(self.delayRigTimer)
        self.delayRigTimer = nil
    end
    self:ClearEffectTimer()
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    if self.voiceHandle and self.voiceHandle:IsValid() then
        g_Game.SoundManager:Stop(self.voiceHandle)
    end
    if self.animHandle and self.animHandle:IsValid() then
        g_Game.SoundManager:Stop(self.animHandle)
    end
    if self.clickHandle and self.clickHandle:IsValid() then
        g_Game.SoundManager:Stop(self.clickHandle)
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_cancel)
    g_Game.EventManager:RemoveListener(EventConst.HERO_SELECT_HERO,Delegate.GetOrCreate(self,self.OnSelectHero))
    g_Game.EventManager:RemoveListener(EventConst.HERO_SELECT_MAINPAGE,Delegate.GetOrCreate(self,self.OnSelectMainPage))
    g_Game.EventManager:RemoveListener(EventConst.HERO_BREAK_THROUGH,Delegate.GetOrCreate(self,self.OnHeroBreakThrough))
    g_Game.EventManager:RemoveListener(EventConst.HERO_UPGREADE_SKILL,Delegate.GetOrCreate(self,self.OnSkillUpgrade))
    g_Game.EventManager:RemoveListener(EventConst.HERO_DATA_UPDATE,Delegate.GetOrCreate(self,self.RefreshComponent))
    g_Game.EventManager:RemoveListener(EventConst.HERO_LEVEL_UP,Delegate.GetOrCreate(self,self.OnHeroLevelUp))
    g_Game.EventManager:RemoveListener(EventConst.HERO_STRENGTH_LEVEL_UP,Delegate.GetOrCreate(self,self.OnHeroStrengthLevelUp))
    g_Game.EventManager:RemoveListener(EventConst.HERO_UI_CHANGE_CAMERA,Delegate.GetOrCreate(self,self.ChangeVirtualCamera))
    g_Game.EventManager:RemoveListener(EventConst.HERO_GET_NEW, Delegate.GetOrCreate(self, self.RefreshHeroList))
    require("GuideUtils").GotoByGuide(36)
end

function UIHeroMainUIMediator:RefreshHeroList()
    if self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE then
        self:UseComp('child_group_left', function(comp)
            comp:OnShow()
        end)
    end
end

function UIHeroMainUIMediator:ClearEffectTimer()
    if self.levelEffectTime1 then
        TimerUtility.StopAndRecycle(self.levelEffectTime1)
        self.levelEffectTime1 = nil
    end
    if self.levelEffectTime2 then
        TimerUtility.StopAndRecycle(self.levelEffectTime2)
        self.levelEffectTime2 = nil
    end
    if self.levelEffectTime3 then
        TimerUtility.StopAndRecycle(self.levelEffectTime3)
        self.levelEffectTime3 = nil
    end
    if self.levelEffectTime4 then
        TimerUtility.StopAndRecycle(self.levelEffectTime4)
        self.levelEffectTime4 = nil
    end
end

function UIHeroMainUIMediator:UpdateComponents()
    self.heroList = self.module:GetAllHeroConfig()
    self:UseComp('child_group_left', function(comp)
        comp:SetVisible(self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE and self.curTab ~= UIHeroLocalData.MainUITabType.STRENGTH)
    end)
    self:PlayChangeAni()
    self.compChildCommonBack:SetVisible(self.curPage ~= UIHeroLocalData.MainUIPageType.BREAK_SUC)
end

function UIHeroMainUIMediator:PlayChangeAni()
    local showBasic = self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE and self.curTab == UIHeroLocalData.MainUITabType.INFO
    local showStrengthen = self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE and self.curTab == UIHeroLocalData.MainUITabType.STRENGTH
    local showEquipment = self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE and self.curTab == UIHeroLocalData.MainUITabType.EQUIP
    local showBreakSucc = self.curPage == UIHeroLocalData.MainUIPageType.BREAK_SUC
    local showBreakPage = self.curPage == UIHeroLocalData.MainUIPageType.BREAK_PAGE
    local needHideBasic = self:IsCompActive('child_group_right_basics') and not showBasic
    local needHideStrengthen = self:IsCompActive('child_group_right_strengthen') and not showStrengthen
    local needHideEquipment = self:IsCompActive('child_group_right_equipment') and not showEquipment
    local needHideBreakSucc = self:IsCompActive('child_group_break_succeed') and not showBreakSucc
    if needHideBasic then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom5)
    elseif needHideStrengthen then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom9)
    elseif needHideEquipment then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom8)
    elseif needHideBreakSucc then
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom7)
    end
    local callBack = function()
        local needShowBasic = showBasic and not self:IsCompActive('child_group_right_basics')
        local needShowStrengthen = showStrengthen and not self:IsCompActive('child_group_right_strengthen')
        local needShowEquipment = showEquipment and not self:IsCompActive('child_group_right_equipment')
        local needShowBreakSucc = showBreakSucc and not self:IsCompActive('child_group_break_succeed')
        if needShowBasic then
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        elseif needShowStrengthen then
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
        elseif needShowEquipment then
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
        elseif needShowBreakSucc then
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom4)
        end
        self:SetCompVisible('child_group_left', showBasic)
        self:SetCompVisible('child_group_right_basics', showBasic)
        self:SetCompVisible('child_group_right_strengthen', showStrengthen)
        self:SetCompVisible('child_group_right_equipment', showEquipment)
        self:SetCompVisible('child_group_break_succeed', showBreakSucc)
        self:SetCompVisible('child_group_break', showBreakPage)
    end
    self.changeTimer = TimerUtility.DelayExecute(callBack, 0.3)
end

---@param selectedHero HeroConfigCache
function UIHeroMainUIMediator:LoadHeroModel(selectedHero)
    if not selectedHero then
        return
    end
    self.isPlayAni = false
    if self.loadHeroModelId == selectedHero.id then
        return
    end
    self.loadHeroModelId = selectedHero.id
    local heroCfg = ConfigRefer.Heroes:Find(self.loadHeroModelId)
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    if resCell:ShowModel() and resCell:ShowModel() > 0 then
        self.voiceHandle = g_Game.SoundManager:PlayAudio(resCell:ShowVoiceRes())
        ModuleRefer.HeroModule:SkipTimeline()
        g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(),ConfigRefer.ArtResource:Find(resCell:ShowModel()):Path(), ConfigRefer.ArtResource:Find(resCell:ShowBackground()):Path(), nil, function(viewer)
            if not viewer then
                return
            end
            self.ui3dModel = viewer
            local scale = ConfigRefer.ArtResource:Find(resCell:ShowModel()):ModelScale()
            self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3(scale,scale,scale))
            self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))
            self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(resCell:ModelPosition(1), resCell:ModelPosition(2), resCell:ModelPosition(3)))
            self.ui3dModel:RefreshEnv()
            self.ui3dModel:InitVirtualCameraSetting(self:GetShowCameraSetting())
            self:ChangeModelState()
            self.animation = self.ui3dModel.curEnvGo.transform:Find("vx_w_hero_main/all/vx_ui_hero_main"):GetComponent(typeof(CS.UnityEngine.Animation))
            if self.animation then
                if not self.isPlayOpenAnim then
                    self.animation:Play("anim_vx_w_hero_main_open")
                    self.isPlayOpenAnim = true
                else
                    self.animation:Play("anim_vx_w_hero_main_loop")
                end
            end
            self.animHandle = g_Game.SoundManager:Play(resCell:ShowAnimationVoice())
            if resCell:LookatMe() then
                self.ui3dModel:AddHeroAimRig()
            end
            local showTimeline = resCell:ShowAnimationVFX()
            self.isPlayAni = true
            if showTimeline and showTimeline ~= "" then
                if self.ui3dModel then
                    self.ui3dModel.curModelGo:SetActive(false)
                end
                local callback = function()
                    if self.ui3dModel then
                        self.ui3dModel.curModelGo:SetActive(true)
                        self.ui3dModel:ChangeRigBuilderState(true)
                    end
                    self.ui3dModel:InitVirtualCameraSetting(self:GetCameraSetting())
                    self.isPlayAni = false
                end
                ModuleRefer.HeroModule:LoadTimeline(resCell:ShowAnimationVFX(), self.ui3dModel.moduleRoot, callback)
            else
                self.aniName = resCell:ShowAnimation()
                self.ui3dModel:PlayAnim(self.aniName)
                if self.aniTimer then
                    TimerUtility.StopAndRecycle(self.aniTimer)
                    self.aniTimer = nil
                end
                self.aniTimer = TimerUtility.IntervalRepeat(function() self:CheckIsCompleteShow() end, 0.2, -1)
            end
        end)
    end
end

function UIHeroMainUIMediator:GetCameraSetting()
    local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:HeroEuipMoveFOV(i)
        singleSetting.nearCp = ConfigRefer.ConstMain:HeroEuipMoveNCP(i)
        singleSetting.farCp = ConfigRefer.ConstMain:HeroEuipMoveFCP(i)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipCameraMove(1), ConfigRefer.ConstMain:HeroEuipCameraMove(2), ConfigRefer.ConstMain:HeroEuipCameraMove(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipCameraMove(4), ConfigRefer.ConstMain:HeroEuipCameraMove(5), ConfigRefer.ConstMain:HeroEuipCameraMove(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function UIHeroMainUIMediator:GetShowCameraSetting()
    local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:HeroEuipShowMoveFOV(i)
        singleSetting.nearCp = ConfigRefer.ConstMain:HeroEuipShowMoveNCP(i)
        singleSetting.farCp = ConfigRefer.ConstMain:HeroEuipShowMoveFCP(i)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(1), ConfigRefer.ConstMain:HeroEuipShowCameraMove(2), ConfigRefer.ConstMain:HeroEuipShowCameraMove(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(4), ConfigRefer.ConstMain:HeroEuipShowCameraMove(5), ConfigRefer.ConstMain:HeroEuipShowCameraMove(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function UIHeroMainUIMediator:CheckIsCompleteShow()
    if self.ui3dModel and  Utils.IsNotNull(self.ui3dModel.modelAnim) then
        local animState = self.ui3dModel.modelAnim:GetCurrentAnimatorStateInfo(0)
        if animState and self.aniName and animState:IsName(self.aniName) and animState.normalizedTime > 0.95 then
            if self.aniTimer then
                TimerUtility.StopAndRecycle(self.aniTimer)
                self.aniTimer = nil
            end
            self.ui3dModel:InitVirtualCameraSetting(self:GetCameraSetting())
            self.delayRigTimer = TimerUtility.DelayExecute(function()
                if self.ui3dModel then
                    self.ui3dModel:ChangeRigBuilderState(true)
                end
            end, 0.5)
            self.isPlayAni = false
        end
    end
end

function UIHeroMainUIMediator:ChangeVirtualCamera(index)
    self.ui3dModel:EnableVirtualCamera(index)
end

function UIHeroMainUIMediator:OnHeroLevelUp()
    if self.ui3dModel then
        if  self.ui3dModel.curVfxPath[1] ~= "vfx_level_hero_shengji" then
            self.ui3dModel:SetupVfx("vfx_level_hero_shengji")
        else
            if self.ui3dModel.curVfxGo[1] and Utils.IsNotNull(self.ui3dModel.curVfxGo[1]) then
                self.ui3dModel.curVfxGo[1]:SetActive(false)
                self.ui3dModel.curVfxGo[1]:SetActive(true)
            end
        end
        --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
        --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        self.ui3dModel:ChangeCameraOpaqueState(true)
        self.levelEffectTime1 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2HalfTone()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new1")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.35)
        self.levelEffectTime2 = TimerUtility.DelayExecute(function()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new2")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_02")
            self.ui3dModel:PlayCameraShake(CS.UnityEngine.Vector3.up, 4, 0.3)
        end, 0.55)
        self.levelEffectTime3 = TimerUtility.DelayExecute(function()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.68)
        self.levelEffectTime4 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2Normal()
            self.ui3dModel:ChangeCameraOpaqueState(false)
            self.ui3dModel:ClearMaterial()
        end, 0.75)
    end
    self:UpdateComponents()
end

function UIHeroMainUIMediator:OnHeroStrengthLevelUp()
    if self.ui3dModel then
        if self.ui3dModel.curVfxPath[1] ~= "vfx_level_hero_shengjie" then
            self.ui3dModel:SetupVfx("vfx_level_hero_shengjie")
        else
            if self.ui3dModel.curVfxGo[1] and Utils.IsNotNull(self.ui3dModel.curVfxGo[1]) then
                self.ui3dModel.curVfxGo[1]:SetActive(false)
                self.ui3dModel.curVfxGo[1]:SetActive(true)
            end
        end
        --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
        --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        self.ui3dModel:ChangeCameraOpaqueState(true)
        self.levelEffectTime1 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2HalfTone()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new1")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.35)
        self.levelEffectTime2 = TimerUtility.DelayExecute(function()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new2")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_02")
            self.ui3dModel:PlayCameraShake(CS.UnityEngine.Vector3.up, 2, 0.5)
        end, 0.55)
        self.levelEffectTime3 = TimerUtility.DelayExecute(function()
            --self.ui3dModel:ChangeRenderMaterial("EnhanceHalfTone", "mat_beijing_s_new3")
            --self.ui3dModel:ChangeRenderMaterial("EnhanceOutline", "mat_level_hero_shengji_fresnel_01")
        end, 0.68)
        self.levelEffectTime4 = TimerUtility.DelayExecute(function()
            self.ui3dModel:ChangeCameraRenderer2Normal()
            self.ui3dModel:ChangeCameraOpaqueState(false)
            self.ui3dModel:ClearMaterial()
        end, 0.75)
    end
end

function UIHeroMainUIMediator:OnClickHero()
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        if self.pointerClickBlocker then
            return
        end
        if self.isPlayAni then
            return
        end

        if self.loadHeroModelId == nil then
            return
        end

        local heroCfg = ConfigRefer.Heroes:Find(self.loadHeroModelId)
        if heroCfg == nil then
            g_Logger.Error('找策划配表： ConfigRefer.Heroes: '.. self.loadHeroModelId)
            return
        end
        local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
        if resCell:ClickVoiceResLength() > 1 then
            local index = resCell:ClickVoiceResLength()
            index = math.random(1, index)
            self.clickHandle = g_Game.SoundManager:PlayAudio(resCell:ClickVoiceRes(index))
        else
            self.clickHandle = g_Game.SoundManager:PlayAudio(resCell:ClickVoiceRes(1))
        end
        if resCell:RandAnimationLength() > 1 then
            local maxNum = resCell:RandAnimationLength()
            local index = math.random(1, maxNum)
            self.clickAnimName = resCell:RandAnimation(index)
            self.ui3dModel:CrossFade(self.clickAnimName)
            if resCell:RandAnimationVoiceLength() >= index then
                self.clickHandle = g_Game.SoundManager:PlayAudio(resCell:RandAnimationVoice(index))
            end
        elseif resCell:RandAnimationLength() == 1 then
            self.clickAnimName = resCell:RandAnimation(1)
            self.ui3dModel:CrossFade(self.clickAnimName)
            if resCell:RandAnimationVoiceLength() == 1 then
                self.clickHandle = g_Game.SoundManager:PlayAudio(resCell:RandAnimationVoice(1))
            end
        end
        self.isPlayAni = true
        self.clickAniTimer = TimerUtility.IntervalRepeat(function() self:CheckClickAniIsCompleteShow() end, 0.2, -1)
        if self.ui3dModel:GetModelRotateY() >= MIN_LOOKAT and self.ui3dModel:GetModelRotateY() <= MAX_LOOKAT then
            self.ui3dModel:RotateAimGo(2)
        end
    end
end

function UIHeroMainUIMediator:CheckClickAniIsCompleteShow()
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        local animState = self.ui3dModel.modelAnim:GetCurrentAnimatorStateInfo(0)
        if self.clickAnimName and animState:IsName(self.clickAnimName) then
            if animState and animState.normalizedTime > 0.95 then
                if self.clickAniTimer then
                    TimerUtility.StopAndRecycle(self.clickAniTimer)
                    self.clickAniTimer = nil
                end
                if self.ui3dModel:GetModelRotateY() >= MIN_LOOKAT and self.ui3dModel:GetModelRotateY() <= MAX_LOOKAT then
                    self.ui3dModel:RotateAimGo(2, self.ui3dModel:GetOriginPos())
                else
                    self.ui3dModel:RotateAimGo(2)
                end
                self.isPlayAni = false
            end
        end
    end
end

function UIHeroMainUIMediator:OnDragHero(go, eventData)
    if self.ui3dModel and Utils.IsNotNull(self.ui3dModel.modelAnim) then
        self.pointerClickBlocker = true
        if self.isPlayAni then
            return
        end
        local isInAim = self.ui3dModel:GetModelRotateY() >= MIN_LOOKAT and self.ui3dModel:GetModelRotateY() <= MAX_LOOKAT
        local isLeftAim = self.ui3dModel:GetModelRotateY() > MAX_LOOKAT
        local isRightAim = self.ui3dModel:GetModelRotateY() < MIN_LOOKAT
        self.ui3dModel:RotateModelY(eventData.delta.x * -0.5)
        if self.ui3dModel:GetModelRotateY() >= MIN_LOOKAT and self.ui3dModel:GetModelRotateY() <= MAX_LOOKAT then
            if isLeftAim or isRightAim then
                self.ui3dModel:RotateAimGo(2, self.ui3dModel:GetOriginPos())
            else
                self.ui3dModel:ResetAimOriginPos()
            end
        elseif isInAim then
            self.ui3dModel:RotateAimGo(2)
        end
    end
end

function UIHeroMainUIMediator:OnDragHeroEnd(go, eventData)
    self.pointerClickBlocker = false
end

function UIHeroMainUIMediator:RefreshComponent()
    self.compChildCommonBack:UpdateTitle(I18N.Get("hero_hero"))
    if self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE then
        if self.curTab == UIHeroLocalData.MainUITabType.INFO then
            self:UseComp('child_group_right_basics', function(comp)
                comp:OnShow()
            end)
        elseif self.curTab == UIHeroLocalData.MainUITabType.STRENGTH then
            self.compChildCommonBack:UpdateTitle(I18N.Get("hero_strenghth_title"))
            self:UseComp('child_group_right_strengthen', function(comp)
                comp:OnShow()
            end)
        elseif self.curTab == UIHeroLocalData.MainUITabType.SKILL then
            --self.compGroupRightSkill:OnShow()
        elseif self.curTab == UIHeroLocalData.MainUITabType.SE_SKILL then
           -- self.compGroupRightSESkill:OnShow()
        elseif self.curTab == UIHeroLocalData.MainUITabType.EQUIP then
            self.compChildCommonBack:UpdateTitle(I18N.Get("hero_equip"))
            self:UseComp('child_group_right_equipment', function(comp)
                comp:OnShow()
            end)
        end
    elseif self.curPage == UIHeroLocalData.MainUIPageType.BREAK_PAGE then
        self.compChildCommonBack:UpdateTitle(I18N.Get("hero_btn_breakthrough"))
        self:UseComp('child_group_break', function(comp)
            comp:OnShow()
        end)
    elseif self.curPage == UIHeroLocalData.MainUIPageType.BREAK_SUC then
        self:UseComp('child_group_break_succeed', function(comp)
            comp:OnShow()
        end)
    end
    self:ChangeModelState()
end

function UIHeroMainUIMediator:ChangeModelState()
end

---OnSelectHero
---@param id number HeroesConfigCell:Id()
function UIHeroMainUIMediator:OnSelectHero(id)
    self:SetSelectHero(self.heroList[id])
    self:RefreshComponent()
end

---@return HeroConfigCache
function UIHeroMainUIMediator:GetSelectHero()
    local heroType = self.module:GetHeroSelectType()
    if self.selectedHero[heroType] == nil and self.heroList ~= nil then
        if self.outSelectHeroId then
            local outType = ConfigRefer.Heroes:Find(self.outSelectHeroId):Type()
            if outType == heroType then
                self:SetSelectHero(self.heroList[self.outSelectHeroId])
                self.outSelectHeroId = nil
                return self.selectedHero[heroType]
            end
        end
        local sortList = self.module:GetSortHeroList(heroType)
        self:SetSelectHero(self.heroList[sortList[1].configCell:Id()])
    end
    return self.selectedHero[heroType]
end

function UIHeroMainUIMediator:SetSelectHero(hero)
    local heroType = self.module:GetHeroSelectType()
    self.selectedHero[heroType] = hero
    self:LoadHeroModel(hero)
end

function UIHeroMainUIMediator:OnSelectMainPage(page, tab)
    if page ~= nil then
        self.curPage = page
    end
    if tab ~= nil then
        self.curTab = tab
    end

    if self.curTab == UIHeroLocalData.MainUITabType.STRENGTH then
        self.compChildCommonBack:UpdateTitle(I18N.Get("hero_strenghth_title"))
    elseif self.curTab == UIHeroLocalData.MainUITabType.EQUIP then
        self.compChildCommonBack:UpdateTitle(I18N.Get("hero_equip"))
    else
        self.compChildCommonBack:UpdateTitle(I18N.Get("hero_hero"))
    end
    if self.curPage == UIHeroLocalData.MainUIPageType.BREAK_PAGE then
        self.compChildCommonBack:UpdateTitle(I18N.Get("hero_btn_breakthrough"))
    end
    self:UseComp('child_group_left', function (comp)
        comp:RefreshLeftState(self.curTab == UIHeroLocalData.MainUITabType.EQUIP)
    end)
    self:UpdateComponents()
end

function UIHeroMainUIMediator:OnBackBtnClick()
    if self.curPage ~= UIHeroLocalData.MainUIPageType.MAIN_PAGE then
        self:OnSelectMainPage(UIHeroLocalData.MainUIPageType.MAIN_PAGE, self.curTab)
    elseif self.curPage == UIHeroLocalData.MainUIPageType.MAIN_PAGE and self.curTab ~= UIHeroLocalData.MainUITabType.INFO then
        self:OnSelectMainPage(UIHeroLocalData.MainUIPageType.MAIN_PAGE, UIHeroLocalData.MainUITabType.INFO)
    else
        self:BackToPrevious()
    end
end

function UIHeroMainUIMediator:OnHeroBreakThrough()
    local heroType = self.module:GetHeroSelectType()
    if self.selectedHero[heroType] and self.curPage == UIHeroLocalData.MainUIPageType.BREAK_PAGE then
        self.curPage = UIHeroLocalData.MainUIPageType.BREAK_SUC
        self:UpdateComponents()
    end
end

function UIHeroMainUIMediator:OnSkillUpgrade()

end

return UIHeroMainUIMediator
