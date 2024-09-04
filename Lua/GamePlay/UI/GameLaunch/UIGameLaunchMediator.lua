local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
local LoadingUtility = require('LoadingUtility')
local LoadingType = require('LoadingType')
local ArtResourceUIConsts = require('ArtResourceUIConsts')
local ArtResourceUtils = require('ArtResourceUtils')
local NativeLoadingOverlay = require('NativeLoadingOverlay')

---@class UIGameLaunchMediator : BaseUIMediator
---@field preloadingModule PreloadingModule
local UIGameLaunchMediator = class('UIGameLaunchMediator', BaseUIMediator)
function UIGameLaunchMediator:ctor()
    self.preloadingModule = ModuleRefer.PreloadingModule
end

function UIGameLaunchMediator:OnCreate()
    self.imgLoadingImage = self:Image('p_loading_image')
    -- self.imgLoadingLogo = self:Image('p_loading_logo')
    self.sliderProgressBarLoading = self:Slider('p_progress_bar_loading')
    self.textTip = self:Text('p_text_tip')
    self.btnTips = self:Button('p_btn_tips',Delegate.GetOrCreate(self,self.OnBtnTipsClicked))
    self.textLoadingDiscription = self:Text('p_text_loading_discription')
    self.textProgress = self:Text('p_text_progress')
    self.compContent = self:LuaBaseComponent('p_content')
    self.btnImg = self:Button('p_btn_img', Delegate.GetOrCreate(self, self.OnBtnImgClicked))
    self.btnCg = self:Button('p_btn_cg', Delegate.GetOrCreate(self, self.OnBtnCgClicked))
    self.textVersion = self:Text('p_text_version')
    self.goGroup = self:GameObject('p_group_btn')
    self.btnFix = self:Button('p_btn_fix', Delegate.GetOrCreate(self, self.OnBtnFixClicked))
    self.textFix = self:Text('p_text_fix', '[*]修复')
    self.btnSwitchAccount = self:Button('p_btn_switch_account', Delegate.GetOrCreate(self, self.OnBtnSwitchAccountClicked))
    self.textSwitchAccount = self:Text('p_text_switch_account', I18N.Temp().text_change_account)
    self.textHint = self:Text('p_text_hint', 'beta_test_reminder')

    self.compContent:SetVisible(false)
    self.goGroup:SetVisible(false)

    self.btnFix:SetVisible(false)
    self.btnCg:SetVisible(false)
    require('UIHelper').CalcFullFitImageSize(self.imgLoadingImage)
    -- self:UpdatePlayerId()
    self.p_progress_bar_loading_rect = self:RectTransform("p_progress_bar_loading")
end

function UIGameLaunchMediator:OnOpened(param)
    ModuleRefer.PerformanceModule:SetLoadingFinish(false)
    g_Game.PerformanceLevelManager:SetLoadingFinish(false)
end

function UIGameLaunchMediator:OnClose(data)
    ModuleRefer.PerformanceModule:SetLoadingFinish(true)
    g_Game.PerformanceLevelManager:SetLoadingFinish(true)
    NativeLoadingOverlay.Close()
end

function UIGameLaunchMediator:OnShow(param)
    self.btnImg:SetVisible(false)
    self.btnCg:SetVisible(false)

    g_Game:AddFrameTicker( Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.ENTER_POST_INIT_DATA_STATE, Delegate.GetOrCreate(self, self.OnEnterPostInitDataState))    
    g_Game.EventManager:AddListener(EventConst.LANGUAGE_AND_CONFIGS_READY, Delegate.GetOrCreate(self, self.OnConfigAndLanguageIsReady))
    self:OnEnterPostInitDataState()
    local lb, tr = self.p_progress_bar_loading_rect:GetViewPortCorners(g_Game.UIManager:GetUICamera())
    local pos = CS.UnityEngine.Vector2(lb.x, (tr.y + lb.y) * 0.5)
    NativeLoadingOverlay.Show(pos)
end

function UIGameLaunchMediator:OnHide(param)
    -- self.state = -1
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.ENTER_POST_INIT_DATA_STATE, Delegate.GetOrCreate(self, self.OnEnterPostInitDataState))
    g_Game.EventManager:RemoveListener(EventConst.LANGUAGE_AND_CONFIGS_READY, Delegate.GetOrCreate(self, self.OnConfigAndLanguageIsReady))
end

function UIGameLaunchMediator:OnEnterPostInitDataState()
    self:UpdatePlayerId()    
end

function UIGameLaunchMediator:OnConfigAndLanguageIsReady()    
    local lvl = LoadingUtility.GetLevel()
    self:LoadBackGround(lvl)
    self:InitTips(lvl)    
end

function UIGameLaunchMediator:UpdatePlayerId()
    local branch, subvision = g_Game.ConfigManager:GetRemoteConfigVersion()
    local postFix = ''
    if USE_LOCAL_CONFIG then
        postFix = ":local"
    elseif USE_PRIVATE_SERVER_LOCAL_CONFIG then
        postFix = ":qa"
    end

    local versionName =  string.format('%s(%s, %s)',ModuleRefer.AppInfoModule:AppVersion(), CS.DragonReborn.VersionControl.RemoteResVersion, ("%s/%s%s"):format(branch, subvision, postFix))
    local playerId = ModuleRefer.PlayerModule:GetPlayerId() or 'unknown'
    self.textVersion.text = string.format('%s: %s, PlayerId: %s', I18N.Get("version_data"), versionName, playerId)
end



function UIGameLaunchMediator:Tick(delta)
    if self.preloadingModule ~= nil and not self.preloadingModule.Finished then
        self.curProgress, self.progressInfo = self.preloadingModule:GetCurrentProgress()
    else
        self.curProgress = 1
    end

    self.sliderProgressBarLoading.value = self.curProgress
    self.textProgress.text = NumberFormatter.Percent(self.curProgress)
    self.textLoadingDiscription.text = I18N.Get(self.progressInfo)
    self:TickTip()
    local lb, tr = self.p_progress_bar_loading_rect:GetViewPortCorners(g_Game.UIManager:GetUICamera())
    local pos = CS.UnityEngine.Vector2(lb.x, (tr.y + lb.y) * 0.5)
    NativeLoadingOverlay.UpdatePos(pos)
end

function UIGameLaunchMediator:OnBtnImgClicked(args)
    --self:OnCGFinish()    
end
function UIGameLaunchMediator:OnBtnCgClicked(args)
    --self:PlayCG()
end

function UIGameLaunchMediator:OnBtnFixClicked(args)
    -- body
end
function UIGameLaunchMediator:OnBtnSwitchAccountClicked(args)
    -- body
end

function UIGameLaunchMediator:LoadBackGround(lvl)    
    local bgName = LoadingUtility.GetBackGroundImage(lvl,LoadingType.ResourceLoading)
    g_Game.SpriteManager:LoadSprite(bgName, self.imgLoadingImage)
    require('UIHelper').CalcFullFitImageSize(self.imgLoadingImage)
end

function UIGameLaunchMediator:OnBtnTipsClicked(args)    
    self:UpdateTips()
end


function UIGameLaunchMediator:InitTips(lvl)
    self.tips = LoadingUtility.GetTips(lvl,LoadingType.ResourceLoading)
    if not self.tips or #self.tips < 1 then
        self.textTip:SetVisible(false)
        self.tips = nil
        return
    end
    self.tipsIndex = math.random(1,#self.tips)
    self.tipTimer = g_Game.Time.realtimeSinceStartup - 0.5
    self:UpdateTips()
end

function UIGameLaunchMediator:UpdateTips()
    if not self.tips then
        return
    end
    if g_Game.Time.realtimeSinceStartup - self.tipTimer < 0.5 then
        return
    end
    self.textTip.text = I18N.Get(self.tips[self.tipsIndex].tip)
    self.tipsIndex = self.tipsIndex + 1
    if self.tipsIndex > #self.tips then
        self.tipsIndex = 1
    end
    self.tipTimer = g_Game.Time.realtimeSinceStartup
end

function UIGameLaunchMediator:TickTip()
    if not self.tips then
        return
    end
    if g_Game.Time.realtimeSinceStartup - self.tipTimer < self.tips[self.tipsIndex].duration then
        return
    end
    self:UpdateTips()
end

return UIGameLaunchMediator;
