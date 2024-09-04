local BaseUIComponent = require ('BaseUIComponent')

---@class TouchMenuCellLandform:BaseUIComponent
local TouchMenuCellLandform = class('TouchMenuCellLandform', BaseUIComponent)

function TouchMenuCellLandform:OnCreate()
    self.txtLandform = self:Text('p_text_lanform')
    self.tableLandforms = self:TableViewPro('p_table_landform')
end

---@param data TouchMenuCellLandformDatum
function TouchMenuCellLandform:OnFeedData(data)
    self.data = data

    self.txtLandform.text = data.title
    self.tableLandforms:Clear()
    for _, landCfgId in ipairs(data.landCfgIds) do
        ---@type TMLandformCellData
        local cellData = {}
        cellData.landCfgId = landCfgId
        self.tableLandforms:AppendData(cellData)
    end
end

return TouchMenuCellLandform