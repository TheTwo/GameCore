local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@class CityWorkUIBuffItem:BaseUIComponent
local CityWorkUIBuffItem = class('CityWorkUIBuffItem', BaseUIComponent)

---@class CityWorkUIBuffItemData
---@field desc string
---@field subDesc string
---@field tip string

function CityWorkUIBuffItem:OnCreate()
    self._icon = self:Image("")
    self._p_text_buff = self:Text("p_text_buff")
    self._p_text_buff_1 = self:Text("p_text_buff_1")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data CityWorkUIBuffItemData
function CityWorkUIBuffItem:OnFeedData(data)
    if self._p_text_buff then
        local showDesc = not string.IsNullOrEmpty(data.desc)
        self._p_text_buff:SetVisible(showDesc)
        if showDesc then
            self._p_text_buff.text = data.desc
        end
    end

    if self._p_text_buff_1 then
        local showSubDesc = not string.IsNullOrEmpty(data.subDesc)
        self._p_text_buff_1:SetVisible(showSubDesc)
        if showSubDesc then
            self._p_text_buff_1.text = data.subDesc
        end
    end

    self.tip = data.tip
end

function CityWorkUIBuffItem:OnClick()
    if string.IsNullOrEmpty(self.tip) then return end

    if not self.toastData then
        self.toastData = {}
        self.toastData.clickTransform = self._button.transform
        self.toastData.content = self.tip
    end
    ModuleRefer.ToastModule:ShowTextToast(self.toastData)
end

return CityWorkUIBuffItem