local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityConstructionUITip:BaseUIComponent
local CityConstructionUITip = class('CityConstructionUITip', BaseUIComponent)

function CityConstructionUITip:OnCreate()
    self.transform = self:Transform("")
    self.gameObject = self.transform.gameObject
    self._p_table_tips = self:TableViewPro("p_table_tips")
end

---@param worldPos CS.UnityEngine.Vector3
---@param attrGroup AttrGroupConfigCell
function CityConstructionUITip:ShowTip(worldPos, attrGroup)
    self._p_table_tips:Clear()
    for i = 1, attrGroup:AttrListLength() do
        local item = attrGroup:AttrList(i)
        self._p_table_tips:AppendData(item)
    end

    self.gameObject:SetActive(true)
    self.transform.position = worldPos
end

function CityConstructionUITip:HideTip()
    self.gameObject:SetActive(false)
end

return CityConstructionUITip    