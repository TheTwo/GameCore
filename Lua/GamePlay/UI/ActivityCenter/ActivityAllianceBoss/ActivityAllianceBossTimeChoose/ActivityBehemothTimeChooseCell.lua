local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
---@class ActivityBehemothTimeChooseCell : BaseTableViewProCell
local ActivityBehemothTimeChooseCell = class("ActivityBehemothTimeChooseCell", BaseTableViewProCell)

function ActivityBehemothTimeChooseCell:OnCreate()
    self.textTime = self:Text("p_text_name")
    self.btn = self:Button("", Delegate.GetOrCreate(self, self.OnBtnClick))
    self.statusCtrler = self:StatusRecordParent("p_content")
    self.goRoot = self:GameObject("")
end

---@param param ActivityAllianceBossRegisterTimeChooseCellParam
function ActivityBehemothTimeChooseCell:OnFeedData(param)
    self.activityTemplateId = param.activityTemplateId
    self.timeStr = param.timeStr
    self.textTime.text = self.timeStr

    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(self.activityTemplateId)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.isAvaliable = curTime <= endTime.ServerSecond
    UIHelper.SetGray(self.goRoot, not self.isAvaliable)
    if param.select then
        self:SelectSelf()
    end
end

function ActivityBehemothTimeChooseCell:OnBtnClick()
    if not self.isAvaliable then
        return
    end
    self:SelectSelf()
    g_Game.EventManager:TriggerEvent(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, self.activityTemplateId)
end

function ActivityBehemothTimeChooseCell:Select()
    self.statusCtrler:ApplyStatusRecord(1)
end

function ActivityBehemothTimeChooseCell:UnSelect()
    self.statusCtrler:ApplyStatusRecord(0)
end

return ActivityBehemothTimeChooseCell