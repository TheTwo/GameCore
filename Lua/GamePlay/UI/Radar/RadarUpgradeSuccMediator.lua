local BaseUIMediator = require('BaseUIMediator')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local EventConst = require('EventConst')

local RadarUpgradeSuccMediator = class('RadarUpgradeSuccMediator', BaseUIMediator)

function RadarUpgradeSuccMediator:OnCreate()
    self.textSucceed = self:Text('p_text_succeed', I18N.Get("leida_shengji"))
    self.textSucceedNum = self:Text('p_text_succeed_num')
    self.goMax = self:GameObject('p_group_succeed_max')
    self.textHint = self:Text('p_text_hint')
    self.luagoGroup = self:LuaObject('group_tips')

    self.p_text_succeed_num_1 = self:Text('p_text_succeed_num_1', "MAX")
    self.p_btn_close = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnClick))
end

function RadarUpgradeSuccMediator:OnOpened()
    self.curLevel = ModuleRefer.RadarModule:GetRadarLv()
    self.textSucceedNum.text = "Lv." .. self.curLevel
    local isMax = ModuleRefer.RadarModule:CheckIsMax()
    self.goMax:SetActive(isMax)

    ---@type RadarPopupUpgradeCompParam
    local param = {}
    param.curlevel = self.curLevel - 1
    param.type = 2
    param.levelTitleText = I18N.Get("leida_shengji")
    self.luagoGroup:FeedData(param)

    local countdown = 2
    self.canClose = false
    self.textHint = self:Text('p_text_hint', I18N.GetWithParams("bw_tips_newcircle_1", countdown))
    self.timer = TimerUtility.IntervalRepeat(function()
        countdown = countdown - 1
        if countdown <= 0 then
            self.canClose = true
            self.textHint = self:Text('p_text_hint', I18N.Get("leida_tishi3"))
            self:ClearTimer()
        else
            self.textHint = self:Text('p_text_hint', I18N.GetWithParams("bw_tips_newcircle_1", countdown))
        end
    end, 1, -1)
end

function RadarUpgradeSuccMediator:ClearTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function RadarUpgradeSuccMediator:OnBtnClick()
    if not self.canClose then
        return
    end

    --雷达升级关闭后 解锁 任务刷新
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_UPGRADE_PANEL_CLOSE)
    self:CloseSelf()
end

function RadarUpgradeSuccMediator:OnClose()
    self:ClearTimer()
    if self.curLevel == 2 then
        ModuleRefer.GuideModule:CallGuide(52)
    end
end

return RadarUpgradeSuccMediator
