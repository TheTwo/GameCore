local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
local NumberFormatter = require("NumberFormatter")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")

---@class ReplicaPVPBattleRecordCellData
---@field recordInfo wds.ReplicaPvpBattleRecordInfo
---@field onChallengeClick fun(wds.ReplicaPvpBattleRecordInfo)
---@field showAttack boolean

---@class ReplicaPVPChallengeCell:BaseTableViewProCell
---@field new fun():ReplicaPVPChallengeCell
---@field super BaseTableViewProCell
local ReplicaPVPBattleRecordCell = class('ReplicaPVPBattleRecordCell', BaseTableViewProCell)

function ReplicaPVPBattleRecordCell:OnCreate()
    self.imgBg = self:Image('p_base_status')

    self.imgAttacker = self:Image('p_icon_attack')
    self.imgDefender = self:Image('p_icon_defence')

    self.imgBgWin = self:Image('p_base_status_win')
    self.imgBgLose = self:Image('p_base_status_lose')

    ---@type PlayerInfoComponent
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')
    self.txtRecordTime = self:Text('p_text_time')
    self.txtPower = self:Text('p_text_power')
    self.txtScoreChange = self:Text('p_text_integer')
    self.btnChallenge = self:Button('p_btn_challenge', Delegate.GetOrCreate(self, self.OnChallengeClicked))
    self.txtChallenge = self:Text('p_text', 'se_pvp_challengelist_play')
    self.goBtnNumber = self:GameObject('p_number_cl')
    self.imgBtnIcon = self:Image('p_icon_item_cl')
    self.textNumWhite = self:Text('p_text_num_wilth_cl')
    self.textNumRed = self:Text('p_text_num_red_cl')

    self.imgIconLevel = self:Image('p_icon_level')
    self.imgIconLevelNum = self:Image('p_icon_lv_num')
end

---@param data ReplicaPVPBattleRecordCellData
function ReplicaPVPBattleRecordCell:OnFeedData(data)
    self.data = data

    if data.recordInfo.IsSuccess then
        g_Game.SpriteManager:LoadSprite('sp_mail_base_victory', self.imgBg)
    else
        g_Game.SpriteManager:LoadSprite('sp_mail_base_defeat', self.imgBg)
    end

    self.imgBgWin:SetVisible(data.recordInfo.IsSuccess)
    self.imgBgLose:SetVisible(not data.recordInfo.IsSuccess)

    self.imgAttacker:SetVisible(data.recordInfo.IsAttacker)
    self.imgDefender:SetVisible(not data.recordInfo.IsAttacker)

    self.playerIcon:FeedData(data.recordInfo.BasicInfo.Portrait)
    self.playerIcon:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnHeadClicked))

    self.txtPlayerName.text = data.recordInfo.BasicInfo.Name
    self.txtRecordTime.text = TimeFormatter.FormatTimesAgo(data.recordInfo.BattleTime.Seconds)
    self.txtPower.text = NumberFormatter.Normal(data.recordInfo.BasicInfo.DefPreset.Power)
    self.txtScoreChange.text = ModuleRefer.ReplicaPVPModule:GetScoreChangedText(data.recordInfo.ScoreChangedVal)

    self.btnChallenge:SetVisible(data.showAttack)

    self.ticketItemId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    self.goBtnNumber:SetActive(canChallengeTimes <= 0)
    self.textNumWhite.text = 1
    self.textNumRed.text = 1
    local curTicketNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.ticketItemId)
    self.textNumRed.gameObject:SetActive(curTicketNum <= 0)
    self.textNumWhite.gameObject:SetActive(curTicketNum > 0)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(self.ticketItemId):Icon(), self.imgBtnIcon)

    local titleId = self.data.recordInfo.BasicInfo.TitleTid
    local titleCfg = ConfigRefer.PvpTitleStage:Find(titleId)
    if titleCfg then
        self:LoadSprite(titleCfg:Icon(), self.imgIconLevel)
        if titleCfg:LevelIcon() > 0 then
            self.imgIconLevelNum:SetVisible(true)
            self:LoadSprite(titleCfg:LevelIcon(), self.imgIconLevelNum)
        else
            self.imgIconLevelNum:SetVisible(false)
        end
    end
end

function ReplicaPVPBattleRecordCell:OnChallengeClicked()
    if self.data.onChallengeClick then
        self.data.onChallengeClick(self.data.recordInfo.BasicInfo)
    end
end

function ReplicaPVPBattleRecordCell:OnHeadClicked()
    ---@type ReplicaPVPTroopInfoTipsParameter
    local param = {}
    param.basicInfo = self.data.recordInfo.BasicInfo
    param.anchorTrans = self.playerIcon.CSComponent.transform
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPTroopInfoTips, param)
end

return ReplicaPVPBattleRecordCell