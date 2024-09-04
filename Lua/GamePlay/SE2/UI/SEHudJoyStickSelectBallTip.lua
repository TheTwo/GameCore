local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class SEHudJoyStickSelectBallTipParameter
---@field currentPocketBallId number
---@field onSelect fun(itemId:number):boolean
---@field seEnv SEEnvironment

---@class SEHudJoyStickSelectBallTip:BaseUIComponent
---@field super BaseUIComponent
local SEHudJoyStickSelectBallTip = class("SEHudJoyStickSelectBallTip", BaseUIComponent)

function SEHudJoyStickSelectBallTip:ctor()
    SEHudJoyStickSelectBallTip.super.ctor(self)
    ---@type SEHudJoyStickSelectBallTipCellData[]
    self._tableCellsData = {}
    self._ignoreToggleChanged = false
end

function SEHudJoyStickSelectBallTip:OnCreate()
    self._p_btn_close_tips = self:Button("p_btn_close_tips", Delegate.GetOrCreate(self, self.OnClickCloseArea))
    self._p_table_ball = self:TableViewPro("p_table_ball")
    self._p_table_ball:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedCell))
end

---@param param SEHudJoyStickSelectBallTipParameter
function SEHudJoyStickSelectBallTip:OnFeedData(param)
    self._param = param
    self:RefreshTable()
end

function SEHudJoyStickSelectBallTip:OnClose()
    self._ignoreToggleChanged = true
    self._p_table_ball:UnSelectAll()
    self._p_table_ball:Clear()
    self._ignoreToggleChanged = false
    table.clear(self._tableCellsData)
    self._param = nil
    self._p_table_ball:SetSelectedDataChanged(nil)
end

function SEHudJoyStickSelectBallTip:OnClickCloseArea()
    self:SetVisible(false)
end

function SEHudJoyStickSelectBallTip:RefreshTable()
    self._ignoreToggleChanged = true
    self._p_table_ball:UnSelectAll()
    self._p_table_ball:Clear()
    self._ignoreToggleChanged = false
    local bagMgr = self._param.seEnv:GetSceneBagManager()
    table.clear(self._tableCellsData)
    local toggleIndex
    for index, item in ConfigRefer.PetPocketBall:ipairs() do
        ---@type SEHudJoyStickSelectBallTipCellData
        local cell
        local count = bagMgr:GetAmountByConfigId(item:LinkItem())
        if count <= 0 then
            goto continue
        end
        cell = {}
        cell.pocketBallConfig = item
        cell.count = count
        table.insert(self._tableCellsData, cell)
        self._p_table_ball:AppendData(cell)
        if (item:Id() == self._param.currentPocketBallId) then
            toggleIndex = index - 1
        end
        ::continue::
    end
    if toggleIndex then
        self._ignoreToggleChanged = true
        self._p_table_ball:SetToggleSelectIndex(toggleIndex)
        self._ignoreToggleChanged = false
    end
end

---@param newCell SEHudJoyStickSelectBallTipCellData
function SEHudJoyStickSelectBallTip:OnSelectedCell(_, newCell)
    if  self._ignoreToggleChanged then
        return
    end
    if not newCell or newCell.pocketBallConfig:Id() == self._param.currentPocketBallId then
        self:SetVisible(false)
        return 
    end
    if self._param.onSelect(newCell.pocketBallConfig:Id()) then
        self:SetVisible(false)
    end
end

return SEHudJoyStickSelectBallTip