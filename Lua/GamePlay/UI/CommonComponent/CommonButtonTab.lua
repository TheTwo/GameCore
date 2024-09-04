local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')

---@class CommonButtonTabParameter
---@field text string
---@field callback fun()

---@class CommonButtonTab:BaseUIComponent
local CommonButtonTab = class('CommonButtonTab', BaseUIComponent)

function CommonButtonTab:OnCreate()
    self.btnChildTabS = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildTabSClicked))
    self.textTab = self:Text('p_text_tab')
    self.goBaseSelect = self:GameObject('p_base_select')
    self.textTabSelect = self:Text('p_text_tab_select')
end

---@param param CommonButtonTabParameter
function CommonButtonTab:OnFeedData(param)
    if not param then
        return
    end
    self.callback = param.callback
    self.textTab.text = param.text
    self.textTabSelect.text = param.text
end

function CommonButtonTab:OnBtnChildTabSClicked()
    if self.callback then
        self.callback()
    end
end

---@param state boolean
function CommonButtonTab:ChangeSelectTab(state)
    self.goBaseSelect:SetActive(state)
end

return CommonButtonTab
