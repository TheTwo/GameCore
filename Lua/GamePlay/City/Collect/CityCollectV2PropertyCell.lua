local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityCollectV2PropertyCell:BaseTableViewProCell
local CityCollectV2PropertyCell = class('CityCollectV2PropertyCell', BaseTableViewProCell)
local ColorConsts = require("ColorConsts")

---@class CityCollectV2PropertyCellData
---@field name string
---@field value string
---@field isShowIcon boolean
---@field fromPet boolean

function CityCollectV2PropertyCell:OnCreate()
    ---属性名字
    self._p_text_content = self:Text("p_text_content")
    ---属性值
    self._p_text_detail = self:Text("p_text_detail")
    ---是否显示感叹号
    self._p_icon = self:Image("p_icon")
end

---@param data CityCollectV2PropertyCellData
function CityCollectV2PropertyCell:OnFeedData(data)
    self.data = data
    self._p_text_content.text = data.name
    if data.fromPet then
        self._p_text_detail.text = ("<color=%s>%s</color>"):format(ColorConsts.reminder_yellow, data.value)
    else
        self._p_text_detail.text = data.value
    end
    self._p_icon:SetVisible(data.isShowIcon)
end

return CityCollectV2PropertyCell