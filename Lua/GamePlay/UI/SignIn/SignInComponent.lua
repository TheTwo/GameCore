local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local TimeFormatter = require('TimeFormatter')
local SignInComponent = class('SignInComponent', BaseUIComponent)

function SignInComponent:ctor()
    self.tick = false
end

function SignInComponent:OnCreate()
    self.textSign = self:Text('p_text_sign', I18N.Get("activity_signin_title"))

    self.textContent = self:Text('p_text_content', I18N.Get("activity_signin_desc"))
    self.compSign = self:LuaObject('child_comp_btn_b') or self:LuaObject('p_btn_sign')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.vxTrigger = self:AnimTrigger('vx_trigger')
    self.textTimer = self:Text('p_text_hint')

    ---@see SignInGroup
    self.luaGroupItem7 = self:LuaObject('p_group_item_7')
    self.luaGroupItem8 = self:LuaObject('p_group_item_8')

    self.goImgSeven = self:GameObject('p_img_seven')
    self.goImgEight = self:GameObject('p_img_eight')

    self.firstOpen = true
end

function SignInComponent:OnShow(param)
    if self.firstOpen then
        self.firstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,Delegate.GetOrCreate(self,self.RefreshInfo))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function SignInComponent:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,Delegate.GetOrCreate(self,self.RefreshInfo))
end

function SignInComponent:OnFeedData(param)
    self.btnClose.gameObject:SetActive(param and param.isShowClose)
    self.compSign:FeedData({
        onClick = Delegate.GetOrCreate(self, self.OnSignInClick),
        buttonText = I18N.Get("activity_signin_btn_active"),
        disableButtonText = I18N.Get("activity_signin_btn_active"),
    })
    self:RefreshInfo()
end

function SignInComponent:RefreshInfo()
    self.rewardId = ConfigRefer.ActivityCenterTabs:Find(3):RefActivityReward()
    local singInInfo = self:GetPlayerRewardInfo()
    local cfgId = singInInfo.SevenDaySignInTid
    local cfg = ConfigRefer.SevenDaySignIn:Find(cfgId)
    if not cfg then
        return
    end
    self.singInIndex = -1
    local data = {}
    for i = 1, cfg:DayInfosLength() do
        local index = i - 1
        local single = {}
        single.isArrived = singInInfo.DayIndex >= index
        single.isCanGet = table.ContainsValue(singInInfo.CanReceiveRewardDays, index)
        single.isGot =  single.isArrived and not single.isCanGet
        single.itemGroupId = cfg:DayInfos(i):Reward()
        single.dayIndex = i
        single.rewardId = self.rewardId
        if single.isCanGet and self.singInIndex < 0 then
            self.singInIndex = index
        end
        table.insert(data, single)
    end

    if #data == 7 then
        self.luaGroupItem7:FeedData(data)
        self.luaGroupItem7:SetVisible(true)
        self.luaGroupItem8:SetVisible(false)
        self.goImgSeven:SetActive(true)
        self.goImgEight:SetActive(false)
    else
        self.luaGroupItem8:FeedData(data)
        self.luaGroupItem8:SetVisible(true)
        self.luaGroupItem7:SetVisible(false)
        self.goImgSeven:SetActive(false)
        self.goImgEight:SetActive(true)
    end

    self.textTimer.gameObject:SetActive(self.singInIndex < 0)
    self.compSign:SetEnabled(self.singInIndex >= 0)
    self.tick = self.singInIndex < 0
    self:Tick()
end

function SignInComponent:GetPlayerRewardInfo()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper2.PlayerAutoReward.Rewards[self.rewardId].SevenDaySignInParam
end

function SignInComponent:OnBtnDetailClicked(args)
    local toastParameter = {}
    toastParameter.clickTransform = self.btnDetail.transform
    toastParameter.content = I18N.Get("activity_signin_txt")
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

function SignInComponent:OnBtnCloseClicked(args)
    local parentMediator = self:GetParentBaseUIMediator()
    g_Game.UIManager:Close(parentMediator.runtimeId)
end

function SignInComponent:OnSignInClick()
    local param = PlayerGetAutoRewardParameter.new()
    param.args.Op.ConfigId = self.rewardId
    param:SendWithFullScreenLock()
end

function SignInComponent:Tick()
    if not self.tick then
        return
    end
    local time = TimeFormatter.GetSecUntilNextDay()
    if time <= 0 then
        self.tick = false
        self:RefreshInfo()
        return
    end
    self.textTimer.text = I18N.GetWithParams("sign_in_time_tips", TimeFormatter.SimpleFormatTime(time))
end


return SignInComponent
