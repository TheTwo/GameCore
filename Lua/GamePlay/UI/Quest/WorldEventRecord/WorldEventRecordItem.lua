local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ProgressType = require('ProgressType')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")

---@class WorldEventRecordItemParam
---@field expeditionInfo wds.PlayerExpeditionInfo
---@field isOverEvent boolean

---@class WorldEventRecordItem : BaseTableViewProCell
local WorldEventRecordItem = class('WorldEventRecordItem', BaseTableViewProCell)

local QUALITY_COLOR =
{
    "sp_world_base_1",
    "sp_world_base_2",
    "sp_world_base_3",
    "sp_world_base_4",
}

function WorldEventRecordItem:OnCreate()
    self.goGotoBtn = self:GameObject('p_position')
    self.btnGoto = self:Button('p_btn_position', Delegate.GetOrCreate(self, self.OnGoBtnClick))

    self.imgFrame = self:Image('p_img_frame')
    self.imgWorldTaskIcon = self:Image('p_event_icon')

    self.textContent = self:Text('p_text_content')
    self.textLv = self:Text('p_text_lv')
    self.btnDetails = self:Button('p_btn_story', Delegate.GetOrCreate(self, self.OnDetailsBtnClick))
    self.sliderProgress = self:BindComponent("p_progress", typeof(CS.UnityEngine.UI.Slider))
    self.textProgress = self:Text('p_text_progress')
    self.textPersonalProgress = self:Text('p_text_progress_player')
    self.textWorldEventEnded = self:Text('p_text_status', I18N.Get("Worldexpedition_event_over"))
    self.timeComp = self:LuaBaseComponent('child_time')
    self.goTime = self:GameObject('p_time')
    self.goFinish = self:GameObject('p_finish')
    self.itemStatusRecord = self:StatusRecordParent('p_item')
    self.compAlphaCanvasGroup = self:BindComponent('p_alpha', typeof(CS.UnityEngine.CanvasGroup))
    self.compIconCanvasGroup = self:BindComponent('p_icon', typeof(CS.UnityEngine.CanvasGroup))

    self.trigger = self:AnimTrigger('vx_trigger_item')
end

function WorldEventRecordItem:OnShow()
    self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.OnShow)
    self:RegisterEvent()
end

function WorldEventRecordItem:OnHide()
    self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.OnClose)
    self:UnregisterEvent()
end

---@param param WorldEventRecordItemParam
function WorldEventRecordItem:OnFeedData(param)
    if not param.expeditionInfo then
        return
    end
    self.expeditionInfo = param.expeditionInfo
    self.isOverEvent = param.isOverEvent
    self.Id = self.expeditionInfo.ExpeditionInstanceTid
    self.Position = self.expeditionInfo.BuildingPos

    self:RefreshRecordItem()
end

function WorldEventRecordItem:RefreshRecordItem()

    self.eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.Id)

    if self.eventCfg:WorldTaskIcon() then
        g_Game.SpriteManager:LoadSprite(self.eventCfg:WorldTaskIcon(), self.imgWorldTaskIcon)
    end
    g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.expeditionInfo.Quality + 1], self.imgFrame)
    self.textContent.text = I18N.Get(self.eventCfg:Name())
    self.textLv.text = self.eventCfg:Level()

    local finishTime = self.expeditionInfo.EndTime.timeSeconds
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.progress = 0
    local percent = 0
    if self.eventCfg:ProgressType() == ProgressType.Whole then
        local personalPercent = math.clamp(self.expeditionInfo.PersonalProgress / self.eventCfg:MaxProgress(), 0, 1)
        self.progress = self.expeditionInfo.Progress
        percent = math.clamp(self.progress / self.eventCfg:MaxProgress(), 0, 1)
        self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
        self.textProgress.text = string.format('%s<b>%d</b>',I18N.Get("Worldexpedition_my_progress"), self.expeditionInfo.PersonalProgress)
    elseif self.eventCfg:ProgressType() == ProgressType.Personal then
        self.progress = self.expeditionInfo.PersonalProgress
        percent = math.clamp(self.progress / self.eventCfg:MaxProgress(), 0, 1)
        self.textPersonalProgress.text = math.floor(percent * 100) .. "%"
    end
    self.sliderProgress.value = percent
    local isFinish = percent >= 1
    local isEnded = finishTime <= curTime or isFinish or self.isOverEvent
    if isEnded then
        self.textWorldEventEnded.gameObject:SetActive(true)
        self.goTime:SetActive(false)

        if self.itemStatusRecord then
            self.itemStatusRecord:SetState(1)
        end
        if self.compAlphaCanvasGroup then
            self.compAlphaCanvasGroup.alpha = 0.5
            self.compAlphaCanvasGroup.interactable = false
        end
        if self.compIconCanvasGroup then
            self.compIconCanvasGroup.alpha = 0.3
        end
        self.textContent.text = UIHelper.GetColoredText(self.textContent.text, '#828793')
        -- self.textLv.text = UIHelper.GetColoredText(self.textLv.text, '#828793')
        self.textProgress.text = UIHelper.GetColoredText(self.textProgress.text, '#828793')
        -- self.textPersonalProgress.text = UIHelper.GetColoredText(self.textPersonalProgress.text, '#828793')
    else
        if self.itemStatusRecord then
            self.itemStatusRecord:SetState(0)
        end
        if self.compAlphaCanvasGroup then
            self.compAlphaCanvasGroup.alpha = 1
            self.compAlphaCanvasGroup.interactable = true
        end
        if self.compIconCanvasGroup then
            self.compIconCanvasGroup.alpha = 1
        end
        self.textWorldEventEnded.gameObject:SetActive(false)
        self.goTime:SetActive(true)
    end

    if isFinish then
        self.goGotoBtn:SetActive(false)
        self.goFinish:SetActive(true)
    else
        self.goGotoBtn:SetActive(true)
        self.goFinish:SetActive(false)

        if finishTime and finishTime > curTime and not self.isOverEvent then
            local timeUpCallBack = function()
                g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_CHANGEED)
            end
            local color = CS.UnityEngine.Color(1.0, 63/255, 43/255, 1.0)
            self.timeComp:FeedData({endTime = finishTime, needTimer = true, callBack = timeUpCallBack,
             deadline = 600, deadlineColor = color})
        end
    end

end

function WorldEventRecordItem:OnGoBtnClick()
    -- g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    -- local x = self.Position.X * staticMapData.UnitsPerBlockX
    -- local z = self.Position.Z * staticMapData.UnitsPerBlockZ
    local x, z  = KingdomMapUtils.ParseBuildingPos(self.Position)
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x,z, KingdomMapUtils.GetMapSystem())
    KingdomMapUtils.GetBasicCamera():LookAt(pos)
end

function WorldEventRecordItem:OnDetailsBtnClick()
    ---@type WorldEventDetailMediatorParameter
    local param = {}
    param.clickTransform =  self.btnDetails.transform
    param.touchMenuBasicInfoDatum = TouchMenuBasicInfoDatum.new(I18N.Get(self.eventCfg:Name()), "", "",self.eventCfg:Level())
    param.touchMenuCellTextDatum = TouchMenuCellTextDatum.new(I18N.Get(self.eventCfg:Des()), true)
    param.tid = self.Id
    param.x, param.y  = KingdomMapUtils.ParseBuildingPos(self.Position)
    param.progress = self.progress
    if self.expeditionInfo.PersonalProgress then
        param.personalProgress = self.expeditionInfo.PersonalProgress
    end
    param.quality = self.expeditionInfo.Quality
    param.openType = 2
    self._infoToastUI = ModuleRefer.ToastModule:ShowWorldEventDetail(param)
end

function WorldEventRecordItem:RegisterEvent()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.JoinExpeditions.MsgPath, Delegate.GetOrCreate(self, self.OnJoinDataChanged))
end

function WorldEventRecordItem:UnregisterEvent()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.JoinExpeditions.MsgPath, Delegate.GetOrCreate(self, self.OnJoinDataChanged))
end

---@param entity wds.Player
function WorldEventRecordItem:OnJoinDataChanged(entity, changedTable)
    if not changedTable.Add then return end
    if self.isOverEvent then
        return
    end
    if not self.expeditionInfo or self.expeditionInfo.ExpeditionEntityId ~= entity.ID then
        return
    end

    for id, expeditionInfo in pairs(changedTable.Add) do
        if expeditionInfo.ExpeditionInstanceTid == self.Id then
            self.expeditionInfo = expeditionInfo
            self.Id = self.expeditionInfo.ExpeditionInstanceTid
            self.Position = self.expeditionInfo.BuildingPos
            self:RefreshRecordItem()
            return
        end
    end
end

return WorldEventRecordItem