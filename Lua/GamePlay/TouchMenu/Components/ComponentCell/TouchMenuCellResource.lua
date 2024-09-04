local BaseUIComponent = require ('BaseUIComponent')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIHelper = require("UIHelper")

---@class TouchMenuCellResource:BaseUIComponent
local TouchMenuCellResource = class('TouchMenuCellResource', BaseUIComponent)

function TouchMenuCellResource:OnCreate()
    ---@type TMCellResourcePair
    self._child_touch_menu_pair_resource = self:LuaObject("child_touch_menu_pair_resource")
end

---@param data TouchMenuCellResourceDatum
function TouchMenuCellResource:OnFeedData(data)
    self.data = data
    ---@type CommonPairsQuantityParameter[]
    local parameter = {}
    for index = 1, data.count do
        local unit = self.data:GetUnit(index)
        ---@type CommonPairsQuantityParameter
        local cellData = {}
        cellData.itemId = unit.itemId
        cellData.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        if unit.curValue < unit.maxValue then
            cellData.num1 = UIHelper.GetColoredText(tostring(unit.curValue) , CommonItemDetailsDefine.TEXT_COLOR.RED)
        else
            cellData.num1 = UIHelper.GetColoredText(tostring(unit.curValue) , CommonItemDetailsDefine.TEXT_COLOR.GREEN_2)
        end
        cellData.num2 = UIHelper.GetColoredText("/".. tostring(unit.maxValue) , CommonItemDetailsDefine.TEXT_COLOR.BLACK)
        table.insert(parameter, cellData)
    end
    self._child_touch_menu_pair_resource:FeedData(parameter)
end

return TouchMenuCellResource