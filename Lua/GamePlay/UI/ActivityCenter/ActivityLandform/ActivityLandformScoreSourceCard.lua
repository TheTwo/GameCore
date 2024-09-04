local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local LandExploreType = require("LandExploreType")
local SearchEntityType = require('SearchEntityType')
local QueuedTask = require("QueuedTask")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
---@class ActivityLandformScoreSourceCard : BaseUIComponent
local ActivityLandformScoreSourceCard = class("ActivityLandformScoreSourceCard", BaseUIComponent)

---@class ActivityLandformScoreSourceCardData
---@field landExploreId number
---@field landExploreScoreSourceId number

local LandExploreType2SearchEntityType = {
    [LandExploreType.KillNormalMonster] = SearchEntityType.NormalMob,
    [LandExploreType.KillEliteMonster] = SearchEntityType.EliteMob,
    [LandExploreType.CollectPetEgg] = SearchEntityType.Pet
}

function ActivityLandformScoreSourceCard:ctor()
    self.cfg = nil
end

function ActivityLandformScoreSourceCard:OnCreate()
    self.textName = self:Text("p_text_way_name")
    self.statusCtrler = self:StatusRecordParent("")
    -- 普通
    self.textScore = self:Text("p_text_score")
    self.textReward = self:Text("p_text_reward", "landexplore_task_contant_available")
    self.btnGoto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoBtnClick))
    self.textGoto = self:Text("p_text_goto", "goto")
    self.imgIcon = self:Image("p_icon_way")

    self.goTextRemainTimes = self:GameObject("p_number_al")
    self.textRemainTimes = self:Text("p_text_num_wilth_al")
    -- 已满
    self.textFull = self:Text("p_text_full", "landexplore_task_contant_reached_limit")
end

---@param data ActivityLandformScoreSourceCardData
function ActivityLandformScoreSourceCard:OnFeedData(data)
    self.data = data
    self.cfg = ConfigRefer.LandExploreScoreSource:Find(data.landExploreScoreSourceId)
    if not self.cfg then return end

    local scoreMap = ModuleRefer.ActivityLandformModule:GetCurScoreSplitBySourceId(data.landExploreId)
    local curScore = scoreMap[data.landExploreScoreSourceId] or 0
    if curScore >= self.cfg:ScoreUpperLimit() then
        self.statusCtrler:ApplyStatusRecord(1)
    else
        self.statusCtrler:ApplyStatusRecord(0)
    end

    local params = {}
    for i = 1, self.cfg:FilterParamLength() do
        table.insert(params, self.cfg:FilterParam(i))
    end
    self.textScore.text = self.cfg:RewardScoreEachTime()

    local lvlRange
    local lvlLow = params[1] or 0
    local lvlHigh = params[2] or 0
    if lvlLow == lvlHigh then
        lvlRange = lvlLow
    else
        lvlRange = ("%d~%d"):format(lvlLow, lvlHigh)
    end
    self.textName.text = I18N.GetWithParams(self.cfg:Desc(), lvlRange)
    g_Game.SpriteManager:LoadSprite(self.cfg:Icon(), self.imgIcon)

    self.goTextRemainTimes:SetActive(true)
    local curTimes = curScore / self.cfg:RewardScoreEachTime()
    local maxTimes = self.cfg:ScoreUpperLimit() / self.cfg:RewardScoreEachTime()
    self.textRemainTimes.text = I18N.GetWithParams("landexplore_info_remaining_times", math.floor(maxTimes - curTimes))
end

function ActivityLandformScoreSourceCard:OnGotoBtnClick()
    self:GetParentBaseUIMediator():CloseSelf()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        local queuedTask = QueuedTask.new()
        queuedTask:WaitEvent(EventConst.HUD_CLOUD_SCREEN_CLOSE, nil, function()
            return true
        end):DoAction(function()
            self:Goto()
        end):Start()
        scene:LeaveCity()
        return
    else
        TimerUtility.DelayExecute(function ()
            self:Goto()
        end, 0.5)
    end

end

function ActivityLandformScoreSourceCard:Goto()
    local searchLvlUpperBound = self.cfg:FilterParam(2)
    local playerCanSearchLvl = math.huge
    local searchEntityType = LandExploreType2SearchEntityType[self.cfg:Type()]
    if searchEntityType == SearchEntityType.NormalMob then
        playerCanSearchLvl = ModuleRefer.WorldSearchModule:GetCanAttackNormalMobLevel()
    elseif searchEntityType == SearchEntityType.EliteMob then
        playerCanSearchLvl = ModuleRefer.WorldSearchModule:GetCanAttackEliteMobLevel()
    end
    local searchLvl = math.min(playerCanSearchLvl, searchLvlUpperBound)
    ---@type UIWorldSearchMediatorParam
    local data = {}
    data.selectType = searchEntityType
    data.searchLv = searchLvl
    g_Game.UIManager:Open(UIMediatorNames.UIWorldSearchMediator, data)
end

return ActivityLandformScoreSourceCard