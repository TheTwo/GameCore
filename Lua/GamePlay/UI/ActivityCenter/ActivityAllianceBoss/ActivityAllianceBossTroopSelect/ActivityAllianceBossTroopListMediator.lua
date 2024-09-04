---scene: scene_league_popup_behemoth_troop
local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local I18N = require("I18N")
---@class ActivityAllianceBossTroopListMediator : BaseUIMediator
local ActivityAllianceBossTroopListMediator = class("ActivityAllianceBossTroopListMediator", BaseUIMediator)

---@class ActivityAllianceBossTroopListMediatorParam
---@field battleData wds.AllianceActivityBattleInfo
---@field uiState number

function ActivityAllianceBossTroopListMediator:OnCreate()
    self.textTroop = self:Text("p_text_troop")
    self.tableTroop = self:TableViewPro("p_table_troop")
    self.textTitle1 = self:Text("p_text_title_1", "alliance_behemoth_title_playername")
    self.textTitle2 = self:Text("p_text_title_2", "alliance_challengeactivity_title_armyinfo")
    ---@see CommonPopupBackLargeComponent
    self.luaBackGround = self:LuaObject("child_popup_base_l")
end

---@param param ActivityAllianceBossTroopListMediatorParam
function ActivityAllianceBossTroopListMediator:OnOpened(param)
    self.battleData = param.battleData
    self.uiState = param.uiState
    self.luaBackGround:FeedData({title = I18N.Get('alliance_challengeactivity_title_armylist')})
    self:UpdateTroops()
end

function ActivityAllianceBossTroopListMediator:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
end

function ActivityAllianceBossTroopListMediator:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
end

function ActivityAllianceBossTroopListMediator:UpdateTroops()
    self.tableTroop:Clear()
    local numTroops = 0
    for _, v in pairs(self.battleData.Members) do
        ---@type ActivityAllianceBossTroopListCellParam
        local data = {}
        data.memberInfo = v
        data.memberPlayerInfo = ModuleRefer.AllianceModule:GetMyAllianceMemberDic(v.FacebookId)[v.FacebookId]
        data.battleId = self.battleData.ID
        data.uiState = self.uiState
        self.tableTroop:AppendData(data)
        numTroops = numTroops + 1
    end
    self.textTroop.text = string.format(I18N.Get('alliance_challengeactivity_title_armynumber') .. ': %d/%d', numTroops, ConfigRefer.AllianceBattle:Find(self.battleData.CfgId):MaxJoinMemberCount())
end

function ActivityAllianceBossTroopListMediator:OnBattleInfoChanged()
   self:UpdateTroops()
end

return ActivityAllianceBossTroopListMediator