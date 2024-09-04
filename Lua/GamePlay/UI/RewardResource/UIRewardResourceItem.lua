local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local ResourcePopDatum = require('ResourcePopDatum')
local TimerUtility = require('TimerUtility')
local RoomScorePopDatum = require("RoomScorePopDatum")
local Utils = require("Utils")
local NumberFormatter = require("NumberFormatter")

---@class UIRewardResourceItem:BaseUIComponent
local UIRewardResourceItem = class('UIRewardResourceItem', BaseUIComponent)

function UIRewardResourceItem:OnCreate()
    self.transform = self:Transform("")
    
    self._p_content = self:GameObject("p_content")
    self._p_icon = self:Image("p_icon")
    self._p_text_toast = self:Text("p_text_toast")

    self._p_content_room_score = self:GameObject("p_content_room_score")
    self._p_text_score_add = self:Text("p_text_score_add")
    self._p_text_score_reduce = self:Text("p_text_score_reduce")

    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param data UIRewardResourceItemData
function UIRewardResourceItem:OnFeedData(data)
    self.data = data

    self._p_content:SetActive(data.datum:is(ResourcePopDatum))
    self._p_content_room_score:SetActive(data.datum:is(RoomScorePopDatum))

    if data.datum:is(ResourcePopDatum) then
        g_Game.SpriteManager:LoadSprite(data.datum.icon, self._p_icon)
        self._p_text_toast.text = data.datum.text
    elseif data.datum:is(RoomScorePopDatum) then
        self._p_text_score_add:SetVisible(data.datum.score > 0)
        self._p_text_score_reduce:SetVisible(data.datum.score < 0)

        if data.datum.score > 0 then
            self._p_text_score_add.text = NumberFormatter.NumberAbbr(data.datum.score, true, true)
        else
            self._p_text_score_reduce.text = NumberFormatter.NumberAbbr(data.datum.score, true, true)
        end
    end

    self:TryRemoveUpdatePosTick()
    if data.fixedWorldPos then
        self:UpdateForFixedWorldPos()
        self:TryAddUpdatePosTick()
    elseif data.fixedViewportPos then
        self:UpdateForFixedViewportPos()
    end
    
    self._vx_trigger:PlayAll("VX", Delegate.GetOrCreate(self, self.RecycleSelf))
end

function UIRewardResourceItem:RecycleSelf()
    self.data.uiMediator._pool:Recycle(self.CSComponent)
end

function UIRewardResourceItem:OnHide()
    self:TryRemoveUpdatePosTick()
end

function UIRewardResourceItem:OnClose()
    self:TryRemoveUpdatePosTick()
end

function UIRewardResourceItem:UpdateForFixedWorldPos()
    local camera = self.data.uiMediator.city:GetCamera()
    if camera == nil then return end

    local mainCamera = camera.mainCamera
    if Utils.IsNull(mainCamera) then return end

    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local viewport = mainCamera:WorldToViewportPoint(self.data.worldPos)
    viewport.z = 0

    local uiWorldPos = uiCamera:ViewportToWorldPoint(viewport)
    self.transform.position = uiWorldPos
end

function UIRewardResourceItem:UpdateForFixedViewportPos()
    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local uiWorldPos = uiCamera:ViewportToWorldPoint(self.data.viewport)
    self.transform.position = uiWorldPos
end

function UIRewardResourceItem:TryAddUpdatePosTick()
    if self.timer then return end

    self.timer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnFrameTick), 1, -1)
end

function UIRewardResourceItem:TryRemoveUpdatePosTick()
    if not self.timer then return end

    TimerUtility.StopAndRecycle(self.timer)
    self.timer = nil
end

function UIRewardResourceItem:OnFrameTick()
    self:UpdateForFixedWorldPos()
end

return UIRewardResourceItem