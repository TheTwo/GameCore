local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFurnitureConstructionProcessTipsDetail:BaseUIComponent
---@field new fun():CityFurnitureConstructionProcessTipsDetail
---@field super BaseUIComponent
local CityFurnitureConstructionProcessTipsDetail = class('CityFurnitureConstructionProcessTipsDetail', BaseUIComponent)

function CityFurnitureConstructionProcessTipsDetail:OnCreate(param)
    self._selfGo = self:GameObject("")
    self._p_btn_empty = self:Button("p_btn_empty", Delegate.GetOrCreate(self, self.OnClickBtnEmpty))
    self._p_text_tips_hint = self:Text("p_text_tips_hint", "process_efficient_tips")
    self._p_table_tips = self:TableViewPro("p_table_tips")
    
end

function CityFurnitureConstructionProcessTipsDetail:FeedData(data)
    
end

function CityFurnitureConstructionProcessTipsDetail:OnClickBtnEmpty()
    self._selfGo:SetVisible(false)
end

return CityFurnitureConstructionProcessTipsDetail