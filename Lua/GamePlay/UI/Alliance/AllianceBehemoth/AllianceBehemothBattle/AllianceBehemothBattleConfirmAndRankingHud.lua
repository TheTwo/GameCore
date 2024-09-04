---parent HUDMediator
local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIHelper = require("UIHelper")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local AllianceBehemothBattleConfirmBtnFuncProvider = require("AllianceBehemothBattleConfirmBtnFuncProvider")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local DisableType = AllianceBehemothBattleConfirmBtnFuncProvider.DisableType
---@class AllianceBehemothBattleConfirmAndRankingHud : BaseUIComponent
local AllianceBehemothBattleConfirmAndRankingHud = class('AllianceBehemothBattleConfirmAndRankingHud', BaseUIComponent)

---@class AllianceBehemothBattleConfirmAndRankingHudParam
---@field boss TroopCtrl

function AllianceBehemothBattleConfirmAndRankingHud:ctor()
    self.disableBtnFunc = function ()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("*Defalut Error"))
    end
end

function AllianceBehemothBattleConfirmAndRankingHud:OnCreate()
    self.btnDetail = self:Button('p_btn_ranking_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClick))
    self.textTroopNum = self:Text('p_text_num')
    self.tableRank = self:TableViewPro('p_table_rank')
    self.goConfirm = self:GameObject('p_confirm')
    self.textStatus = self:Text('p_text_status')
    self.textCountDown = self:Text('p_text_status_1')
    self.goRanking = self:GameObject('p_table_rank')
    self.btnConfirm = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnBtnConfirmClick))
    self.textBtnConfirm = self:Text('p_text')
    self.textReadyTroopNum = self:Text('p_text_status')
    self.luaTypeDropdown = self:LuaObject('child_dropdown_scroll')
end

function AllianceBehemothBattleConfirmAndRankingHud:OnShow(param)
    self.luaTypeDropdown:SetVisible(false)
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.AllianceBehemothBattleConfirmAndRankingMediator) then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceBehemothBattleConfirmAndRankingMediator)
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnBehemothCageStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.VillageWar.PlayerPreparation.MsgPath, Delegate.GetOrCreate(self, self.OnPrepareInfoChanged))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function AllianceBehemothBattleConfirmAndRankingHud:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.BehemothCage.Status.MsgPath, Delegate.GetOrCreate(self, self.OnBehemothCageStatusChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.VillageWar.PlayerPreparation.MsgPath, Delegate.GetOrCreate(self, self.OnPrepareInfoChanged))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

---@param param AllianceBehemothBattleConfirmAndRankingHudParam
function AllianceBehemothBattleConfirmAndRankingHud:OnFeedData(param)
    ---@type BehemothTroopCtrl
    self.boss = param.boss
    self.cage = self.boss.cageEntity
    self.hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.StartBehemothWar)
    self.isInWaiting = (self.cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) ~= 0
    self.btnFuncProvider = AllianceBehemothBattleConfirmBtnFuncProvider.new(self.btnConfirm, self.cage)

    if self.hasAuthority then
        self.textBtnConfirm.text = I18N.Get("alliance_behemoth_title_openwar")
        self.enableType = AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.StartBattle
    else
        self.textBtnConfirm.text = I18N.Get("alliance_behemoth_title_ready")
        self.enableType = AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.ReadyBattle
    end
    self:UpdateUI()
end

function AllianceBehemothBattleConfirmAndRankingHud:UpdateUI()
    self.goConfirm:SetActive(self.isInWaiting)
    self.goRanking:SetActive(not self.isInWaiting)
    self.textCountDown.gameObject:SetActive(self.isInWaiting)
    if not self.isInWaiting then
        self:UpdateDamage()
    else
        local buildingCfg = ConfigRefer.FixedMapBuilding:Find(self.cage.BehemothCage.ConfigId)
        local cageCfg = ConfigRefer.BehemothCage:Find(buildingCfg:BehemothCageConfig())
        local waitDuration = cageCfg:StandbyDuration() / 1e9
        self.waitTillSec = self.cage.BehemothCage.StartWaitingTimestamp + waitDuration
    end
    self:UpdatePrepareInfo()
end

function AllianceBehemothBattleConfirmAndRankingHud:UpdateDamage()
    self.tableRank:Clear()
    local damageList, damageTotal, damageHighest = ModuleRefer.SlgModule:GetMobDamageData(self.boss:GetData())
    for index, value in ipairs(damageList) do
        ---@type GveBattleDamageInfoCellData
        local info = {}
        info.index = index
        info.isSelf = ModuleRefer.PlayerModule:IsMineById(value.playerId)
        info.damageInfo = value
        info.allDamage = damageTotal
        info.maxPlayerDamage = damageHighest
        info.isThumbnail = true
        self.tableRank:AppendData(info)
    end
end

function AllianceBehemothBattleConfirmAndRankingHud:UpdatePrepareInfo()
    self.disableType = nil
    self.btnDisable = false
    local playerId = ModuleRefer.PlayerModule:GetPlayerId()
    local readyCount = 0
    local totalCount = 0
    local selfInRange = false
    for _, v in pairs(self.cage.VillageWar.PlayerPreparation) do
        if v.PlayerId == playerId then
            selfInRange = true
        end
        if v.PlayerId == playerId and self.hasAuthority then
            readyCount = readyCount + 1
            if not v.Ready then
                self.btnFuncProvider:OnBtnEnableClick(AllianceBehemothBattleConfirmBtnFuncProvider.EnableType.ReadyBattle)
            end
        elseif v.Ready then
            readyCount = readyCount + 1
        end
        totalCount = totalCount + 1
    end
    if not selfInRange and not self.disableType then
        self.disableType = DisableType.NotInRange
    end
    self.textReadyTroopNum.text = I18N.Get("alliance_behemoth_title_readied") .. readyCount
    if not self.hasAuthority then
        for _, v in pairs(self.cage.VillageWar.PlayerPreparation) do
            if v.Ready and v.PlayerId == playerId then
                self.disableType = DisableType.ReadyPlayer
                break
            end
        end
    else
        if totalCount == 0 then
            self.disableType = DisableType.NotInRange
        end
    end
    self.btnDisable = self.disableType ~= nil
    UIHelper.SetGray(self.btnConfirm.gameObject, self.btnDisable)
    self.textTroopNum.text = I18N.Get("alliance_behemoth_title_number") .. totalCount
end

---@param entity wds.BehemothCage
function AllianceBehemothBattleConfirmAndRankingHud:OnBehemothCageStatusChanged(entity, _)
	if not self.cage or not entity or self.cage.ID ~= entity.ID then return end
    self.isInWaiting = (self.cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) ~= 0
    self:UpdateUI()
end

---@param entity wds.MapMob
function AllianceBehemothBattleConfirmAndRankingHud:OnDamageChanged(entity, _)
	if not entity or not self.boss or not self.boss:GetData() or self.boss:GetData().ID ~= entity.ID then return end
	self:UpdateDamage()
end

---@param entity wds.BehemothCage
function AllianceBehemothBattleConfirmAndRankingHud:OnPrepareInfoChanged(entity, _)
	if not self.cage or not entity or self.cage.ID ~= entity.ID then return end
    self:UpdatePrepareInfo()
end

function AllianceBehemothBattleConfirmAndRankingHud:OnSecondTicker()
    if self.isInWaiting then
        local remainSec = self.waitTillSec - g_Game.ServerTime:GetServerTimestampInSeconds()
        if remainSec < 0 then
            remainSec = 0
        end
        self.textCountDown.text = I18N.Get("alliance_behemoth_title_readytiem") .. TimeFormatter.SimpleFormatTimeWithoutHour(remainSec)
    end
end

function AllianceBehemothBattleConfirmAndRankingHud:OnBtnDetailClick()
    ---@type AllianceBehemothBattleConfirmAndRankingMediatorParameter
    local data = {}
    data.cage = self.cage
    data.mapMob = self.boss:GetData()
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothBattleConfirmAndRankingMediator, data)
end

function AllianceBehemothBattleConfirmAndRankingHud:OnBtnConfirmClick()
    if self.btnDisable then
        self.btnFuncProvider:OnBtnDisableClick(self.disableType, self.hasAuthority)
    else
        self.btnFuncProvider:OnBtnEnableClick(self.enableType)
    end
end

return AllianceBehemothBattleConfirmAndRankingHud
