local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local CityWorkI18N = require('CityWorkI18N')

---@class CityWorkCollectUIRecipeItemExpand:BaseTableViewProCell
local CityWorkCollectUIRecipeItemExpand = class('CityWorkCollectUIRecipeItemExpand', BaseTableViewProCell)

---@class CityWorkCollectUIRecipeSubData
---@field expanded boolean
---@field eleResArray CityElementResourceConfigCell[]

function CityWorkCollectUIRecipeItemExpand:OnCreate()
    self._p_text_detail = self:Text("p_text_detail", CityWorkI18N.UIHint_CityWorkCollect_ExpandedCellTitle)
    self._p_table_detail = self:TableViewPro("p_table_detail")
end

---@param data CityWorkCollectUIRecipeSubData
function CityWorkCollectUIRecipeItemExpand:OnFeedData(data)
    self.data = data
    self._p_table_detail:Clear()
    for i, v in ipairs(data.eleResArray) do
        ---@type StarItemIconData
        local starItemIconData = {}
        starItemIconData.starCount = v:Star()
        starItemIconData.itemIconData = {}
        starItemIconData.itemIconData.customImage = v:Icon()
        starItemIconData.itemIconData.customQuality = v:Quality()
        starItemIconData.itemIconData.showCount = false
        starItemIconData.itemIconData.onClick = Delegate.GetOrCreate(self, self.OnClick)
        self._p_table_detail:AppendData(starItemIconData)
    end
end

function CityWorkCollectUIRecipeItemExpand:OnClick()
    --- block click
end

return CityWorkCollectUIRecipeItemExpand