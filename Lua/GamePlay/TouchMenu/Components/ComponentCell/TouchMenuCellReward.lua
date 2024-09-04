local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TouchMenuCellReward:BaseUIComponent
local TouchMenuCellReward = class('TouchMenuCellReward', BaseUIComponent)

function TouchMenuCellReward:OnCreate()
    self._p_text_reward = self:Text("p_text_reward")
    self._p_text_tip = self:Text("p_text_tip")
    self._p_text_tip_extra = self:Text("p_text_tip_1")
    self._p_table_reward = self:TableViewPro("p_table_reward")
end

---@param data TouchMenuCellRewardDatum
function TouchMenuCellReward:OnFeedData(data)
    self.data = data
    self.data:BindUICell(self)
end

function TouchMenuCellReward:OnClose()
    if self.data then
        self.data:UnbindUICell()
        self.data = nil
    end
end

function TouchMenuCellReward:UpdateTitle(title)
    self._p_text_reward.text = title
end

function TouchMenuCellReward:UpdateTips(tips)
    local isShow = not string.IsNullOrEmpty(tips)
    self._p_text_tip:SetVisible(isShow)
    if isShow then
        self._p_text_tip.text = tips
    end
end

function TouchMenuCellReward:UpdateExtraTips(tips)
    local isShow = not string.IsNullOrEmpty(tips)
    self._p_text_tip_extra:SetVisible(isShow)
    if isShow then
        self._p_text_tip_extra.text = tips
    end
end

---@param data TMCellRewardBase[]
function TouchMenuCellReward:UpdateTable(data)
    self._p_table_reward:Clear()
    if data == nil then return end

    for _, v in ipairs(data) do
        self._p_table_reward:AppendData(v.data, v:GetPrefabIndex())
    end
end

return TouchMenuCellReward