local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")
local CommonDropDown = require('CommonDropDown')
local NotificationType = require('NotificationType')
local TimeFormatter = require('TimeFormatter')
local Utils = require("Utils")
local UI3DViewConst = require("UI3DViewConst")
local NpcServiceObjectType = require('NpcServiceObjectType')
local NpcServiceType = require('NpcServiceType')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local RequestNpcServiceInfoParameter = require('RequestNpcServiceInfoParameter')
local ManualResourceConst = require('ManualResourceConst')
local KingdomMapUtils = require("KingdomMapUtils")
local idleAnims = {"state01_idle", "state02_idle", "state03_idle", "state04_idle", "state05_idle", "state06_idle"}
local freeAnims = {"state01_free", "state02_free", "state03_free", "state04_free", "state05_free"}
local vfxAttachments = {"vfx01", "vfx02", "vfx03", "vfx04", "vfx05"}

---@class UIPetMediator : BaseUIMediator
local HeroRescueMediator = class('HeroRescueMediator', BaseUIMediator)
function HeroRescueMediator:ctor()
    self._rewardList = {}
end

function HeroRescueMediator:OnCreate()
    self.p_text_hint_find = self:Text('p_text_hint_find', "new_activity_egirl4")
    self.p_btn_find = self:Button('p_btn_find', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_text_find = self:Text('p_text_find', "goto")
    self.p_btn_clear = self:Button('p_btn_clear', Delegate.GetOrCreate(self, self.OnClickUseItem))
    self.p_text = self:Text('p_text', "new_activity_egirl5")

    ---@type CommonPairsQuantity
    self.child_common_quantity = self:LuaObject('child_common_quantity')

    -- 倒计时
    self.p_text_count_down_1 = self:Text('p_text_count_down_1')
    self.p_text_count_down_2 = self:Text('p_text_count_down_2')
    self.p_text_count_down_3 = self:Text('p_text_count_down_3')

    -- 角色文本气泡
    self.p_text_content_2 = self:Text('p_text_content_2')

    self.p_group_find = self:GameObject('p_group_find')
    self.p_group_clear = self:GameObject('p_group_clear')
    self.group_time = self:GameObject('group_time')
    self.p_bubble = self:GameObject('p_bubble')

    self.p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))
    self:PreloadUI3DView()
end

function HeroRescueMediator:PreloadUI3DView()
    self:SetAsyncLoadFlag()
    local cameraSettings = self:Get3DCameraSettings()
    g_Game.UIManager.ui3DViewManager:InitCameraTransform(cameraSettings[1])
    -- 展示模型
    self:Show3DModel(function(viewer)
        self:RemoveAsyncLoadFlag()
    end)
    if self.ui3dModel then
        self.ui3dModel:EnableVirtualCamera(1)
    end
end

function HeroRescueMediator:OnOpened(param)
    KingdomMapUtils.SetGlobalCityMapParamsId(false)
    g_Game.EventManager:AddListener(EventConst.UI_HERO_RESCUE_SHOW_HIDE_BUBBLE, Delegate.GetOrCreate(self, self.ShowHideBubble))

    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then
        return
    end
    ---@type KingdomSceneStateInCity
    local sceneState = scene.stateMachine:GetCurrentState()
    if not sceneState or not sceneState.HideMarkerHUD then
        return
    end
    sceneState:HideMarkerHUD()
    g_Game.EventManager:TriggerEvent(EventConst.UI_HERO_RESCUE_SHOW, false)

    self.timer = {}
    self.isPlayAnim = false
    ModuleRefer.HeroRescueModule:SetCountdown(self.cfgId)

    -- 倒计时
    self:SetCountDown()
    self:SetCountDownTimer()

    -- 播放随机对话
    self:GenerateRandomDialogue()

    -- 剩余需要使用的道具数量
    self:RefreshItems()
end

function HeroRescueMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_HERO_RESCUE_SHOW_HIDE_BUBBLE, Delegate.GetOrCreate(self, self.ShowHideBubble))
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    KingdomMapUtils.SetGlobalCityMapParamsId(KingdomMapUtils.IsMapState())
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if scene then
        ---@type KingdomSceneStateInCity
        local sceneState = scene.stateMachine:GetCurrentState()
        if sceneState and sceneState.ShowMarkerHUD then
            sceneState:ShowMarkerHUD()
        end
    end
    self.ui3dModel = nil
    g_Game.EventManager:TriggerEvent(EventConst.HERO_RESCUE)
    g_Game.EventManager:TriggerEvent(EventConst.UI_HERO_RESCUE_SHOW, true)

    self:StopTimer()
    self:ClearVfx()
end

function HeroRescueMediator:OnShow(param)

end

function HeroRescueMediator:OnHide(param)
end

function HeroRescueMediator:RefreshItems()
    local index = 1
    local cureItemGroup = ConfigRefer.ItemGroup:Find(self.cfg:CureItemGroup())
    local itemId = cureItemGroup:ItemGroupInfoList(index):Items()
    local has = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)

    -- 已经使用的道具数量
    self.serviceGroup = ModuleRefer.HeroRescueModule:GetHeroRescueServiceGroup()
    if self.serviceGroup == nil then
        self.animIndex = 6
        self.p_group_clear:SetVisible(false)
        self.p_group_find:SetVisible(false)

        -- 完成,展示奖励，2s后关闭界面
        -- self.closeTimer = TimerUtility.DelayExecute(function()
        --     self:CloseSelf()
        -- end, 2)
        return
    end
    local used = self.serviceGroup.Services[self.serviceGroup.ServiceGroupTid].ItemCount[itemId] and self.serviceGroup.Services[self.serviceGroup.ServiceGroupTid].ItemCount[itemId] or 0

    self.itemId = itemId
    self.itemNum = has
    local total = cureItemGroup:ItemGroupInfoList(index):Nums()
    local remain = total - used
    self.p_group_find:SetVisible(has <= 0)
    self.p_group_clear:SetVisible(has > 0)

    if remain == 0 then
        self.p_btn_clear:SetVisible(false)
    else
        self.p_btn_clear:SetVisible(true)
    end

    -- 动画计数
    self.animIndex = used + 1

    ---@type CommonPairsQuantityParameter
    local quantityParam = {compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST, itemId = itemId, num1 = has, num2 = 1}
    self.child_common_quantity:FeedData(quantityParam)
end

function HeroRescueMediator:GenerateRandomDialogue()
    local pool = {}
    for i = 1, self.cfg:RandomDialogueLength() do
        table.insert(pool, self.cfg:RandomDialogue(i))
    end
    self.randomDialogues = self:Shuffle(pool)
    self.randomDialogueIndex = 1
    self:PlayRandomDialgoue()

    self.randomDialogueTimer = TimerUtility.IntervalRepeat(function()
        self:PlayRandomDialgoue()
    end, 3, -1)
end

function HeroRescueMediator:Shuffle(dialogues)
    local res = {}
    local index = 1
    while #dialogues ~= 0 do
        local n = math.random(1, #dialogues)
        if dialogues[n] ~= nil then
            res[index] = dialogues[n]
            table.remove(dialogues, n)
            index = index + 1
        end
    end
    return res
end

function HeroRescueMediator:PlayRandomDialgoue()
    self.p_text_content_2.text = I18N.Get(self.randomDialogues[self.randomDialogueIndex])
    self.randomDialogueIndex = self.randomDialogueIndex + 1
    if self.randomDialogueIndex > #self.randomDialogues then
        self.randomDialogueIndex = 1
    end
end

function HeroRescueMediator:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function HeroRescueMediator:SetCountDown()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local endT = ModuleRefer.HeroRescueModule:GetCountdownEndTime(self.cfgId)
    local seconds = endT - curTime
    if seconds < 0 then
        self.group_time:SetVisible(false)
        self:StopCountdownTimer()
        return
    else
        self.group_time:SetVisible(true)
        -- self.p_text_count_down_1.text = TimeFormatter.SimpleFormatTimeWithoutZero(endT - curTime)

        local h, m, s = self:GetCountDown(seconds)
        self.p_text_count_down_1.text = string.format("%02d", h)
        self.p_text_count_down_2.text = string.format("%02d", m)
        self.p_text_count_down_3.text = string.format("%02d", s)
    end
end

function HeroRescueMediator:GetCountDown(seconds)
    local int = math.floor(seconds);
    int = int > 0 and int or 0
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return h, m, s
end

function HeroRescueMediator:StopCountdownTimer()
    if self.countdownTimer then
        TimerUtility.StopAndRecycle(self.countdownTimer)
        self.countdownTimer = nil
    end
end
function HeroRescueMediator:StopTimer()
    -- if self.closeTimer then
    --     TimerUtility.StopAndRecycle(self.closeTimer)
    --     self.closeTimer = nil
    -- end

    if self.useItemTimer then
        TimerUtility.StopAndRecycle(self.useItemTimer)
        self.useItemTimer = nil
    end
    if self.playAnimTimer then
        TimerUtility.StopAndRecycle(self.playAnimTimer)
        self.playAnimTimer = nil
    end

    self:StopCountdownTimer()
    if self.randomDialogueTimer then
        TimerUtility.StopAndRecycle(self.randomDialogueTimer)
        self.randomDialogueTimer = nil
    end

    for i = 1, #self.timer do
        TimerUtility.StopAndRecycle(self.timer[i])
    end
    self.timer = {}
end

function HeroRescueMediator:OnClickDetails()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform = self.p_btn_detail.transform
    toastParameter.content = I18N.Get("new_activity_egirl10")
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function HeroRescueMediator:OnClickGoto()
    if self.isPlayAnim then
        return
    end

    local isFirstOpen = ModuleRefer.HeroRescueModule:GetFirstOpen()
    if isFirstOpen == 0 then
        self:CloseSelf()
        ModuleRefer.HeroRescueModule:SetFirstOpen()
        ModuleRefer.HeroRescueModule:DisplayItems()
        return
    end

    if ModuleRefer.CityModule.myCity:IsInSingleSeExplorerMode() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("new_activity_egirl11"))
        return
    end

    if self.cfg:ZoneLength() < self.animIndex then
        g_Logger.Error("animIndex = " .. self.animIndex .. " self.cfg:ZoneLength() = " .. self.cfg:ZoneLength())
        return
    end

    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        ModuleRefer.HeroRescueModule:GotoItemZone(self.animIndex)
        self:CloseSelf()
    else
        scene:ReturnMyCity(function()
            TimerUtility.DelayExecute(function()
                ModuleRefer.HeroRescueModule:GotoItemZone(self.animIndex)
                self:CloseSelf()
            end, 0.2)
        end)
    end

end

function HeroRescueMediator:OnClickUseItem()
    if self.itemNum < 1 then
        return
    end

    if not self.ui3dModel or self.isPlayAnim then
        return
    end

    if self.serviceGroup == nil then
        return
    end
    self:PlayVfx(self.animIndex)

    if self.useItemTimer then
        TimerUtility.StopAndRecycle(self.useItemTimer)
        self.useItemTimer = nil
    end

    self.useItemTimer = TimerUtility.DelayExecute(function()
        self:PlayAnim(true)
        TimerUtility.DelayExecute(function()
            ModuleRefer.PlayerServiceModule:RequestNpcService(nil, NpcServiceObjectType.CityElement, self.serviceGroup.ObjectId, self.serviceGroup.ServiceGroupTid, {[self.itemId] = 1},
                                                              function(cmd, success, rsp)
                if success then
                    self:RefreshItems()
                end
            end)
        end, 1)
    end, 1)
end

--- 展示3D模型
function HeroRescueMediator:Show3DModel(callback)
    self.cfgId = 1 -- 现在只有一个美女要拯救
    self.cfg = ConfigRefer.HeroRescue:Find(self.cfgId)
    local artConf = ConfigRefer.ArtResource:Find(self.cfg:ShowModel())
    g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(), artConf:Path(), ConfigRefer.ArtResource:Find(self.cfg:ShowBackground()):Path(), nil, function(viewer)
        if not viewer then
            return
        end
        self.ui3dModel = viewer
        local scale = artConf:ModelScale()
        if (not scale or scale <= 0) then
            scale = 1
        end
        self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3.one * scale)
        self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3.zero)
        self.ui3dModel:InitVirtualCameraSetting(self:Get3DCameraSettings())
        self.ui3dModel:SetModelAngles(CS.UnityEngine.Vector3.zero)
        -- self.ui3dModel:SetModelAngles(CS.UnityEngine.Vector3(artConf:ModelRotation(1), artConf:ModelRotation(2), artConf:ModelRotation(3)))
        -- self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(artConf:ModelPosition(1), artConf:ModelPosition(2), artConf:ModelPosition(3)))
        self.ui3dModel:RefreshEnv()

        if callback then
            callback()
        end
        self:PlayAnim()
    end)
end

--- 获取3D相机参数
function HeroRescueMediator:Get3DCameraSettings()
    local cameraSetting = {}
    -- for i = 1, 2 do
    local setting = {}
    setting.fov = ConfigRefer.ConstMain:RescueBeautyCameraFOV()
    setting.nearCp = ConfigRefer.ConstMain:RescueBeautyCameraNearClip()
    setting.farCp = ConfigRefer.ConstMain:RescueBeautyCameraFarClip()
    setting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:RescueBeautyCameraPosition(1), ConfigRefer.ConstMain:RescueBeautyCameraPosition(2),
                                              ConfigRefer.ConstMain:RescueBeautyCameraPosition(3))
    setting.rotation = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:RescueBeautyCameraRotation(1), ConfigRefer.ConstMain:RescueBeautyCameraRotation(2),
                                              ConfigRefer.ConstMain:RescueBeautyCameraRotation(3))
    cameraSetting[1] = setting
    -- end
    return cameraSetting
end

function HeroRescueMediator:PlayVfx(index)
    self.isPlayAnim = true
    self:ClearVfx()
    self.useItemVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local effectName = ManualResourceConst.vfx_w_savation_pen
    self.useItemVfx:Create(effectName, effectName, nil, function(success, obj, handle)
        if success then
            local go = handle.Effect.gameObject
            local obj = self.ui3dModel.curModelGo.transform:Find(vfxAttachments[index])
            go.transform.position = obj.transform.position
        end
    end)
end

function HeroRescueMediator:ClearVfx()
    if self.useItemVfx then
        self.useItemVfx:Delete()
        self.useItemVfx = nil
    end
end

function HeroRescueMediator:PlayAnim(isFree)
    if self.ui3dModel == nil then
        return
    end

    if self.playAnimTimer then
        TimerUtility.StopAndRecycle(self.playAnimTimer)
        self.playAnimTimer = nil
    end

    ---@type CS.UnityEngine.Animator
    local animator = self.ui3dModel.curModelGo:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
    local animIndex
    if isFree then
        animIndex = math.min(self.animIndex, 5)
        animator:Play(freeAnims[animIndex])
    else
        animIndex = math.min(self.animIndex, 6)
        animator:Play(idleAnims[self.animIndex])
    end
    self.playAnimTimer = TimerUtility.DelayExecute(function()
        self.isPlayAnim = false
    end, 1.5)
end

function HeroRescueMediator:ShowHideBubble(isShow)
    self.p_bubble:SetVisible(isShow)
    if isShow then
        self:CloseSelf()
    end
end

return HeroRescueMediator
