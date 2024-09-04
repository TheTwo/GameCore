local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local ColorConsts = require('ColorConsts')
local UIHelper = require("UIHelper")
local Delegate = require('Delegate')
local EventConst = require('EventConst')

---@class LeaderboardTabsSubCellData
---@field leaderboardConfigCell LeaderboardConfigCell
---@field type number
---@field isSelect boolean

---@class LeaderboardTabsSubCell:BaseTableViewProCell
---@field new fun():LeaderboardTabsSubCell
---@field super BaseTableViewProCell
local LeaderboardTabsSubCell = class('LeaderboardTabsSubCell', BaseTableViewProCell)

function LeaderboardTabsSubCell:OnCreate()
    self.title = self:Text('p_text_2rd')
    self.btnSelf = self:Button('', Delegate.GetOrCreate(self, self.OnClick))
    ---@type NotificationNode
    self.child_reddot = self:LuaObject('child_reddot_default')

    ---@type CS.StatusRecordParent
    self.statusControl = self:StatusRecordParent("")
end

---@param data LeaderboardTabsSubCellData
function LeaderboardTabsSubCell:OnFeedData(data)
    self.cellData = data

    self.child_reddot:SetVisible(false)

    self.title.text = I18N.Get(data.leaderboardConfigCell:Name())
    if data.isSelect then
        self.statusControl:ApplyStatusRecord(1)
    else
        self.statusControl:ApplyStatusRecord(0)
    end
end

function LeaderboardTabsSubCell:OnClick()
    g_Game.EventManager:TriggerEvent(EventConst.LEADERBOARD_TAB_SUB_CLICK, self.cellData.leaderboardConfigCell:Id())
end

return LeaderboardTabsSubCell