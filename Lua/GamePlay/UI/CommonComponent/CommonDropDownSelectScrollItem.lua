local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CommonDropDownSelectScrollItem:BaseTableViewProCell
---@field new fun():CommonDropDownSelectScrollItem
---@field super BaseTableViewProCell
local CommonDropDownSelectScrollItem = class('CommonDropDownSelectScrollItem', BaseTableViewProCell)

function CommonDropDownSelectScrollItem:ctor()
    BaseTableViewProCell.ctor(self)
    self._isDisable = false
end

function CommonDropDownSelectScrollItem:OnCreate(param)
    self.selfTrans = self:RectTransform("")
    self._p_text_content = self:Text("p_text_content")
    self._selfImage = self:Image("")
    self:PointerClick("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._selfStatus = self:StatusRecordParent("")
end

---@param data {index:number, data:{show:string, context:any, isDisable:boolean}, width:number}
function CommonDropDownSelectScrollItem:OnFeedData(data)
    self._isDisable = data.data.isDisable
    self._p_text_content.text = data.data.show
    self._selfStatus:SetState(self._isDisable and 1 or 0)
    local size = self.selfTrans.sizeDelta
    size.x = data.width
    self.selfTrans.sizeDelta = size
end

function CommonDropDownSelectScrollItem:OnClickSelf()
    if self._isDisable then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_unable_declare"))
        return 
    end
    self:SelectSelf()
end

 function CommonDropDownSelectScrollItem:Select(param)
     --override
 end
 function CommonDropDownSelectScrollItem:UnSelect(param)
     --override
 end

return CommonDropDownSelectScrollItem