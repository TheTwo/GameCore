local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")

---@class CityBuildUpgradeMaterialCell:BaseTableViewProCell
local CityBuildUpgradeMaterialCell = class('CityBuildUpgradeMaterialCell', BaseTableViewProCell)

function CityBuildUpgradeMaterialCell:OnCreate()
    self.baseIcon = self:LuaObject('child_item_standard_s')
end

function CityBuildUpgradeMaterialCell:OnFeedData(data)
    self.data = data
    if self.baseIcon then
        self.baseIcon:FeedData(data)
    end
    if data.customColor then
        self.baseIcon:SetColor(data.customColor)
    end
    if data.setGrey then
        self.baseIcon:SetGray(true)
    end
    if self._itemCountEvtHandle then
        self._itemCountEvtHandle()
    end
    self._itemCountEvtHandle = ModuleRefer.InventoryModule:AddCountChangeListener(data.configCell:Id(), Delegate.GetOrCreate(self, self.OnCountChanged))
end

function CityBuildUpgradeMaterialCell:OnRecycle()
    if self._itemCountEvtHandle then
        self._itemCountEvtHandle()
        self._itemCountEvtHandle = nil
    end
    self.data = nil
end

function CityBuildUpgradeMaterialCell:OnCountChanged()
    if self.data then
        self.data.count = ModuleRefer.InventoryModule:GetAmountByConfigId(self.data.configCell:Id())
        if self.baseIcon then
            self.baseIcon:FeedData(self.data)
        end
        if self.data.customColor then
            self.baseIcon:SetColor(self.data.customColor)
        end
        if self.data.setGrey then
            self.baseIcon:SetGray(true)
        end
    end
end

return CityBuildUpgradeMaterialCell