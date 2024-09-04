---scene: scene_se_pvp_main
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local DBEntityPath = require("DBEntityPath")
local NumberFormatter = require("NumberFormatter")
local FunctionClass = require("FunctionClass")
local EventConst = require("EventConst")

local GetTopListParameter = require("GetTopListParameter")
local GetReplicaPvpPlayerInfoParameter = require("GetReplicaPvpPlayerInfoParameter")

---@class ReplicaPVPMainMediatorParameter

---@class ReplicaPVPMainMediator:BaseUIMediator
---@field new fun():ReplicaPVPMainMediator
---@field super BaseUIMediator
local ReplicaPVPMainMediator = class('ReplicaPVPMainMediator', BaseUIMediator)

local ProgressMaxValue = 0.33

function ReplicaPVPMainMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self.commonBackComp = self:LuaObject("child_common_btn_back")

    -- 左侧面板
    self.goNextLevel = self:GameObject('p_next_level')
    self.imgHeadFrame = self:Image('p_img_head_frame')
    self.textNextLevel = self:Text('p_text_next_level', 'se_pvp_reward_nextstage')
    self.textFrameTime = self:Text('p_text_frame_time')

    self.btnTips = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnTipsClicked))

    self.goLevel = self:GameObject('p_full_level')
    self.imageLvIcon = self:Image('p_icon_lv')
    self.imageLvIconNum = self:Image('p_icon_lv_num')
    self.txtLvName = self:Text('p_text_lv')

    self.sliderExp = self:Slider('p_progress_integer')
    self.txtExp = self:Text('p_text_num')

    self.textLvlRewardLabel = self:Text('p_text_reward_level', 'se_pvp_reward_season_currentrank')
    self.tableLvlReward = self:TableViewPro('p_table_reward_level')

    self.btnDailyReward = self:Button('p_reward_area', Delegate.GetOrCreate(self, self.OnDailyRewardAreaClicked))
    self.txtDailyReward = self:Text('p_text_reward_today', 'se_pvp_reward_day')
    self.tableDailyReward = self:TableViewPro('p_table_reward')

    self.imgProgress = self:Image('p_progress_score')
    self.textProgress = self:Text('p_text_number')

    -- 底部按钮
    self.btnShop = self:Button('p_btn_shop', Delegate.GetOrCreate(self, self.OnShopClicked))
    self.txtShop = self:Text('p_text_shop', 'se_pvp_main_shop')
    self.reddotShop = self:LuaObject('child_reddot_shop')
    self.btnBattleRecord = self:Button('p_btn_record', Delegate.GetOrCreate(self, self.OnBattleRecordClicked))
    self.txtBattleRecord = self:Text('p_text_record', 'se_pvp_main_history')
    ---@type NotificationNode
    self.reddotBattleRecord = self:LuaObject('child_reddot_record')

    -- 右侧面板
    self.txtHeaderRanking = self:Text('p_text_title_rank', 'se_pvp_main_rank')
    self.txtHeaderPlayer = self:Text('p_text_title_player', 'se_pvp_main_player')
    self.txtHeaderRank = self:Text('p_text_title_level', 'se_pvp_main_level')
    self.tableRanks = self:TableViewPro('p_table_ranking')

    -- 自己的排名信息
    self.goMyRankItem = self:GameObject('p_rank_item_mime')
    ---@type PlayerInfoComponent
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player_me')
    self.txtPlayerPowerNumber = self:Text('p_text_power_me')
    self.txtPlayerScoreNumber = self:Text('p_text_score_me')
    self.imageLvIconMine = self:Image('p_icon_level_me')
    self.imageLvIconNumMine = self:Image('p_icon_lv_num_me')

    self.txtRankTitle = self:Text('p_text_ranking', 'se_pvp_main_selfrank')
    self.imgMyRankTop1 = self:Image('p_icon_rank_top_1_me')
    self.imgMyRankTop2 = self:Image('p_icon_rank_top_2_me')
    self.imgMyRankTop3 = self:Image('p_icon_rank_top_3_me')
    self.txtMyRankOther = self:Text('p_text_rank_me')

    self.btnTroop = self:Button('p_btn_troop', Delegate.GetOrCreate(self, self.OnTroopClicked))
    self.txtTroop = self:Text('p_text_troop', 'se_pvp_main_defend')
    self.btnChallenge = self:Button('p_btn_challenge', Delegate.GetOrCreate(self, self.OnChallengeClicked))
    self.txtChallenge = self:Text('p_text_challenge', 'se_pvp_main_play')
    self.btnRankReview = self:Button('p_btn_view', Delegate.GetOrCreate(self, self.OnRankReviewClicked))
    self.txtRankReview = self:Text('p_text_ranking_btn', 'se_pvp_main_reward')

    ---@type NotificationNode
    self.reddotChallenge = self:LuaObject('child_reddot_challenge')
end

---@param data ReplicaPVPMainMediatorParameter
function ReplicaPVPMainMediator:OnOpened(data)

    ---@type CommonBackButtonData
    local commonBackButtonData = {}
    commonBackButtonData.title = I18N.Get('se_pvp_main_name')
    commonBackButtonData.onClose = Delegate.GetOrCreate(self, self.OnClickBtnClose)
    self.commonBackComp:FeedData(commonBackButtonData)

    ModuleRefer.ReplicaPVPModule:SendRefreshPvpLeaderboard()
    ModuleRefer.ReplicaPVPModule:NotifyPvpMainState(true)
end

function ReplicaPVPMainMediator:OnClose(data)
    ModuleRefer.ReplicaPVPModule:NotifyPvpMainState(false)
end

function ReplicaPVPMainMediator:OnShow(param)
    g_Game.ServiceManager:AddResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.BattleRecord.MsgPath, Delegate.GetOrCreate(self, self.OnBattleRecordChanged))
    g_Game.EventManager:AddListener(EventConst.REPLICA_PVP_CHALLENGE_CLICK, Delegate.GetOrCreate(self, self.OnCellChallengeClicked))
    self:RefreshUI()
end

function ReplicaPVPMainMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(GetTopListParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnGetTopListResponse))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerReplicaPvp.BattleRecord.MsgPath, Delegate.GetOrCreate(self, self.OnBattleRecordChanged))
    g_Game.EventManager:RemoveListener(EventConst.REPLICA_PVP_CHALLENGE_CLICK, Delegate.GetOrCreate(self, self.OnCellChallengeClicked))
end

---@param isSuccess boolean
---@param reply wrpc.GetTopListReply
---@param req AbstractRpc
function ReplicaPVPMainMediator:OnGetTopListResponse(isSuccess, reply, req)
    self.reply = reply
    self:RefreshLeaderboardUI()
end

function ReplicaPVPMainMediator:OnBattleRecordChanged()
    self:RefreshChallengeReddot()
end

function ReplicaPVPMainMediator:RefreshUI()
    -- 左侧面板信息
    -- 阶位相关信息
    local myTitleStageConfigCell = ModuleRefer.ReplicaPVPModule:GetMyPVPTitleStageConfigCell()
    if myTitleStageConfigCell == nil then
        return
    end
    local immdReward = nil
    for _, stageCfg in ConfigRefer.PvpTitleStage:ipairs() do
        if stageCfg:Id() <= myTitleStageConfigCell:Id() then
            goto continue
        end
        if stageCfg:IMMDReward() > 0 then
            immdReward = stageCfg:IMMDReward()
            break
        end
        ::continue::
    end
    if immdReward then
        self:RefreshNextTitle(immdReward)
    else
        self:RefreshTitleStage(myTitleStageConfigCell)
    end

    -- 当前段位结算奖励
    self.tableLvlReward:Clear()
    local settleRewardItemGroupId = myTitleStageConfigCell:SettleReward()
    local settleRewardConfigCell = ConfigRefer.ItemGroup:Find(settleRewardItemGroupId)
    if settleRewardConfigCell then
        for i = 1, settleRewardConfigCell:ItemGroupInfoListLength() do
            local itemGroupInfo = settleRewardConfigCell:ItemGroupInfoList(i)
            self.tableLvlReward:AppendData(itemGroupInfo)
        end
    end

    -- 我当前段位的每日奖励信息
    self.tableDailyReward:Clear()
    local myItemGroupId = myTitleStageConfigCell:DailySettleReward()
    local itemGroupConfigCell = ConfigRefer.ItemGroup:Find(myItemGroupId)
    if itemGroupConfigCell then
        for i = 1, itemGroupConfigCell:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroupConfigCell:ItemGroupInfoList(i)
            self.tableDailyReward:AppendData(itemGroupInfo)
        end
    end
    self:EnableChallengeBtn()
    self:RefreshLeaderboardUI()
    self:RefreshChallengeReddot()
end

function ReplicaPVPMainMediator:RefreshTitleStage(myTitleStageConfigCell)
    self.goLevel:SetActive(true)
    self.goNextLevel:SetActive(false)
    self:LoadSprite(myTitleStageConfigCell:Icon(), self.imageLvIcon)
    if myTitleStageConfigCell:LevelIcon() > 0 then
        self.imageLvIconNum:SetVisible(true)
        self:LoadSprite(myTitleStageConfigCell:LevelIcon(), self.imageLvIconNum)
    else
        self.imageLvIconNum:SetVisible(false)
    end
    self.txtLvName.text = I18N.Get(myTitleStageConfigCell:Name())

    local showSlider = ModuleRefer.ReplicaPVPModule:ShowScoresProgress(myTitleStageConfigCell)
    self.sliderExp:SetVisible(showSlider)
    self.txtExp:SetVisible(showSlider)
    if showSlider then
        local myPoints = ModuleRefer.ReplicaPVPModule:GetMyPoints()
        local min, max, progress = self:GetSliderInfo(myTitleStageConfigCell, myPoints)
        self.sliderExp.value = progress
        self.txtExp.text = string.format('%d/%d', myPoints, max)
    end
end

function ReplicaPVPMainMediator:RefreshNextTitle(immdReward)
    self.goLevel:SetActive(false)
    self.goNextLevel:SetActive(true)
    local frameItem = nil
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(immdReward)
    for _, item in ipairs(items) do
        if item.configCell:FunctionClass() == FunctionClass.AddAdornment then
            frameItem = item
            break
        end
    end
    if not frameItem then return end
    g_Game.SpriteManager:LoadSprite(frameItem.configCell:Icon(), self.imgHeadFrame)
    local progress = ModuleRefer.ReplicaPVPModule:GetTitleRewardProgress()
    local realProgress = progress * ProgressMaxValue
    self.imgProgress.fillAmount = realProgress

    local _, max = ModuleRefer.ReplicaPVPModule:GetTitleRewardProgressValue()
    local cur = ModuleRefer.ReplicaPVPModule:GetMyPoints()
    local curTitle = ModuleRefer.ReplicaPVPModule:GetMyPVPTitleStageConfigCell():Rank()
    if curTitle == 6 then
        self.textProgress.text = I18N.Get('se_pvp_reward_toking')
    else
        self.textProgress.text = string.format('%d / %d', cur, max)
    end

end

function ReplicaPVPMainMediator:RefreshLeaderboardUI()
    -- 自己的排行榜信息
    local portraitInfo = ModuleRefer.PlayerModule:GetSelfPortaitInfo()
    self.playerIcon:FeedData(portraitInfo)
    self.txtPlayerName.text = ModuleRefer.PlayerModule:MyFullName()

    -- 自己的战力和积分信息
    local attackPresets = ModuleRefer.ReplicaPVPModule:GetAttackPresets()
    local power = attackPresets and attackPresets.Power or 0
    self.txtPlayerPowerNumber.text = NumberFormatter.Normal(power)
    self.txtPlayerScoreNumber.text = NumberFormatter.Normal(ModuleRefer.ReplicaPVPModule:GetMyPoints())

    -- 自己的排名信息
    local myRank = ModuleRefer.ReplicaPVPModule:GetMyRank()
    self.imgMyRankTop1:SetVisible(myRank == 1)
    self.imgMyRankTop2:SetVisible(myRank == 2)
    self.imgMyRankTop3:SetVisible(myRank == 3)
    self.txtMyRankOther:SetVisible(myRank > 3 or myRank <= 0)
    if myRank <= 0 then
        self.txtMyRankOther.text = I18N.Get('se_pvp_challengelist_notonlist')
    elseif myRank <= 3 then
        g_Game.SpriteManager:LoadSprite(UIHelper.GetRankIcon(myRank), self.imageMyRankTop3)
    else
        self.txtMyRankOther.text = tostring(myRank)
    end

    -- 自己的段位信息
    local myTitleStageConfigCell = ModuleRefer.ReplicaPVPModule:GetMyPVPTitleStageConfigCell()
    self:LoadSprite(myTitleStageConfigCell:Icon(), self.imageLvIconMine)
    if myTitleStageConfigCell:LevelIcon() > 0 then
        self.imageLvIconNumMine:SetVisible(true)
        self:LoadSprite(myTitleStageConfigCell:LevelIcon(), self.imageLvIconNumMine)
    else
        self.imageLvIconNumMine:SetVisible(false)
    end

    -- 其他排行榜信息
    if self.reply == nil then
        return
    end

    self.tableRanks:Clear()
    local count = self.reply.TopList:Count()
    for i = 1, count do
        ---@type ReplicaPVPLeaderboardCellData
        local cellData = {}
        cellData.rankNum = i
        cellData.rankData = self.reply.TopList[i]
        cellData.onHeadClick = Delegate.GetOrCreate(self, self.OnHeadClicked)
        self.tableRanks:AppendData(cellData)
    end
end

function ReplicaPVPMainMediator:RefreshChallengeReddot()
    local hasNew = ModuleRefer.ReplicaPVPModule:HasNewerChallengeRecord()
    self.reddotBattleRecord:SetVisible(hasNew)
    if hasNew then
        self.reddotBattleRecord:ShowRedDot()
    end
end

---@param cell PvpTitleStageConfigCell
---@param points number
function ReplicaPVPMainMediator:GetSliderInfo(cell, points)
    local min = cell:IntegralMin()
    local max = cell:IntegralMax()
    local total = max - min
    local current = points - min
    local progress = math.clamp01(current / total)
    return min, max, progress
end

function ReplicaPVPMainMediator:OnClickBtnClose()
    local SeState = require("SeState")
    if g_Game.StateMachine:IsCurrentState(SeState:GetName()) then
        -- 从SE退出
        ModuleRefer.ReplicaPVPModule:ExitReplicaPVP()
    else
        -- 从City退出
        self:CloseSelf()
    end
end

---@param targetPlayerId number
---@param anchorTrans CS.UnityEngine.Transform
function ReplicaPVPMainMediator:OnHeadClicked(targetPlayerId, anchorTrans)
    local req = GetReplicaPvpPlayerInfoParameter.new()
    req.args.TargetId = targetPlayerId
    self.lastClickAnchorTrans = anchorTrans
    req:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, reply)
        if isSuccess then
            ---@type wrpc.GetReplicaPvpPlayerInfoReply
            local responseData = reply
            ---@type ReplicaPVPTroopInfoTipsParameter
            local param = {}
            param.basicInfo = responseData.PlayerInfo
            param.anchorTrans = self.lastClickAnchorTrans
            g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPTroopInfoTips, param)
            self.lastClickAnchorTrans = nil
        end
    end)
end

function ReplicaPVPMainMediator:OnTipsClicked()
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPRankInfoMediator)
end

function ReplicaPVPMainMediator:OnRankReviewClicked()
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPPopupInfoMediator)
end

function ReplicaPVPMainMediator:OnShopClicked()
    ModuleRefer.ReplicaPVPModule:OpenPVPShop()
end

function ReplicaPVPMainMediator:OnBattleRecordClicked()
    self.reddotBattleRecord:SetVisible(false)
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPBattleRecordMediator)
end

function ReplicaPVPMainMediator:OnTroopClicked()
    ModuleRefer.ReplicaPVPModule:OpenDefendTroopEditUI()
end

function ReplicaPVPMainMediator:OnChallengeClicked()
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPChallengeMediator)
end

function ReplicaPVPMainMediator:OnDailyRewardAreaClicked()
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPSettlementRewardsMediator)
end

function ReplicaPVPMainMediator:OnCellChallengeClicked()
    self:DisableChallengeBtn()
end

function ReplicaPVPMainMediator:DisableChallengeBtn()
    self.btnChallenge.interactable = false
end

function ReplicaPVPMainMediator:EnableChallengeBtn()
    self.btnChallenge.interactable = true
end

return ReplicaPVPMainMediator