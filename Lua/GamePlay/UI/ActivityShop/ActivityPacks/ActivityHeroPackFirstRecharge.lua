local BaseActivityPack = require("BaseActivityPack")
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local ClientDataKeys = require("ClientDataKeys")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local CommonGotoDetailDefine = require("CommonGotoDetailDefine")
local KingdomMapUtils = require("KingdomMapUtils")
local BehaviourManager = require("BehaviourManager")
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local TimerUtility = require("TimerUtility")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local Utils = require("Utils")
---@class ActivityHeroPackFirstRecharge : BaseActivityPack
local ActivityHeroPackFirstRecharge = class("ActivityHeroPackFirstRecharge", BaseActivityPack)
---@scene sence_child_shop_activity

function ActivityHeroPackFirstRecharge:ctor()
    self.createHelper = PooledGameObjectCreateHelper.Create("HeroPackCreater")
    self.gestureBlocker = nil
    self.tick = true
end

function ActivityHeroPackFirstRecharge:OnShow()
    local isFirstOpen = not ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.FirstTimeOpenRechargePopup)
    local isShop = self:GetParentBaseUIMediator():GetName() == UIMediatorNames.ActivityShopMediator
    if isFirstOpen and not ModuleRefer.ActivityShopModule.isFirstRechargeTimelinePlayed and not isShop then
        ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.FirstTimeOpenRechargePopup, "1")
        self:GetParentBaseUIMediator():CloseSelf()
        self.frameTimer = TimerUtility.DelayExecuteInFrame(function()
            self:PlayTimeLine()
        end, 1)
        ModuleRefer.ActivityShopModule.isFirstRechargeTimelinePlayed = true -- 保底，防止网络原因SetData失败或延迟导致的重复播放
    else
        g_Game.SoundManager:Play("sfx_ui_firstcharge_giftbag")
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

function ActivityHeroPackFirstRecharge:OnHide()
    if self.frameTimer then
        TimerUtility.StopAndRecycle(self.frameTimer)
        self.frameTimer = nil
    end
    if self.handler then
        self.createHelper:Delete(self.handler)
        self.handler = nil
    end
    if self.gestureBlocker then
        self.gestureBlocker:UnRef()
        self.gestureBlocker = nil
    end
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

---@override
function ActivityHeroPackFirstRecharge:PostOnCreate()
    self.root = self:GameObject("p_root") or self:GameObject("")
    self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseBtnClick))
    self.imgBase = self:Image("base_activity")
    self.imgBase.gameObject:SetActive(false)
    self.imgHero = self:Image("p_img_hero")
    self.imgHero.gameObject:SetActive(false)

    self.goTimer = self:GameObject("p_base_tips_count")
    self.textTimer = self:Text("p_text_count")
end

function ActivityHeroPackFirstRecharge:PostInitGotoDetailParam()
    self.gotoDetailParam.customReplay = function ()
        self:GetParentBaseUIMediator():CloseSelf()
        self:PlayTimeLine()
    end
    self.gotoDetailParam.displayMask = self.gotoDetailParam.displayMask | CommonGotoDetailDefine.DISPLAY_MASK.BTN_REPLAY
end

function ActivityHeroPackFirstRecharge:PostInitGroupInfoParam()
    self.groupInfoParam.showDiscountTag = false
end

function ActivityHeroPackFirstRecharge:PostOnFeedData(param)
    self.shouldOffset = param.shouldOffset
    self.imgBase.gameObject:SetActive(self.isShop)
    self.btnClose.gameObject:SetActive(not self.isShop)
    self:OnSecTick()
end

function ActivityHeroPackFirstRecharge:OnCloseBtnClick()
    self:GetParentBaseUIMediator():CloseSelf()
end

function ActivityHeroPackFirstRecharge:PlayTimeLine()
    local heroCfg = ConfigRefer.Heroes:Find(self:GetRelatedRewardCfgId())
    if not heroCfg then return end
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    local parent = KingdomMapUtils.GetMapSystem().Parent
    self.handler = self.createHelper:Create(resCell:ShowTimeline(), parent, function(go)
        if not self.gestureBlocker then
            self.gestureBlocker = g_Game.GestureManager:SetBlockAddRef()
        end
        if go then
            local succ, _ = pcall(self.PlayTimeLineImpl, self, go)
            if not succ then
                self:RecoverMediatorAndHUD()
            end
        else
            self:RecoverMediatorAndHUD()
        end
    end)
end

function ActivityHeroPackFirstRecharge:PlayTimeLineImpl(go)
    self.timelineGo = go
    self.timelineGo.transform.position = CS.UnityEngine.Vector3.zero
    go:SetActive(false)
    self.timelineDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.timelineWrapper = self.timelineDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
    self.timelineWrapper.targetDirector = self.timelineDirector
	self:ShowTimeline()
    local camera = go:GetComponentInChildren(typeof(CS.UnityEngine.Camera), true)
    camera.enabled = true

    local behaviourManager = BehaviourManager.Instance()
    self.plotDirector = self.timelineGo:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector), true)
    self.plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
    self.plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
    self.plotDirector.OnBehaviourPause = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourPause)
    self.plotDirector.OnBehaviourResume = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourResume)
    self.plotDirector.OnBehaviourTick = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourTick)
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, false)
end

function ActivityHeroPackFirstRecharge:OnSecTick()
    if not self.tick or Utils.IsNull(self.goTimer) then return end
    local progress = ModuleRefer.ActivityShopModule:GetFirstRechargeBubbleProgress()
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = math.clamp(progress.endTime - now, 0, math.huge)
    if remainTime > 0 then
        self.goTimer:SetActive(true)
        self.textTimer.text = I18N.GetWithParams("city_area_task15", TimeFormatter.SimpleFormatTime(remainTime))
    else
        self.goTimer:SetActive(false)
        self.tick = false
    end
end

function ActivityHeroPackFirstRecharge:ShowTimeline()
    self.timelineWrapper.stoppedCallback = Delegate.GetOrCreate(self, self.OnTimelineComplete)
    self.timelineWrapper:AddStoppedListener()
    self.timelineGo:SetActive(true)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.everyThing, false)
    ModuleRefer.UIAsyncModule:AddGlobalBlock()
end

function ActivityHeroPackFirstRecharge:OnTimelineComplete()
    BehaviourManager.Instance():CleanUp()
    self.timelineWrapper.stoppedCallback = nil
	self.timelineWrapper:RemoveStoppedListener()
    self.timelineGo:SetActive(false)
    self.createHelper:Delete(self.handler)
    self.handler = nil
    if self.gestureBlocker then
        self.gestureBlocker:UnRef()
        self.gestureBlocker = nil
    end
    self:RecoverMediatorAndHUD()
end

function ActivityHeroPackFirstRecharge:RecoverMediatorAndHUD()
    ---@type FirstRechargePopUpMediatorParam
    local data = {}
    data.isFromHud = true
    data.popIds = {self.popId}
    g_Game.UIManager:Open(UIMediatorNames.FirstRechargePopUpMediator, data)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.everyThing ~ HUDMediatorPartDefine.bossInfo, true)
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, true)
    ModuleRefer.UIAsyncModule:RemoveGlobalBlock()
end

return ActivityHeroPackFirstRecharge