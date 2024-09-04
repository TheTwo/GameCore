local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local AllianceTaskItemDataProvider = require("AllianceTaskItemDataProvider")

---@class AllianceTimeLimitedTaskMediator : BaseUIMediator
local AllianceTimeLimitedTaskMediator = class('AllianceTimeLimitedTaskMediator', BaseUIMediator)
function AllianceTimeLimitedTaskMediator:OnCreate()
    self.p_text_title = self:Text('p_text_title',"alliance_target_3")
    self.p_table_task = self:TableViewPro('p_table_task')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClick))
end

function AllianceTimeLimitedTaskMediator:OnOpened(param)
    ModuleRefer.AllianceJourneyModule:LoadAllianceShortTermTasks()
    local tasks = ModuleRefer.AllianceJourneyModule:GetAllianceShortTermTasks()
    for k, v in pairs(tasks) do
        local data = v
        data.provider = AllianceTaskItemDataProvider.new(v.TID)
        self.p_table_task:AppendData(data)
    end
end

function AllianceTimeLimitedTaskMediator:OnBtnCloseClick(param)
    self:CloseSelf()
end

function AllianceTimeLimitedTaskMediator:OnClose(param)
end

return AllianceTimeLimitedTaskMediator
