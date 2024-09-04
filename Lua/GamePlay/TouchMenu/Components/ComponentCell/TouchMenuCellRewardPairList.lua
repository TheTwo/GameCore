local BaseUIComponent = require("BaseUIComponent")
local Delegate = require('Delegate')

---@class TouchMenuCellRewardPairList : BaseUIComponent
local TouchMenuCellRewardPairList = class("TouchMenuCellRewardPairList", BaseUIComponent)

function TouchMenuCellRewardPairList:OnCreate(param)
    self.p_title = self:Text("p_title")
    self.p_table_pair = self:TableViewPro("p_table_pair")
    self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))
end

---@param data TouchMenuCellRewardPairListDatum
function TouchMenuCellRewardPairList:OnFeedData(data)
    self.data = data
    self.p_title.text = data.title
    
    self.p_table_pair:Clear()
    for i, pairData in ipairs(data.dataList) do
        self.p_table_pair:AppendData(pairData, pairData:GetPrefabIndex())
        if i < table.nums(data.dataList) then
            self.p_table_pair:AppendData({ }, 2)
        end
    end
    --self.p_table_pair:RefreshAllShownItem()

end

function TouchMenuCellRewardPairList:OnGotoClicked()
    if self.data.onClick then
        self.data.onClick()
    end
end

return TouchMenuCellRewardPairList