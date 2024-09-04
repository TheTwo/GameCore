local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local ColorConsts = require('ColorConsts')
local UIHelper = require("UIHelper")
local I18N = require('I18N')

---@class LeaderboardTabsMainCellData
---@field type LeaderboardType
---@field isSelect boolean
---@field canFold boolean   能不能折叠
---@field isUnfold boolean    是否打开了
---@field isUnlock boolean 是否没解锁

---@class LeaderboardTabsMainCell:BaseTableViewProCell
---@field new fun():LeaderboardTabsMainCell
---@field super BaseTableViewProCell
local LeaderboardTabsMainCell = class('LeaderboardTabsMainCell', BaseTableViewProCell)

function LeaderboardTabsMainCell:OnCreate()
    self.goSelect = self:GameObject('p_base_select')
    self.txtTabName = self:Text('p_text_1')
    self.txtTabName2 = self:Text('p_text_2')
    self.goUnfold = self:GameObject('p_icon_unfold')
    self.goFold = self:GameObject('p_icon_fold')
    self.btnSelf = self:Button('', Delegate.GetOrCreate(self, self.OnClick))
    self.goLock = self:GameObject('p_icon_lock')
    ---@type NotificationNode
    self.child_reddot = self:LuaObject('child_reddot_default')
end

---@param data LeaderboardTabsMainCellData
function LeaderboardTabsMainCell:OnFeedData(data)
    self.data = data
    self.goSelect:SetVisible(data.isSelect)
    self.goUnfold:SetVisible(data.canFold and data.isUnfold)
    self.goFold:SetVisible(data.canFold and not data.isUnfold)
    self.txtTabName.text = ModuleRefer.LeaderboardModule:GetMainTabTitle(data.type)
    self.txtTabName2.text = ModuleRefer.LeaderboardModule:GetMainTabTitle(data.type)
    self.txtTabName:SetVisible(data.isSelect)
    self.txtTabName2:SetVisible(not data.isSelect)

    self.goLock:SetVisible(not data.isUnlock)
    self.child_reddot:SetVisible(data.type == require('LeaderboardUIMediator').TAB_MAIN_TOP_PLAYER)
    ModuleRefer.LeaderboardModule:AttachLeaderboardHonorTabRedDot(self.child_reddot.CSComponent.gameObject)
    ModuleRefer.LeaderboardModule:UpdateDailyRewardState()
end

function LeaderboardTabsMainCell:OnClick()
    if not self.data.isUnlock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('leaderboard_info_2'))
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.LEADERBOARD_TAB_MAIN_CLICK, self.data.type)
end

return LeaderboardTabsMainCell