---Scene Name : scene_common_popup_restart
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require("Delegate")
local Utils = require("Utils")
local I18N_TEMP = require("I18N_TEMP")

---@class SystemRestartUIMediator : BaseUIMediator
local SystemRestartUIMediator = class('SystemRestartUIMediator', BaseUIMediator)

---@class SystemRestartUIMediatorParameter
---@field title string
---@field content string
---@field btnText string
---@field context any
---@field showReportBtn boolean

function SystemRestartUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnRestart))

    self.textTitle = self:Text('p_title')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnRestart))

    self._p_text_confirm_detail = self:Text("p_text_confirm_detail")
    self._p_btn_confirm_b = self:Button("p_btn_confirm_b", Delegate.GetOrCreate(self, self.OnRestart))
    self._p_btn_confirm_b_lb = self:Text("p_btn_confirm_b_lb")
    self._p_btn_upload_bug = self:Button("p_btn_upload_bug", Delegate.GetOrCreate(self, self.OnReportBugAndRestart))
    self._p_txt_upload_bug = self:Text("p_txt_upload_bug", I18N_TEMP.text_bug_report)
end

---@param param SystemRestartUIMediatorParameter
function SystemRestartUIMediator:OnOpened(param)
    self.textTitle.text = param.title
    self._context = param.context
    self._p_text_confirm_detail.text = param.content
    self._p_btn_confirm_b_lb.text = param.btnText
    self._restart = false
    if g_Game.debugSupportOn then
        self._p_btn_upload_bug:SetVisible(param.showReportBtn)
    else
        self._p_btn_upload_bug:SetVisible(false)
    end
end

function SystemRestartUIMediator:OnClose()
    if not self._restart then
        g_Game:RestartGame()
    end
end

function SystemRestartUIMediator:OnRestart()
    self._restart = true
    g_Game:RestartGame()
end

local function GetReporter()
    return CS and CS.SdkAdapter and CS.SdkAdapter.SdkModels and CS.SdkAdapter.SdkModels.SdkProblemDingTalkReport or nil
end

function SystemRestartUIMediator:OnReportBugAndRestart()
    if self._context and type(self._context) == 'string' then
        local reporter = GetReporter()
        if reporter then
            local hasDingAt,dingAtStr = require("ModuleRefer").AppInfoModule:GetDingTalkAt()
            reporter.ReportProblem(self._context, hasDingAt and dingAtStr or string.Empty)
        end
    end
    self:OnRestart()
end

return SystemRestartUIMediator