local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local AudioConsts = require('AudioConsts')
local ConfigRefer = require("ConfigRefer")
local FpAnimTriggerEvent = require("FpAnimTriggerEvent")
local RANGE_MIDDLE_MIN = 0.4
local RANGE_MIDDLE_MAX = 0.6
local HeroCardFeedCell = class('HeroCardFeedCell',BaseTableViewProCell)

function HeroCardFeedCell:OnCreate(param)
    self.goRoot = self:GameObject("")
    self.imgIconItem = self:Image('p_icon_item')
    self.goIconItem = self:GameObject('p_icon_item')
    self:DragEvent("p_btn_cellClick",
    Delegate.GetOrCreate(self, self.OnCaptureDragStart),
    Delegate.GetOrCreate(self, self.OnCaptureDrag),
    Delegate.GetOrCreate(self, self.OnCaptureDragEnd),
        false)
    self:DragCancelEvent("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnCaptureDragCancel))
    self.goRoot:SetActive(true)
    g_Game.EventManager:AddListener(EventConst.HERO_CARD_FEED_DRAG_HIDE, Delegate.GetOrCreate(self, self.OnCaptureDragHide))
end

function HeroCardFeedCell:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.HERO_CARD_FEED_DRAG_HIDE, Delegate.GetOrCreate(self, self.OnCaptureDragHide))
end

function HeroCardFeedCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIconItem)
    self.index = data.index
    self.isOne = data.isOne
end

function HeroCardFeedCell:OnCaptureDragHide(index)
    self.goRoot:SetActive(index == self.index)
end

function HeroCardFeedCell:OnCaptureDragCancel(go, eventData)

end

function HeroCardFeedCell:UpdateUsingItemPos(screenPos)
    self.goRoot.transform.position = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x, screenPos.y, 0))
end

function HeroCardFeedCell:OnCaptureDragStart(go, eventData)
	self:UpdateUsingItemPos(eventData.position)
    self:GetParentBaseUIMediator():PlayHide()
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_FEED_DRAG_HIDE, self.index)
end

function HeroCardFeedCell:OnCaptureDrag(go, eventData)
	self:UpdateUsingItemPos(eventData.position)
end

function HeroCardFeedCell:OnCaptureDragEnd(go, eventData)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_lottery_start1_01)
    local throwPos = eventData.position.x / CS.UnityEngine.Screen.width
    local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
    local u3dModel = cardMediator.ui3dModel
    if u3dModel then
        if throwPos < RANGE_MIDDLE_MIN then
            u3dModel:SetupVfx("vfx_chouka_touzhi", 1, {localRot = CS.UnityEngine.Vector3(359.2355, 351, 357.0366)})
        elseif throwPos > RANGE_MIDDLE_MAX then
            u3dModel:SetupVfx("vfx_chouka_touzhi", 1, {localRot = CS.UnityEngine.Vector3(359.2355, 344.8571, 357.0366)})
        else
            u3dModel:SetupVfx("vfx_chouka_touzhi", 1, {localRot = CS.UnityEngine.Vector3(359.2355, 347.5, 357.0366)})
        end
        u3dModel:PlayVfxByIndex(1)
        TimerUtility.DelayExecute(function()
            u3dModel:SetupVfx("vfx_chouka_loop", 2, {})
            u3dModel:SetupVfx("vfx_chouka_start", 3, {})
            u3dModel:PlayVfxByIndex(2)
            u3dModel:PlayVfxByIndex(3)
        end, 0.4)

        u3dModel:ChangeCinemachineBlend(0.2)
        u3dModel:InitVirtualCameraSetting({{localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraMove(4), ConfigRefer.ConstMain:GachaCameraMove(5), ConfigRefer.ConstMain:GachaCameraMove(6)),
            rotation = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraRot(4) - 6, ConfigRefer.ConstMain:GachaCameraRot(5), ConfigRefer.ConstMain:GachaCameraRot(6))}})
        u3dModel:EnableVirtualCamera(1)
        TimerUtility.DelayExecute(function()
            if u3dModel then
                u3dModel:EnableVirtualCamera(2)
            end
        end, 0.2)
    end
    self.goIconItem:SetActive(false)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_FEED_DRAG_END, self.isOne)
    TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.OnAnimationEnd), 3)
    local feedMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardFeedMediator)
    if feedMediator then
        g_Game.UIManager:Close(feedMediator.runtimeId)
    end
end

function HeroCardFeedCell:OnAnimationEnd()
    ModuleRefer.HeroCardModule:PlayGachaResults()
    local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
    local u3dModel = cardMediator.ui3dModel
    if u3dModel then
        u3dModel:HideVfx()
    end
end

return HeroCardFeedCell
