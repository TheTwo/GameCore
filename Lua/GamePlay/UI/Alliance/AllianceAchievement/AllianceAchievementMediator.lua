local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')
local ConfigRefer = require('ConfigRefer')
local AllianceTaskOperationParameter = require('AllianceTaskOperationParameter')
local AllianceTaskItemDataProvider = require("AllianceTaskItemDataProvider")
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')

---@class AllianceAchievementMediator : BaseUIMediator
local AllianceAchievementMediator = class('AllianceAchievementMediator', BaseUIMediator)
function AllianceAchievementMediator:OnCreate()
    self.p_status_content = self:StatusRecordParent('p_status_content')
    self.p_group_achievement = self:GameObject('p_group_achievement')
    self.p_table_type = self:TableViewPro('p_table_type')
    self.p_text_quantity = self:Text('p_text_quantity', '9999')
    self.p_text_detail = self:Text('p_text_detail', 'alliance_target_36')
    self.p_text_reward = self:Text('p_text_reward', "alliance_activity_big15")
    self.p_btn_reward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnClaimClick))
    self.child_common_btn_back = self:LuaObject('child_common_btn_back')

    -- 盟主任务
    self.group_tab = self:GameObject('group_tab')
    self.p_group_league_leader_task = self:GameObject('p_group_league_leader_task')
    ---@type AllianeAchievementTab
    self.p_item_tab_1 = self:LuaObject('p_item_tab_1')
    ---@type AllianeAchievementTab
    self.p_item_tab_2 = self:LuaObject('p_item_tab_2')
    self.p_table_chapter = self:TableViewPro('p_table_chapter')
    self.p_table_task = self:TableViewPro('p_table_task')

    -- 盟主章节任务
    self.p_task = self:GameObject('p_task')
    self.p_text_task = self:Text('p_text_task', 'alliance_target_45')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    ---@type BistateButtonSmall
    self.child_comp_btn_b_s = self:LuaObject('child_comp_btn_b_s')
end

function AllianceAchievementMediator:OnOpened(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceBasicInfo.LongTermTaskPoint.MsgPath, Delegate.GetOrCreate(self, self.RefreshPoint))

    local titleData = {}
    titleData.title = I18N.Get("alliance_target_1")
    self.child_common_btn_back:FeedData(titleData)

    -- 是否展示盟主任务
    local isLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    if isLeader then
        self.p_status_content:SetState(1)
        local parameter = {}
        parameter.onClick = Delegate.GetOrCreate(self, self.OnChangeTabIndex)
        parameter.index = 1
        parameter.btnName = I18N.Get("alliance_target_1")
        parameter.titleText = I18N.Get("alliance_target_1")
        self.p_item_tab_1:FeedData(parameter)

        parameter.index = 2
        parameter.btnName = I18N.Get("alliance_target_2")
        parameter.titleText = I18N.Get("alliance_target_2")
        self.p_item_tab_2:FeedData(parameter)

        self:OnChangeTabIndex(1)
    else
        self.p_status_content:SetState(0)
    end
    ModuleRefer.AllianceJourneyModule:LoadAllianceLongTermTasks()
    local longTermTasks = ModuleRefer.AllianceJourneyModule:GetAllianceLongTermTasks()
    for i = 1, 3 do
        if longTermTasks[i] then
            ---@type AllianceAchievementTypeComp
            self.p_table_type:AppendData({index = i, tasks = longTermTasks[i], canClick = true})
        end
    end
    self:RefreshPoint()
end

function AllianceAchievementMediator:OnClose(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceBasicInfo.LongTermTaskPoint.MsgPath, Delegate.GetOrCreate(self, self.RefreshPoint))
end

function AllianceAchievementMediator:OnChangeTabIndex(index)
    self.p_group_achievement:SetVisible(index == 1)
    self.p_group_league_leader_task:SetVisible(index == 2)
    self.p_item_tab_1:SetStatus(index == 1 and 0 or 1)
    self.p_item_tab_2:SetStatus(index == 2 and 0 or 1)

    if index == 2 then
        self:InitLeaderTasks()
    end
end

function AllianceAchievementMediator:InitLeaderTasks()
    self.p_table_chapter:Clear()
    ModuleRefer.AllianceJourneyModule:LoadAllianceLeaderTasks()
    self.leaderTasks = ModuleRefer.AllianceJourneyModule:GetAllianceLeaderTasks()
    self.leaderChapterData = {}
    for i = 1, #self.leaderTasks do
        local data = {index = i, onClick = Delegate.GetOrCreate(self, self.RefreshLeaderTasks)}
        ---@type AllianceAchievementLeaderChapterTab
        self.p_table_chapter:AppendData(data)
        self.leaderChapterData[i] = data
    end

    -- 前往盟主任务章节1
    self:RefreshLeaderTasks(1)
end

function AllianceAchievementMediator:RefreshLeaderTasks(chapter)
    self.p_table_task:Clear()
    for i = 1, (self.leaderTasks[chapter]:SubTasksLength()) do
        local id = self.leaderTasks[chapter]:SubTasks(i)
        local task = ModuleRefer.AllianceJourneyModule:GetTask(id)
        if task then
            local data = {}
            data.provider = AllianceTaskItemDataProvider.new(task.TID)
            data.index = chapter
            self.p_table_task:AppendData(data)
        end
    end

    -- 盟主章节任务
    local provider = AllianceTaskItemDataProvider.new(self.leaderTasks[chapter]:FinalTask())
    self.p_table_reward:Clear()
    for _, reward in ipairs(provider:GetTaskRewards()) do
        self.p_table_reward:AppendData(reward)
    end

    local chapterTaskId = self.leaderTasks[chapter]:FinalTask()
    local chapterTask = ModuleRefer.AllianceJourneyModule:GetTask(chapterTaskId)
    self.p_task:SetVisible(chapterTask ~= nil)
    if chapterTask then
        local unlock = ModuleRefer.AllianceJourneyModule:IsLeaderTaskChapterUnlock(chapter, true)
        if unlock then
            local leaderTaskStatus = ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(chapterTaskId)
            self.child_comp_btn_b_s:SetEnabled(leaderTaskStatus == wds.TaskState.TaskStateCanFinish)
        else
            self.child_comp_btn_b_s:SetEnabled(false)
        end
        ---@type BistateButtonSmallParam
        local btnParam = {}
        btnParam.buttonText = I18N.Get('worldstage_lingqu')
        btnParam.disableButtonText = I18N.Get('worldstage_lingqu')
        btnParam.onClick = function()
            local req = AllianceTaskOperationParameter.new()
            req.args.Op = wrpc.TaskOperation.TaskOpGetReward
            req.args.CID = chapterTaskId
            req:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
                if isSuccess then
                    self:RefreshLeaderTasks(chapter)
                end
            end)
        end
        self.child_comp_btn_b_s:FeedData(btnParam)
    end

    self.p_table_chapter:SetToggleSelectIndex(chapter - 1)
end

function AllianceAchievementMediator:RefreshPoint()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then
        return
    end
    local alliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    self.p_text_quantity.text = alliance.AllianceBasicInfo.LongTermTaskPoint
end

function AllianceAchievementMediator:OnBtnClaimClick(param)
    local rewards = {}
    local names = {}
    local rangeMins = {}

    for k, v in ConfigRefer.AllianceLongTermPointReward:ipairs() do
        local reward = {}
        table.insert(names, v:Name())
        table.insert(rangeMins, v:RangeMin())
        -- local rangeMax = cfg:RangeMax()
        local itemGroupCfg = ConfigRefer.ItemGroup:Find(v:Reward())
        if itemGroupCfg then
            for i = 1, itemGroupCfg:ItemGroupInfoListLength() do
                local info = itemGroupCfg:ItemGroupInfoList(i)
                local iconData = {}
                iconData.configCell = ConfigRefer.Item:Find(info:Items())
                iconData.count = info:Nums()
                table.insert(reward, iconData)
            end
        end
        table.insert(rewards, reward)
    end

    local content_page1 = {}
    table.insert(content_page1, {hint = I18N.Get("alliance_target_43")})
    for i = 1, #names do
        table.insert(content_page1, {title = I18N.GetWithParams("alliance_target_44", I18N.Get(names[i]), rangeMins[i])})
        table.insert(content_page1, {reward = rewards[i]})
    end
    ---@type CommonPlainTextContent
    local content1 = {list = content_page1}

    g_Game.UIManager:Open(UIMediatorNames.CommonPlainTextInfoMediator, {tabs = {}, contents = {content1}, title = I18N.Get("alliance_WorldEvent_rule")})

end
return AllianceAchievementMediator
