local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local WorldTrendDefine = require('WorldTrendDefine')
local TimeFormatter = require('TimeFormatter')

---@class WorldTrendStageDotCell : BaseTableViewProCell
local WorldTrendStageDotCell = class('WorldTrendStageDotCell', BaseTableViewProCell)

---@class WorldTrendSelectDotCellParam
---@field stage number
---@field index number

function WorldTrendStageDotCell:OnCreate()
    self.goDotNormal = self:GameObject('p_dot_nml')
    self.goDotOK = self:GameObject('p_dot_ok')
    self.goDotClose = self:GameObject('p_dot_close')
    self.goDotLock = self:GameObject('p_dot_lock')
    self.goDotReward = self:GameObject('p_dot_reward')
    self.goSelect = self:GameObject('p_select')

    self.textOpenTips = self:Text('p_text_open_tip')
    self.luagoReddot = self:LuaObject("child_reddot_default")
    self.btnDotCell = self:Button('p_btn_dot', Delegate.GetOrCreate(self, self.OnClickDotCell))
end

function WorldTrendStageDotCell:OnShow()
    g_Game.EventManager:AddListener(EventConst.WORLD_TREND_SELECT_DOT, Delegate.GetOrCreate(self, self.OnSelectDotCell))
    g_Game.EventManager:AddListener(EventConst.WORLD_TREND_REWARD, Delegate.GetOrCreate(self, self.OnRewardUpdateDotState))
end

function WorldTrendStageDotCell:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.WORLD_TREND_SELECT_DOT, Delegate.GetOrCreate(self, self.OnSelectDotCell))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_TREND_REWARD, Delegate.GetOrCreate(self, self.OnRewardUpdateDotState))
end

---@param param WorldTrendStageCellParam
function WorldTrendStageDotCell:OnFeedData(param)
    if not param then
        return
    end
    self.isOpen = param.isOpen
    self.lastStage = param.lastStage
    self.curStage = param.stage
    self.index = param.index
    self.curMaxStage = param.curMaxStage

    if(self.curMaxStage == self.curStage) then
        self.goSelect:SetVisible(true)
    else
        self.goSelect:SetVisible(false)
    end
    self.state = ModuleRefer.WorldTrendModule:GetStageDotState(self.curStage)
    self:InitDotCellByState()
end

function WorldTrendStageDotCell:InitDotCellByState()
    if not self.state then
        return
    end
    if self.state == WorldTrendDefine.DOT_STATE.Lock_Normal then
        self.goDotNormal:SetActive(false)
        self.goDotOK:SetActive(false)
        self.goDotClose:SetActive(true)
        self.goDotLock:SetActive(false)
        self.goDotReward:SetActive(false)
        self.textOpenTips:SetVisible(true)
        self:CheckOpenTime()
    elseif self.state == WorldTrendDefine.DOT_STATE.Lock_WithCondition then
        self.goDotNormal:SetActive(false)
        self.goDotOK:SetActive(false)
        self.goDotClose:SetActive(false)
        self.goDotLock:SetActive(true)
        self.goDotReward:SetActive(false)
        self.textOpenTips:SetVisible(true)
        self:CheckOpenTime()
    elseif self.state == WorldTrendDefine.DOT_STATE.Open_Normal then
        self.goDotNormal:SetActive(true)
        self.goDotOK:SetActive(false)
        self.goDotClose:SetActive(false)
        self.goDotLock:SetActive(false)
        self.goDotReward:SetActive(false)
        self.textOpenTips:SetVisible(false)
    elseif self.state == WorldTrendDefine.DOT_STATE.Open_CanReward then
        self.goDotNormal:SetActive(false)
        self.goDotOK:SetActive(false)
        self.goDotClose:SetActive(false)
        self.goDotLock:SetActive(false)
        self.goDotReward:SetActive(true)
        self.textOpenTips:SetVisible(false)
    elseif self.state == WorldTrendDefine.DOT_STATE.Open_AllRewarded then
        self.goDotNormal:SetActive(false)
        self.goDotOK:SetActive(true)
        self.goDotClose:SetActive(false)
        self.goDotLock:SetActive(false)
        self.goDotReward:SetActive(false)
        self.textOpenTips:SetVisible(false)
    end
end

function WorldTrendStageDotCell:CheckOpenTime()
    local openTime = ModuleRefer.WorldTrendModule:GetStageOpenTime(self.curStage)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTime = openTime - curTime
    local h = leftTime // 3600

    if leftTime > TimeFormatter.OneDaySeconds then
        self.textOpenTips.text = "" --24h以上 不显示
    else
        leftTime = leftTime - h * 3600
        local m = leftTime // 60
        local s = leftTime % 60
        local d = h // 24

        if m == 0 and s > 0 then
            m = 1
        end

        if d > 0 then
            self.textOpenTips.text = I18N.GetWithParams("WorldStage_countdown_1", d)
        elseif h > 0 then
            self.textOpenTips.text = I18N.GetWithParams("WorldStage_countdown_2", h)
        elseif m > 0 then
            self.textOpenTips.text = I18N.GetWithParams("WorldStage_countdown_3", m)
        end
        self.textOpenTips:SetVisible(true)
    end
end

function WorldTrendStageDotCell:OnClickDotCell()
    -- self.goSelect:SetActive(true)
    ---@type WorldTrendSelectDotCellParam
    local param = {stage = self.curStage, index = self.index}
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_SELECT_DOT, param)
end

---@param param WorldTrendSelectDotCellParam
function WorldTrendStageDotCell:OnSelectDotCell(param)
    if not param then
        return
    end
    local isShow = false
    if param.stage and self.curStage == param.stage then
        isShow = true
    end
    if param.index and self.index == param.index then
        isShow = true
    end
    self.goSelect:SetActive(isShow)
end

function WorldTrendStageDotCell:OnRewardUpdateDotState(stage)
    if not stage then
        return
    end
    if self.curStage ~= stage then
        return
    end
    self.state = ModuleRefer.WorldTrendModule:GetStageDotState(self.curStage)
    self:InitDotCellByState()
end

return WorldTrendStageDotCell