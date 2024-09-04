---scene:scene_mail_multidetail_popup

local Delegate = require("Delegate")
local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require("ModuleRefer")
local Mail = ModuleRefer.MailModule
local I18N = require("I18N")
local MailUtils = require("MailUtils")

---@class UIMailDetailMediator : BaseUIMediator
local UIMailDetailMediator = class("UIMailDetailMediator", BaseUIMediator)

---@class UIMailDetailData
---@field mail wds.Mail

local BR_CELL_INDEX_OVERALL = 0
local BR_CELL_INDEX_HEADER = 1
local BR_CELL_INDEX_TEAM = 2

function UIMailDetailMediator:OnCreate()
    self.commonPopup = self:LuaObject("child_popup_base_l")
    self.brTable = self:TableViewPro("p_table_war")
    self.lastButton = self:Button("p_btn_last", Delegate.GetOrCreate(self, self.OnLastClick))
    self.nextButton = self:Button("p_btn_next", Delegate.GetOrCreate(self, self.OnNextClick))
    self.index = 0
end

---@param param UIMailDetailData
function UIMailDetailMediator:OnShow(param)
    self.commonPopup:FeedData({title = I18N.Get("battlemessage_detail")})
    self.mail = param.mail
    self.report = self.mail.BattleReport
    self.index = 1
    self.count = #self.report.Records
    self:RefreshUI()
end

function UIMailDetailMediator:RefreshUI()
    self.brTable:Clear()

    if self.index < 1 or self.index > self.count then
        return
    end

    local report = self.report
    local record = report.Records[self.index]

    -- 标题部分
    local _, sp = Mail:GetBattleReportTitle(report)

    -- 总览
    ---@type BattleReportOverviewCellData
    local overviewData =
    {
        result = record.Result,
        attacker = record.Attacker.BasicInfo,
        target = record.Target.BasicInfo,
        sceneType = report.SceneType,
        titleImageSp = sp,
        titleTimeStr = Mail:GetElapsedTimeString(self.mail.ID),
        showHp = true
    }

    local _, totalDamageTaken, _ = MailUtils.CalculateTotalStatistics(record.Target)
    overviewData.target.TakeDamage = totalDamageTaken
    
    self.brTable:AppendData(overviewData, BR_CELL_INDEX_OVERALL)

    -- 题头
    ---@type BattleReportHeaderCellData
    local headerData = {record = record}
    self.brTable:AppendData(headerData, BR_CELL_INDEX_HEADER)

    -- 部队
    local attackers = MailUtils.GetHerosAndPets(record.Attacker)
    local defenders = MailUtils.GetHerosAndPets(record.Target)
    local count = math.max(#attackers, #defenders)
    
    for index = 1, count do
        ---@type BattleReportTeamCellData
        local teamData = {record = record, attacker = attackers[index], defender = defenders[index]}
        self.brTable:AppendData(teamData, BR_CELL_INDEX_TEAM)
    end
end

function UIMailDetailMediator:OnLastClick()
    self.index = math.max(self.index - 1, 1)
    self:RefreshUI()
end

function UIMailDetailMediator:OnNextClick()
    self.index = math.min(self.index + 1, self.count)
    self:RefreshUI()
end

return UIMailDetailMediator