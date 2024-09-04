local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
---@class ActivityAllianceBossRegisterTimeChooseCell : BaseUIComponent
local ActivityAllianceBossRegisterTimeChooseCell = class('ActivityAllianceBossRegisterTimeChooseCell', BaseUIComponent)

---@class ActivityAllianceBossRegisterTimeChooseCellParam
---@field activityTemplateId number
---@field timeStr string

function ActivityAllianceBossRegisterTimeChooseCell:OnCreate()
    self.button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self.textTime = self:Text("p_text_time")
    self.goRoot = self:GameObject("")
end

---@param param ActivityAllianceBossRegisterTimeChooseCellParam
function ActivityAllianceBossRegisterTimeChooseCell:OnFeedData(param)
    self.activityTemplateId = param.activityTemplateId
    self.timeStr = param.timeStr
    self.textTime.text = self.timeStr

    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(self.activityTemplateId)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.isAvaliable = curTime <= endTime.ServerSecond
    UIHelper.SetGray(self.goRoot, not self.isAvaliable)
end

function ActivityAllianceBossRegisterTimeChooseCell:OnClick()
    if not self.isAvaliable then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_TIME_SELCET, self.activityTemplateId)
end

return ActivityAllianceBossRegisterTimeChooseCell