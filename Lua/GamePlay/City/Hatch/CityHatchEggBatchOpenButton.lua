local BaseUIComponent = require ('BaseUIComponent')
---@class CityHatchEggBatchOpenButton:BaseUIComponent
local CityHatchEggBatchOpenButton = class('CityHatchEggBatchOpenButton', BaseUIComponent)
local Delegate = require("Delegate")

function CityHatchEggBatchOpenButton:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text_num_open_1 = self:Text("p_text_num_open_1", "treasure_option")
    self._p_text_num_open = self:Text("p_text_num_open")
end

---@param data {param:CityHatchEggUIParameter, count:number}
function CityHatchEggBatchOpenButton:OnFeedData(data)
    self.data = data
    self._p_text_num_open.text = ("x%d"):format(data.count)
end

function CityHatchEggBatchOpenButton:OnClick()
    self.data.param:OpenEggBatch(self.data.count, self._button.transform)
end

return CityHatchEggBatchOpenButton