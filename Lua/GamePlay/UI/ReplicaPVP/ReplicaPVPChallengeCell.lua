local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require("Delegate")
local NumberFormatter = require("NumberFormatter")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local I18N = require("I18N")

---@class ReplicaPVPChallengeCellData
---@field basicInfo wds.ReplicaPvpPlayerBasicInfo
---@field onChallengeClick fun(wds.ReplicaPvpBattleRecordInfo)

---@class ReplicaPVPChallengeCell:BaseTableViewProCell
---@field new fun():ReplicaPVPChallengeCell
---@field super BaseTableViewProCell
local ReplicaPVPChallengeCell = class('ReplicaPVPChallengeCell', BaseTableViewProCell)

function ReplicaPVPChallengeCell:ctor()
    self.tick = true
end

function ReplicaPVPChallengeCell:OnCreate()
    ---@type PlayerInfoComponent
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')
    self.txtPower = self:Text('p_text_power')
    self.txtScore = self:Text('p_text_score')
    self.btnChallenge = self:Button('p_btn_challenge', Delegate.GetOrCreate(self, self.OnChallengeClicked))
    self.txtChallenge = self:Text('p_text', 'se_pvp_challengelist_play')
    self.goBtnNumber = self:GameObject('p_number_cl')
    self.imgBtnIcon = self:Image('p_icon_item_cl')
    self.textNumWhite = self:Text('p_text_num_wilth_cl')
    self.textNumRed = self:Text('p_text_num_red_cl')

    self.imgIconLevel = self:Image('p_icon_level')
    self.imgIconLevelNum = self:Image('p_icon_lv_num')
end

---@param data ReplicaPVPChallengeCellData
function ReplicaPVPChallengeCell:OnFeedData(data)
    self.data = data

    self.playerIcon:FeedData(data.basicInfo.Portrait)
    self.playerIcon:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnHeadClicked))

    self.txtPlayerName.text = data.basicInfo.Name
    self.txtPower.text = NumberFormatter.Normal(data.basicInfo.DefPreset.Power)
    self.txtScore.text = NumberFormatter.Normal(data.basicInfo.Score)

    self.ticketItemId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
    self:UpdateBtn()
end

function ReplicaPVPChallengeCell:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function ReplicaPVPChallengeCell:OnClose()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function ReplicaPVPChallengeCell:OnSecondTick()
    if not self.tick then return end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local seasonAttackableTime = player.PlayerWrapper3.PlayerReplicaPvp.SeasonAttackableTime.Seconds
    if g_Game.ServerTime:GetServerTimestampInSeconds() > seasonAttackableTime then
        self.tick = false
        self:UpdateBtn()
    end
end

function ReplicaPVPChallengeCell:UpdateBtn()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local seasonAttackableTime = player.PlayerWrapper3.PlayerReplicaPvp.SeasonAttackableTime.Seconds
    if g_Game.ServerTime:GetServerTimestampInSeconds() > seasonAttackableTime then
        self.btnChallenge.interactable = false
        self.txtChallenge.text = I18N.Get("se_pvp_insettlement")
        UIHelper.SetGray(self.btnChallenge.gameObject, true)
    else
        self.btnChallenge.interactable = true
        self.txtChallenge.text = I18N.Get("se_pvp_challengelist_play")
        UIHelper.SetGray(self.btnChallenge.gameObject, false)
    end

    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    self.goBtnNumber:SetActive(canChallengeTimes <= 0)
    self.textNumWhite.text = 1
    self.textNumRed.text = 1
    local curTicketNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.ticketItemId)
    self.textNumRed.gameObject:SetActive(curTicketNum <= 0)
    self.textNumWhite.gameObject:SetActive(curTicketNum > 0)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(self.ticketItemId):Icon(), self.imgBtnIcon)

    local titleId = self.data.basicInfo.TitleTid
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

function ReplicaPVPChallengeCell:OnChallengeClicked()
    if self.data.onChallengeClick then
        self.data.onChallengeClick(self.data.basicInfo)
    end
end

function ReplicaPVPChallengeCell:OnHeadClicked()
    ---@type ReplicaPVPTroopInfoTipsParameter
    local param = {}
    param.basicInfo = self.data.basicInfo
    param.anchorTrans = self.playerIcon.CSComponent.transform
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPTroopInfoTips, param)
end

return ReplicaPVPChallengeCell