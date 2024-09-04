local Delegate = require("Delegate")
local HUDTroopUtils = require("HUDTroopUtils")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")

---@class HUDTroopStateHolder
local HUDTroopStateHolder = class("HUDTroopStateHolder")

---@param cell BaseTableViewProCell
---@param presetIndex number
function HUDTroopStateHolder:ctor(cell, presetIndex, locked, empty)
    self.index = presetIndex
    self.locked = locked
    self.empty = empty

    self.cell = cell
    self.p_group_left_base = self.cell:Transform("p_group_left_base")
    self.p_explore = self.cell:Transform("p_explore")
    self.p_text_destination = self.cell:Text('p_text_destination')
    self.p_text_status = self.cell:Text('p_text_status')
    self.p_text_progress = self.cell:Text('p_text_progress')
end

function HUDTroopStateHolder:Setup()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self:UpdateUI()
end

function HUDTroopStateHolder:Release()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function HUDTroopStateHolder:Tick()
    self:UpdateUI()
end

function HUDTroopStateHolder:UpdateUI()
    if self.empty or self.locked then
        self.p_group_left_base:SetVisible(false)
        self.p_explore:SetVisible(false)
    else
        if HUDTroopUtils.IsPresetInHome(self.index) then
            self:UpdateUIBySeTeamData()
        else
            self:UpdateUIBySlgData()
        end
    end
end

--部队在家里
function HUDTroopStateHolder:UpdateUIBySeTeamData()
    local teamData = HUDTroopUtils.GetExplorerTeamData(self.index)
    if teamData then
        local showTime = HUDTroopUtils.ShouldShowCityTeamMoveTime(teamData)
        if showTime then
            local state = I18N.Get("formation-xingjun")
            local destination = HUDTroopUtils.GetCityTeamDestination(teamData)
            local duration = HUDTroopUtils.GetCityTeamMoveDuration(teamData)
            duration = math.max(duration, 0)

            self.p_text_destination.text = destination
            self.p_text_status.text = state
            self.p_text_progress.text = TimeFormatter.SimpleFormatTime(duration)
        end

        self.p_group_left_base:SetVisible(showTime)
        self.p_explore:SetVisible(showTime)
        return
    end

    self.p_group_left_base:SetVisible(false)
    self.p_explore:SetVisible(false)
end

---部队在大世界
function HUDTroopStateHolder:UpdateUIBySlgData()
    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo then
        local showTime = HUDTroopUtils.ShouldShowTroopMoveTime(troopInfo)
        if showTime then
            local state = HUDTroopUtils.GetTroopMoveState(troopInfo)
            local destination = HUDTroopUtils.GetTroopMoveDestination(troopInfo)
            local endTime = HUDTroopUtils.GetTroopoMoveEndTime(troopInfo)
            local timestamp = g_Game.ServerTime:GetServerTimestampInSeconds()
            local duration = endTime - timestamp
            duration = math.max(duration, 0)

            self.p_text_destination.text = destination
            self.p_text_status.text = state
            self.p_text_progress.text = TimeFormatter.SimpleFormatTime(duration)
        end

        self.p_group_left_base:SetVisible(showTime)
        self.p_explore:SetVisible(showTime)
        return
    end

    self.p_group_left_base:SetVisible(false)
    self.p_explore:SetVisible(false)
end

return HUDTroopStateHolder