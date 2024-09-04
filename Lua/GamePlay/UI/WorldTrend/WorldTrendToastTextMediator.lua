local BaseUIMediator = require ('BaseUIMediator')
local TimerUtility = require("TimerUtility")
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Vector3 = CS.UnityEngine.Vector3
local I18N = require('I18N')
local Utils = require("Utils")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require('UIMediatorNames')

local WorldTrendToastTextMediator = class('WorldTrendToastTextMediator', BaseUIMediator)

function WorldTrendToastTextMediator:ctor()
    BaseUIMediator.ctor(self)
    self._inLateTickLimitInScreen = false
end

function WorldTrendToastTextMediator:OnCreate()
    self.p_text_detail = self:Text('p_text_detail')
    self.p_toast_text = self:GameObject('p_toast_text')
    self.p_btn_show = self:Button('p_btn_show', Delegate.GetOrCreate(self, self.OnClickButton))
    self.transform = self:Transform("")
end

function WorldTrendToastTextMediator:OnShow()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function WorldTrendToastTextMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function WorldTrendToastTextMediator:OnOpened(param)
    self.param = param
    self.p_text_detail.text = I18N.Get(param.tips)
    self.p_toast_text.transform.position = param.pos
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.p_toast_text.transform)
    self._needLateTick = true
end

function WorldTrendToastTextMediator:OnClickButton()
    local video = self.param.video
    local data = {}
    local demoCfg = ConfigRefer.GuideDemo:Find(video)
    local demo = {
        imageId = demoCfg:Pic(),
        videoId = demoCfg:Video(),
        title = demoCfg:Title(),
        desc = demoCfg:Desc(),
    }
    table.insert(data, demo)
    g_Game.UIManager:Open(UIMediatorNames.GuideDemoUIMediator, {data = data})
    g_Game.UIManager:CloseByName(UIMediatorNames.WorldTrendToastTextMediator)
end

function WorldTrendToastTextMediator:LateTick()
    if not self._needLateTick then
        return
    end

    self.p_toast_text.transform.position = self.param.pos
    self._needLateTick = false
end

return WorldTrendToastTextMediator