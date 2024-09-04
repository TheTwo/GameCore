local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')

local ActivityWorldEventRankMediator = class('ActivityWorldEventRankMediator', BaseUIMediator)
function ActivityWorldEventRankMediator:ctor()
    self._rewardList = {}
end

function ActivityWorldEventRankMediator:OnCreate()
    self.p_group_board = self:GameObject('p_group_board')
    self.p_group_empty = self:GameObject('p_group_empty')
    self.p_text_empty = self:Text('p_text_empty', I18N.Get("alliance_worldevent_rank_empty"))

    ---@see CommonPopupBackLargeComponent
    self.luaBackGround = self:LuaObject("child_popup_base_l")

    self.p_btn_close = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_text_title_rank = self:Text('p_text_title_rank', I18N.Get("alliance_worldevent_big_ranklist"))
    self.p_text_title_player = self:Text('p_text_title_player', I18N.Get("alliance_worldevent_big_rank_name"))
    self.p_text_title_contribute = self:Text('p_text_title_contribute', I18N.Get("alliance_worldevent_big_rank_num"))

    self.p_table_ranking = self:TableViewPro('p_table_ranking')
    self.p_content = self:LuaObject('p_content')
    self.mineComp = self:GameObject('p_content')
end

function ActivityWorldEventRankMediator:OnShow(param)
    self.luaBackGround:FeedData({title = "alliance_worldevent_big_rank_title"})
    self.param = param
    self:Refresh()
end

function ActivityWorldEventRankMediator:OnHide(param)

end

function ActivityWorldEventRankMediator:Refresh()
    local members = ModuleRefer.AllianceModule:GetMyAllianceData().AllianceMembers.Members
    local ProgressList = self.param.ProgressList
    local selfID = ModuleRefer.PlayerModule:GetPlayer().ID
    self.p_table_ranking:Clear()

    local sum = 0
    local temp = {}

    for k, v in pairs(ProgressList) do
        sum = sum + v
        temp[k] = v
    end

    -- 是否存在数据
    if sum == 0 then
        self.p_group_board:SetVisible(false)
        self.p_group_empty:SetVisible(true)
        return
    else
        self.p_group_board:SetVisible(true)
        self.p_group_empty:SetVisible(false)
    end

    local index = 1
    local showMine = false
    for k, v in pairs(temp) do
        local max = v
        local key = k
        for k2, v2 in pairs(temp) do
            if v2 then
                if max < v2 then
                    max = v2
                    key = k2
                end
            end
        end
        -- 玩家本身数据
        if key == selfID then
            local faceBookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
            local mine = {}
            mine.index = index
            mine.PortraitInfo = members[faceBookId].PortraitInfo
            mine.Name = members[faceBookId].Name
            mine.Progress = max
            mine.sum = sum
            mine.isMine = true
            showMine = true
            self.p_content:FeedData(mine)
        end

        -- 他人数据
        for k2, v2 in pairs(members) do
            if v2.PlayerID == key then
                local param = {}
                param.index = index
                param.PortraitInfo = members[k2].PortraitInfo
                param.Name = members[k2].Name
                param.Progress = max
                param.sum = sum
                self.p_table_ranking:AppendData(param)
                break
            end
        end

        index = index + 1
        temp[key] = -1
    end

    if not showMine then
        self.mineComp:SetVisible(false)
    else
        self.mineComp:SetVisible(true)
    end

    self.p_table_ranking:RefreshAllShownItem()

end

function ActivityWorldEventRankMediator:OnBtnClick()
    g_Game.UIManager:CloseByName("ActivityWorldEventRankMediator")
end

return ActivityWorldEventRankMediator
