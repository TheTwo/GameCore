local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local PayConfirmHelper = require("PayConfirmHelper")
local EventConst = require("EventConst")

local ReplicaPvpRefreshTargetParameter = require("ReplicaPvpRefreshTargetParameter")

---@class ReplicaPVPChallengeMediatorParameter

---@class ReplicaPVPChallengeMediator:BaseUIMediator
---@field new fun():ReplicaPVPChallengeMediator
---@field super BaseUIMediator
local ReplicaPVPChallengeMediator = class('ReplicaPVPChallengeMediator', BaseUIMediator)

function ReplicaPVPChallengeMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")

    self.txtChallenge = self:Text('p_text_challenge')
    self.btnAddChallenge = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnAddChallengeClicked))

    self.tableChallengeList = self:TableViewPro('p_table_player')

    ---@type BistateButton
    self.btnChange = self:LuaObject('child_comp_btn_b')

    ---@see CommonResourceBtn
    self.luaResource = self:LuaObject('child_resource')
end

---@param data ReplicaPVPChallengeMediatorParameter
function ReplicaPVPChallengeMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backButtonData = {}
    backButtonData.title = I18N.Get('se_pvp_challengelist_name')
    backButtonData.hideClose = false
    self._child_popup_base_l:FeedData(backButtonData)
    local ticketId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
    ---@type CommonResourceBtnSimplifiedData
    local data = {}
    data.itemId = ticketId
    data.isShowPlus = true
    data.onClick = Delegate.GetOrCreate(self, self.OnAddChallengeClicked)
    self.luaResource:FeedData(data)
    self:RefreshUI()
end

function ReplicaPVPChallengeMediator:OnClose(param)

end

function ReplicaPVPChallengeMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.DefenderInfos.MsgPath, Delegate.GetOrCreate(self, self.OnDefenderInfosChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.CanChallengeTimes.MsgPath, Delegate.GetOrCreate(self, self.OnDefenderInfosChanged))

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function ReplicaPVPChallengeMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.DefenderInfos.MsgPath, Delegate.GetOrCreate(self, self.OnDefenderInfosChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.CanChallengeTimes.MsgPath, Delegate.GetOrCreate(self, self.OnDefenderInfosChanged))

    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function ReplicaPVPChallengeMediator:OnSecondTick()
    self:RefreshChangeBtn()
end

function ReplicaPVPChallengeMediator:RefreshUI()
    self:RefreshChallengeTimeUI()
    self:RefreshChallengeListUI()
    self:RefreshChangeBtn()
end

function ReplicaPVPChallengeMediator:RefreshChallengeListUI()
    local challengeList = ModuleRefer.ReplicaPVPModule:GetChallengeList()
    local count = challengeList:Count()
    if count > 0 then
        self.tableChallengeList:Clear()
        for i = 1, count do
            ---@type ReplicaPVPChallengeCellData
            local data = {}
            data.basicInfo = challengeList[i]
            data.onChallengeClick = Delegate.GetOrCreate(self, self.OnChallengeClicked)
            self.tableChallengeList:AppendData(data)
        end
    end
end

function ReplicaPVPChallengeMediator:RefreshChallengeTimeUI()
    local freeMax = ConfigRefer.ReplicaPvpConst:FreeChallengeNum()
    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    self.txtChallenge.text = I18N.GetWithParams('se_pvp_challengelist_chance', canChallengeTimes, freeMax)
end

function ReplicaPVPChallengeMediator:RefreshChangeBtn()
    local refreshCD = ModuleRefer.ReplicaPVPModule:GetChallengeRefreshCD()

    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnChangeClicked)
    if refreshCD > 0 then
        btnData.buttonText = string.format('%s(%ss)', I18N.Get('se_pvp_challengelist_change'), refreshCD)
    else
        btnData.buttonText = I18N.Get('se_pvp_challengelist_change')
    end
    self.btnChange:FeedData(btnData)
    self.btnChange:SetEnabled(refreshCD == 0)
end

---@param basicInfo wds.ReplicaPvpPlayerBasicInfo
function ReplicaPVPChallengeMediator:OnChallengeClicked(basicInfo)
    local canChallengeTimes = ModuleRefer.ReplicaPVPModule:CanChallengeTimes()
    if canChallengeTimes == 0 then
        local ticketItemId = ModuleRefer.ReplicaPVPModule:GetTicketItemId()
        local curTicketNum = ModuleRefer.InventoryModule:GetAmountByConfigId(ticketItemId)
        if curTicketNum <= 0 then
            PayConfirmHelper.ShowSimpleConfirmationPopupForInsufficientItem(ticketItemId, 1)
            return
        end
    end

    ModuleRefer.ReplicaPVPModule:OpenAttackTroopEditUI(basicInfo.PlayerId)
    g_Game.EventManager:TriggerEvent(EventConst.REPLICA_PVP_CHALLENGE_CLICK)
end

function ReplicaPVPChallengeMediator:OnAddChallengeClicked()
    ModuleRefer.ReplicaPVPModule:OpenPVPShop()
end

function ReplicaPVPChallengeMediator:OnChangeClicked()
    local refreshCD = ModuleRefer.ReplicaPVPModule:GetChallengeRefreshCD()
    if refreshCD > 0 then
        return
    end

    local req = ReplicaPvpRefreshTargetParameter.new()
    req:Send()
end

function ReplicaPVPChallengeMediator:OnChallengeTimeChanged()
    self:RefreshChallengeTimeUI()
end

function ReplicaPVPChallengeMediator:OnDefenderInfosChanged()
    self:RefreshUI()
end

return ReplicaPVPChallengeMediator